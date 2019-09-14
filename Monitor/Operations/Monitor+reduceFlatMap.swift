import Foundation

public extension Monitor {
    func reduceFlatMap<OutputEphemeral, IntermediateTerminal, OutputTerminal>(
        accumulator: OutputTerminal,
        ephemeralTransform: @escaping Transform<Ephemeral, Monitor<OutputEphemeral, IntermediateTerminal>>,
        intermediateTerminalReducer: @escaping Reduce<OutputTerminal, IntermediateTerminal>,
        terminalReducer: @escaping Reduce<OutputTerminal, Terminal>,
        threadSafety: ThreadSafetyStrategy = CalleeSyncGuaranteed()
    ) -> Monitor<OutputEphemeral, OutputTerminal> {
        let factory = ReduceFlatMappingFactory(accumulator: accumulator,
                                           ephemeralTransform: ephemeralTransform,
                                           intermediateTerminalReducer: intermediateTerminalReducer,
                                           terminalReducer: terminalReducer)
        return transform(factory: factory)
    }
}

struct ReduceFlatMappingFactory<InputEphemeral, InputTerminal, IntermediateTerminal, OutputEphemeral, OutputTerminal>: MonitorTransformingFactory {
    typealias Transforming = ReduceFlatMapper<InputEphemeral, InputTerminal, IntermediateTerminal, OutputEphemeral, OutputTerminal>

    init(accumulator: OutputTerminal,
         ephemeralTransform: @escaping Transform<InputEphemeral, Monitor<OutputEphemeral, IntermediateTerminal>>,
         intermediateTerminalReducer: @escaping Reduce<OutputTerminal, IntermediateTerminal>,
         terminalReducer: @escaping Reduce<OutputTerminal, InputTerminal>
    ) {
        self.accumulator = accumulator
        self.transformEphemeral = ephemeralTransform
        self.reduceIntermediateTerminal = intermediateTerminalReducer
        self.reduceInputTerminal = terminalReducer
    }

    func make(feed: Feed<OutputEphemeral, OutputTerminal>) -> ReduceFlatMapper<InputEphemeral, InputTerminal, IntermediateTerminal, OutputEphemeral, OutputTerminal> {
        return Transforming(accumulator: accumulator,
                            ephemeralTransform: transformEphemeral,
                            intermediateTerminalReducer: reduceIntermediateTerminal,
                            terminalReducer: reduceInputTerminal,
                            feed: feed)
    }

    private let accumulator: OutputTerminal
    private let transformEphemeral: Transform<InputEphemeral, Monitor<OutputEphemeral, IntermediateTerminal>>
    private let reduceIntermediateTerminal: Reduce<OutputTerminal, IntermediateTerminal>
    private let reduceInputTerminal: Reduce<OutputTerminal, InputTerminal>
}

struct ReduceFlatMapper<InputEphemeral, InputTerminal, IntermediateTerminal, OutputEphemeral, OutputTerminal>: MonitorTransforming {
    init(accumulator: OutputTerminal,
         ephemeralTransform: @escaping Transform<InputEphemeral, Monitor<OutputEphemeral, IntermediateTerminal>>,
         intermediateTerminalReducer: @escaping Reduce<OutputTerminal, IntermediateTerminal>,
         terminalReducer: @escaping Reduce<OutputTerminal, InputTerminal>,
         feed: Feed<OutputEphemeral, OutputTerminal>) {
        self.transformEphemeral = ephemeralTransform
        self.reduceIntermediateTerminal = intermediateTerminalReducer
        self.reduceInputTerminal = terminalReducer
        self.feed = feed
        self.context = FreeContext(content: MutableState(accumulator: accumulator,
                                                         feed: feed.push(terminal:)))
    }

    func eat(ephemeral: InputEphemeral) {
        // Context: synchronized [subscription]
        transformEphemeral(ephemeral)
            .observe(ephemeral: feed.push(ephemeral:), terminal: eat(intermediateTerminal:))
            .associate(with: \.activeSubscribtions, in: ContextAccessor(context))
    }

    func eat(terminal: InputTerminal) {
        // Context: synchronized [terminal]
        context.readWrite { state in
            state.accumulator = reduceInputTerminal(state.accumulator, terminal)
            state.terminated = true
        }
    }

    func cancel(sourceSubscription: Cancelable) {
        // Context: synchronized [cancelation]
        sourceSubscription.cancel()
        context.read { $0.activeSubscribtions.forEach { $0.cancel() } }
    }

    private func eat(intermediateTerminal: IntermediateTerminal) {
        // Context: synchronized [terminal]
        context.readWrite { state in
            state.accumulator = reduceIntermediateTerminal(state.accumulator, intermediateTerminal)
        }
    }

    private let transformEphemeral: Transform<InputEphemeral, Monitor<OutputEphemeral, IntermediateTerminal>>
    private let reduceIntermediateTerminal: Reduce<OutputTerminal, IntermediateTerminal>
    private let reduceInputTerminal: Reduce<OutputTerminal, InputTerminal>
    private let feed: Feed<OutputEphemeral, OutputTerminal>
    private let context: FreeContext<MutableState>

    private struct MutableState {
        init(accumulator: OutputTerminal, feed: @escaping Consumer<OutputTerminal>) {
            self.accumulator = accumulator
            self.feed = feed
        }

        var accumulator: OutputTerminal

        var terminated = false {
            didSet {
                finalizeIfNeeded()
            }
        }

        var activeSubscribtions = [] as [Vanishable] {
            didSet {
                finalizeIfNeeded()
            }
        }

        private func finalizeIfNeeded() {
            if terminated && activeSubscribtions.isEmpty {
                feed(accumulator)
            }
        }

        private let feed: Consumer<OutputTerminal>
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
