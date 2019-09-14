import Foundation

public extension Monitor {
    func scan<PartialResult, Result>(accumulator: PartialResult,
                                       ephemeralReducer: @escaping Reduce<PartialResult, Ephemeral>,
                                       terminalReducer: @escaping (PartialResult, Terminal) -> Result,
                                       mode: ReduceMode = .interlocked,
                                       threadSafety: ThreadSafetyStrategy = CalleeSyncGuaranteed()) -> Monitor<PartialResult, Result> {
        switch mode {
        case .interlocked:
            return interlockedScan(accumulator: accumulator,
                                   ephemeralReducer: ephemeralReducer,
                                   terminalReducer: terminalReducer,
                                   threadSafety: threadSafety)
        case .concurrent:
            return concurrentScan(accumulator: accumulator,
                                  ephemeralReducer: ephemeralReducer,
                                  terminalReducer: terminalReducer,
                                  threadSafety: threadSafety)
        }
    }

    func interlockedScan<PartialResult, Result>(accumulator: PartialResult,
                                                ephemeralReducer: @escaping Reduce<PartialResult, Ephemeral>,
                                                terminalReducer: @escaping (PartialResult, Terminal) -> Result,
                                                threadSafety: ThreadSafetyStrategy) -> Monitor<PartialResult, Result> {
        let factory = ScannerFactory(accumulator: accumulator,
                                     ephemeralReducer: ephemeralReducer,
                                     terminalReducer: terminalReducer,
                                     threadSafety: threadSafety,
                                     reduceStrategyType: ScannerInterlockedReduceStrategy.self)
        return transform(factory: factory)
    }

    func concurrentScan<PartialResult, Result>(accumulator: PartialResult,
                                               ephemeralReducer: @escaping Reduce<PartialResult, Ephemeral>,
                                               terminalReducer: @escaping (PartialResult, Terminal) -> Result,
                                               threadSafety: ThreadSafetyStrategy) -> Monitor<PartialResult, Result> {
        let factory = ScannerFactory(accumulator: accumulator,
                                     ephemeralReducer: ephemeralReducer,
                                     terminalReducer: terminalReducer,
                                     threadSafety: threadSafety,
                                     reduceStrategyType: ScannerConcurrentReduceStrategy.self)
        return transform(factory: factory)
    }
}

struct ScannerFactory<InputTerminal, Result, ReduceStrategy: ScannerReduceStrategy>: MonitorTransformingFactory {
    init(accumulator: ReduceStrategy.PartialResult,
         ephemeralReducer: @escaping Reduce<ReduceStrategy.PartialResult, ReduceStrategy.Ephemeral>,
         terminalReducer: @escaping (ReduceStrategy.PartialResult, InputTerminal) -> Result,
         threadSafety: ThreadSafetyStrategy,
         reduceStrategyType: ReduceStrategy.Type) {
        self.accumulator = accumulator
        self.ephemeralReducer = ephemeralReducer
        self.terminalReducer = terminalReducer
        self.threadSafety = threadSafety
    }

    func make(feed: Feed<ReduceStrategy.PartialResult, Result>) -> Scanner<InputTerminal, Result, ReduceStrategy> {
        return Scanner(accumulator: accumulator,
                       ephemeralReducer: ephemeralReducer,
                       terminalReducer: terminalReducer,
                       threadSafety: threadSafety,
                       feed: feed)
    }

    private let accumulator: ReduceStrategy.PartialResult
    private let ephemeralReducer: Reduce<ReduceStrategy.PartialResult, ReduceStrategy.Ephemeral>
    private let terminalReducer: (ReduceStrategy.PartialResult, InputTerminal) -> Result
    private let threadSafety: ThreadSafetyStrategy
}

struct Scanner<InputTerminal, Result, ReduceStrategy: ScannerReduceStrategy>: MonitorTransforming {
    typealias InputEphemeral = ReduceStrategy.Ephemeral
    typealias OutputEphemeral = ReduceStrategy.PartialResult
    typealias OutputTerminal = Result

