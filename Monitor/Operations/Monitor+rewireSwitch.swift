import Foundation

public extension Monitor {
    func rewireSwitch<OutputEphemeral, OutputTerminal>(
        transform ephemeralTransform: @escaping Transform<Ephemeral, Monitor<OutputEphemeral, OutputTerminal>>,
        reduce: @escaping Reduce<OutputEphemeral, OutputEphemeral>,
        terminalReduce: @escaping Reduce<OutputTerminal, OutputEphemeral>,
        threadSafety: ThreadSafetyStrategy = CalleeSyncGuaranteed()
    ) -> Monitor<OutputTerminal, Terminal> {
        let factory = RewireSwitcherFactory(transform: ephemeralTransform, reduce: reduce, terminalReduce: terminalReduce, threadSafety: threadSafety, Terminal.self)
        return transform(factory: factory)
    }
}

struct RewireSwitcherFactory<InputEphemeral, InputTerminal, ReducedEphemeral, MappedTerminal>: MonitorTransformingFactory {
    init(transform: @escaping Transform<InputEphemeral, Monitor<ReducedEphemeral, MappedTerminal>>,
         reduce: @escaping Reduce<ReducedEphemeral, ReducedEphemeral>,
         terminalReduce: @escaping Reduce<MappedTerminal, ReducedEphemeral>,
         threadSafety: ThreadSafetyStrategy,
         _: InputTerminal.Type) {
        self.transform = transform
        self.reduce = reduce
        self.terminalReduce = terminalReduce
        self.threadSafety = threadSafety
    }

    func make(feed: Feed<MappedTerminal, InputTerminal>) -> RewireSwitch<InputEphemeral, InputTerminal, ReducedEphemeral, MappedTerminal> {
        return RewireSwitch(transform: transform, reduce: reduce, terminalReduce: terminalReduce, threadSafety: threadSafety, feed: feed)
    }

    private let transform: Transform<InputEphemeral, Monitor<ReducedEphemeral, MappedTerminal>>
    private let reduce: Reduce<ReducedEphemeral, ReducedEphemeral>
    private let terminalReduce: Reduce<MappedTerminal, ReducedEphemeral>
    private let threadSafety: ThreadSafetyStrategy
}

struct RewireSwitch<InputEphemeral, InputTerminal, ReducedEphemeral, MappedTerminal>: MonitorTransforming {
    init(transform: @escaping Transform<InputEphemeral, Monitor<ReducedEphemeral, MappedTerminal>>,
         reduce: @escaping Reduce<ReducedEphemeral, ReducedEphemeral>,
         terminalReduce: @escaping Reduce<MappedTerminal, ReducedEphemeral>,
         threadSafety: ThreadSafetyStrategy,
         feed: Feed<MappedTerminal, InputTerminal>) {
        self.transform = transform
        self.reduce = reduce
        self.terminalReduce = terminalReduce
        self.threadSafety = threadSafety
        self.feed = feed
        self.synchronizedContext = SynchronizedContext(content: MutableState())
    }

    func eat(ephemeral: InputEphemeral) {
        // Context: synchronized [subscription]
        let sync = CalleeSyncGuaranteed()

        synchronizedContext.readWrite(using: sync) { $0.accumulator = nil }
        transform(ephemeral).observe(ephemeral: reduce(ephemeral:), terminal: reduce(terminal:))
            .associate(with: \.activeSubscription, in: ContextAccessor(synchronizedContext, threadSafety: sync))
    }

    func eat(terminal: InputTerminal) {
        // Context: synchronized [terminal]
        feed.push(terminal: terminal)
    }

    func cancel(sourceSubscription: Cancelable) {
        // Context: synchronized [cancelation]
        let sync = CalleeSyncGuaranteed()

        synchronizedContext.read(using: sync) { $0.activeSubscription?.cancel() }
        sourceSubscription.cancel()
    }

    private func reduce(ephemeral: ReducedEphemeral) {
        // Context: free
        let sync = threadSafety

        synchronizedContext.readWrite(using: sync) { state in
            if let accumuator = state.accumulator {
                state.accumulator = reduce(accumuator, ephemeral)
            } else {
                state.accumulator = ephemeral
            }
        }
    }

    private func reduce(terminal: MappedTerminal) {
        // Context: synchronized [terminal]
        let sync = CalleeSyncGuaranteed()
    
        let accumulator = synchronizedContext.readWrite(using: sync) { state in
            let result = state.accumulator
            state.accumulator = nil
            return result
        } as ReducedEphemeral?

        if let accumuator = accumulator {
            feed.push(ephemeral: terminalReduce(terminal, accumuator))
        } else {
            feed.push(ephemeral: terminal)
        }
    }

    typealias OutputEphemeral = MappedTerminal
    typealias OutputTerminal = InputTerminal

    private let transform: Transform<InputEphemeral, Monitor<ReducedEphemeral, MappedTerminal>>
    private let reduce: Reduce<ReducedEphemeral, ReducedEphemeral>
    private let terminalReduce: Reduce<MappedTerminal, ReducedEphemeral>
    private let threadSafety: ThreadSafetyStrategy

    private let feed: Feed<MappedTerminal, InputTerminal>
    private let synchronizedContext: SynchronizedContext<MutableState>

    private struct MutableState {
        init() { }

        var accumulator: ReducedEphemeral?
        var activeSubscription: Vanishable?
    }
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
