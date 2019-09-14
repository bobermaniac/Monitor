import Foundation

public extension Monitor {
    func rewireAll<IntermediateEphemeral, RewiredTerminal>(
        ephemeral ephemeralTransform: @escaping Transform<Ephemeral, Monitor<IntermediateEphemeral, RewiredTerminal>>,
        reduce: @escaping Reduce<IntermediateEphemeral, IntermediateEphemeral>,
        terminalReduce: @escaping Reduce<RewiredTerminal, IntermediateEphemeral>,
        threadSafety: ThreadSafetyStrategy = CalleeSyncGuaranteed()
    ) -> Monitor<RewiredTerminal, Terminal> {
        let factory = RewireAllFactory(transform: ephemeralTransform,
                                       reduce: reduce,
                                       terminalReduce: terminalReduce,
                                       threadSafety: threadSafety,
                                       Terminal.self)
        return transform(factory: factory)
    }
}

struct RewireAllFactory<InputEphemeral, InputTerminal, IntermediateEphemeral, RewiredTerminal>: MonitorTransformingFactory {
    init(transform: @escaping Transform<InputEphemeral, Monitor<IntermediateEphemeral, RewiredTerminal>>,
         reduce: @escaping Reduce<IntermediateEphemeral, IntermediateEphemeral>,
         terminalReduce: @escaping Reduce<RewiredTerminal, IntermediateEphemeral>,
         threadSafety: ThreadSafetyStrategy,
         _ terminal: InputTerminal.Type) {
        self.transform = transform
        self.reduce = reduce
        self.terminalReduce = terminalReduce
        self.threadSafety = threadSafety
    }

    func make(feed: Feed<RewiredTerminal, InputTerminal>) -> AllRewirer<InputEphemeral, InputTerminal, IntermediateEphemeral, RewiredTerminal> {
        return AllRewirer(transform: transform,
                          reduce: reduce,
                          terminalReduce: terminalReduce,
                          threadSafety: threadSafety,
                          feed: feed)
    }

    private let transform: Transform<InputEphemeral, Monitor<IntermediateEphemeral, RewiredTerminal>>
    private let reduce: Reduce<IntermediateEphemeral, IntermediateEphemeral>
    private let terminalReduce: Reduce<RewiredTerminal, IntermediateEphemeral>
    private let threadSafety: ThreadSafetyStrategy
}

struct AllRewirer<InputEphemeral, InputTerminal, IntermediateEphemeral, RewiredTerminal>: MonitorTransforming {
    typealias OutputEphemeral = RewiredTerminal
    typealias OutputTerminal = InputTerminal

    init(transform: @escaping Transform<InputEphemeral, Monitor<IntermediateEphemeral, RewiredTerminal>>,
         reduce: @escaping Reduce<IntermediateEphemeral, IntermediateEphemeral>,
         terminalReduce: @escaping Reduce<RewiredTerminal, IntermediateEphemeral>,
         threadSafety: ThreadSafetyStrategy,
         feed: Feed<RewiredTerminal, InputTerminal>) {
        self.transform = transform
        self.reduce = reduce
        self.terminalReduce = terminalReduce
        self.threadSafety = threadSafety
        self.feed = feed
        self.synchronizedContext = SynchronizedContext(content: MutableState(feed: feed.push(terminal:)))
    }

    func eat(ephemeral: InputEphemeral) {
        // Context: synchronized [subscription]
        let sync = CalleeSyncGuaranteed()

        let sId = synchronizedContext.readWrite(using: sync) { state in
            let result = state.sIdCounter
            state.sIdCounter += 1
            return result
        } as UInt64

        let token = transform(ephemeral)
            .observe(ephemeral: { self.collect(ephemeral: $0, sId: sId)},
                     terminal: { self.collect(terminal: $0, sId: sId) })
        synchronizedContext.readWrite(using: sync) { state in
            state.rewireNodes[sId] = RewireNode(vanishable: token, accumulator: nil)
        }
        token.vanished.execute { [synchronizedContext] _ in
            synchronizedContext.readWrite(using: sync) { state in
                state.rewireNodes[sId] = nil
            }
        }
    }

    func eat(terminal: InputTerminal) {
        // Context: synchronized [terminal]
        let sync = CalleeSyncGuaranteed()

        synchronizedContext.readWrite(using: sync) { state in
            state.terminal = terminal
        }
    }

    func cancel(sourceSubscription: Cancelable) {
        // Context: synchronized [canelation]
        let sync = CalleeSyncGuaranteed()

        synchronizedContext.read(using: sync) { state in
            state.rewireNodes.values.forEach { $0.vanishable.cancel() }
        }
        sourceSubscription.cancel()
    }

    private func collect(ephemeral: IntermediateEphemeral, sId: UInt64) {
        // Context: free
        let sync = threadSafety

        synchronizedContext.readWrite(using: sync) { state in
            guard let node = state.rewireNodes[sId] else {
                fatalError("Misplaced rewire node found, aborting")
            }
            if let accumulator = node.accumulator {
                let newAccumulator = reduce(accumulator, ephemeral)
                state.rewireNodes[sId] = RewireNode(vanishable: node.vanishable, accumulator: newAccumulator)
            } else {
                state.rewireNodes[sId] = RewireNode(vanishable: node.vanishable, accumulator: ephemeral)
            }
        }
    }

    private func collect(terminal: RewiredTerminal, sId: UInt64) {
        // Context: synchronized [terminal]
        let sync = CalleeSyncGuaranteed()

        synchronizedContext.read(using: sync) { state in
            if let accumulator = state.rewireNodes[sId]?.accumulator {
                feed.push(ephemeral: terminalReduce(terminal, accumulator))
            } else {
                feed.push(ephemeral: terminal)
            }
        }
    }

    private let transform: Transform<InputEphemeral, Monitor<IntermediateEphemeral, RewiredTerminal>>
    private let reduce: Reduce<IntermediateEphemeral, IntermediateEphemeral>
    private let terminalReduce: Reduce<RewiredTerminal, IntermediateEphemeral>
    private let threadSafety: ThreadSafetyStrategy
    private let feed: Feed<RewiredTerminal, InputTerminal>
    private let synchronizedContext: SynchronizedContext<MutableState>

    private struct MutableState {
        init(feed: @escaping Consumer<InputTerminal>) {
            self.feed = feed
        }

        var sIdCounter = 0 as UInt64
        var rewireNodes = [:] as [UInt64: RewireNode<IntermediateEphemeral, RewiredTerminal>] {
            didSet {
                terminateIfNeeded()
            }
        }
        var terminal: InputTerminal? {
            didSet {
                terminateIfNeeded()
            }
        }

        private let feed: Consumer<InputTerminal>

        private func terminateIfNeeded() {
            if let terminal = self.terminal, rewireNodes.isEmpty {
                feed(terminal)
            }
        }
    }
}

private struct RewireNode<Ephemeral, Terminal> {
    let vanishable: Vanishable
    let accumulator: Ephemeral?
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