    init(accumulator: OutputEphemeral,
         ephemeralReducer: @escaping Reduce<OutputEphemeral, InputEphemeral>,
         terminalReducer: @escaping (OutputEphemeral, InputTerminal) -> Result,
         threadSafety: ThreadSafetyStrategy,
         feed: Feed<OutputEphemeral, Result>) {
        self.reduceStrategy = ReduceStrategy(accumulator: accumulator,
                                             reducer: ephemeralReducer,
                                             threadSafety: threadSafety)
        self.terminalReducer = terminalReducer
        self.feed = feed
    }

    func eat(ephemeral: InputEphemeral) {
        // Context: free
        // Synchronized via reduceStrategy
        feed.push(ephemeral: reduceStrategy.consume(ephemeral: ephemeral))
    }

    func eat(terminal: InputTerminal) {
        // Context: synchronized
        let sync = CalleeSyncGuaranteed()

        let accumulator = reduceStrategy.context.read(using: sync) { $0.accumulator }
        feed.push(terminal: terminalReducer(accumulator, terminal))
    }

    func cancel(sourceSubscription: Cancelable) {
        // Context: synchronized
        sourceSubscription.cancel()
    }

    private let reduceStrategy: ReduceStrategy
    private let terminalReducer: (OutputEphemeral, InputTerminal) -> Result
    private let feed: Feed<OutputEphemeral, Result>
}

protocol ScannerAccumulatorHolding {
    associatedtype PartialResult

    var accumulator: PartialResult { get set }
}

protocol ScannerReduceStrategy {
    associatedtype Ephemeral
    associatedtype MutableState: ScannerAccumulatorHolding

    typealias PartialResult = MutableState.PartialResult

    init(accumulator: PartialResult,
         reducer: @escaping Reduce<PartialResult, Ephemeral>,
         threadSafety: ThreadSafetyStrategy)

    var context: SynchronizedContext<MutableState> { get }

    func consume(ephemeral: Ephemeral) -> PartialResult
}

struct ScannerInterlockedReduceStrategy<Ephemeral, PartialResult>: ScannerReduceStrategy {
    init(accumulator: PartialResult,
         reducer: @escaping Reduce<PartialResult, Ephemeral>,
         threadSafety: ThreadSafetyStrategy) {
        self.context = SynchronizedContext(content: MutableState(accumulator: accumulator))
        self.reducer = reducer
        self.threadSafety = threadSafety
    }

    let context: SynchronizedContext<MutableState>

    func consume(ephemeral: Ephemeral) -> PartialResult {
        return context.readWrite(using: threadSafety) { state in
            state.accumulator = reducer(state.accumulator, ephemeral)
            return state.accumulator
        }
    }

    struct MutableState: ScannerAccumulatorHolding {
        init(accumulator: PartialResult) {
            self.accumulator = accumulator
        }

        var accumulator: PartialResult
    }

    private let reducer: Reduce<PartialResult, Ephemeral>
    private let threadSafety: ThreadSafetyStrategy
}

struct ScannerConcurrentReduceStrategy<Ephemeral, PartialResult>: ScannerReduceStrategy {
    init(accumulator: PartialResult,
         reducer: @escaping Reduce<PartialResult, Ephemeral>,
         threadSafety: ThreadSafetyStrategy) {
        self.context = SynchronizedContext(content: MutableState(accumulator: accumulator))
        self.reducer = reducer
        self.threadSafety = threadSafety
    }

    let context: SynchronizedContext<MutableState>

    func consume(ephemeral: Ephemeral) -> PartialResult {
        repeat {
            let (accumulator, generation) = context.read(using: threadSafety) { ($0.accumulator, $0.generation) }
            let newAccumulator = reducer(accumulator, ephemeral)
            let noConflict = context.readWrite(using: threadSafety) { state in
                guard state.generation == generation else {
                    return false
                }
                state.generation += 1
                state.accumulator = newAccumulator
                return true
            } as Bool
            if noConflict {
                return newAccumulator
            }
        } while true
    }

    struct MutableState: ScannerAccumulatorHolding {
        init(accumulator: PartialResult) {
            self.accumulator = accumulator
        }

        var accumulator: PartialResult
        var generation = 0 as UInt64
    }

    private let reducer: Reduce<PartialResult, Ephemeral>
    private let threadSafety: ThreadSafetyStrategy
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
