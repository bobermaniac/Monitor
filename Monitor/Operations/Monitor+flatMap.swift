import Foundation

public extension Monitor {
    func flatMap<OutputEphemeral, OutputTerminal>(
        ephemeral ephemeralTransform: @escaping Transform<Ephemeral, Monitor<OutputEphemeral, OutputTerminal>>,
        terminal terminalTransform: @escaping Transform<Terminal, Monitor<OutputEphemeral, OutputTerminal>>,
        reducer: @escaping Reduce<OutputTerminal, OutputTerminal>
    ) -> Monitor<OutputEphemeral, OutputTerminal> {
        let factory = FlatMapperFactory(ephemeralTransform: ephemeralTransform,
                                        terminalTransform: terminalTransform,
                                        reducer: reducer)
        return transform(factory: factory)
    }
}

struct FlatMapperFactory<InputEphemeral, InputTerminal, OutputEphemeral, OutputTerminal>: MonitorTransformingFactory {
    typealias Transforming = FlatMapper<InputEphemeral, InputTerminal, OutputEphemeral, OutputTerminal>

    init(ephemeralTransform: @escaping Transform<InputEphemeral, Monitor<OutputEphemeral, OutputTerminal>>,
         terminalTransform: @escaping Transform<InputTerminal, Monitor<OutputEphemeral, OutputTerminal>>,
         reducer: @escaping Reduce<OutputTerminal, OutputTerminal>) {
        self.ephemeralTransform = ephemeralTransform
        self.terminalTransform = terminalTransform
        self.reducer = reducer
    }

    func make(feed: Feed<OutputEphemeral, OutputTerminal>) -> FlatMapper<InputEphemeral, InputTerminal, OutputEphemeral, OutputTerminal> {
        return FlatMapper(ephemeralTransform: ephemeralTransform,
                          terminalTransform: terminalTransform,
                          reducer: reducer,
                          feed: feed)
    }

    private let ephemeralTransform: Transform<InputEphemeral, Monitor<OutputEphemeral, OutputTerminal>>
    private let terminalTransform: Transform<InputTerminal, Monitor<OutputEphemeral, OutputTerminal>>
    private let reducer: Reduce<OutputTerminal, OutputTerminal>
}

struct FlatMapper<InputEphemeral, InputTerminal, OutputEphemeral, OutputTerminal>: MonitorTransforming {
    init(ephemeralTransform: @escaping Transform<InputEphemeral, Monitor<OutputEphemeral, OutputTerminal>>,
         terminalTransform: @escaping Transform<InputTerminal, Monitor<OutputEphemeral, OutputTerminal>>,
         reducer: @escaping Reduce<OutputTerminal, OutputTerminal>,
         feed: Feed<OutputEphemeral, OutputTerminal>) {
        self.ephemeralTransform = ephemeralTransform
        self.terminalTransform = terminalTransform
        self.reducer = reducer
        self.feed = feed
        self.context = FreeContext(content: MutableState(feed: feed.push(terminal:)))
    }

    func eat(ephemeral: InputEphemeral) {
        // Context: synchronized [subsequent call]
        observe(monitor: ephemeralTransform(ephemeral))
    }

    func eat(terminal: InputTerminal) {
        // Context: synchronized [terminal, subsequent call]
        observe(monitor: terminalTransform(terminal))
        context.readWrite { $0.inputTerminalFound = true }
    }

    func cancel(sourceSubscription: Cancelable) {
        // Context: synchronized [cancelation]
        sourceSubscription.cancel()
        context.read { $0.activeSubscriptions.forEach { $0.cancel() } }
    }

    private func observe(monitor: Monitor<OutputEphemeral, OutputTerminal>) {
        // Context: synchronized [subscription]
        monitor.observe(ephemeral: feed.push(ephemeral:), terminal: accumulate(terminal:))
            .associate(with: \.activeSubscriptions, in: ContextAccessor(context))
    }

    private func accumulate(terminal: OutputTerminal) {
        // Context: synchronized [terminal]
        context.readWrite { state in
            if let accumulator = state.accumulator {
                state.accumulator = reducer(accumulator, terminal)
            } else {
                state.accumulator = terminal
            }
        }
    }

    private let ephemeralTransform: Transform<InputEphemeral, Monitor<OutputEphemeral, OutputTerminal>>
    private let terminalTransform: Transform<InputTerminal, Monitor<OutputEphemeral, OutputTerminal>>
    private let reducer: Reduce<OutputTerminal, OutputTerminal>
    private let feed: Feed<OutputEphemeral, OutputTerminal>
    private let context: FreeContext<MutableState>

    private struct MutableState {
        init(feed: @escaping Consumer<OutputTerminal>) {
            self.feed = feed
        }

        var activeSubscriptions = [] as [Vanishable] {
            didSet {
                finalizeIfNeeded()
            }
        }

        var inputTerminalFound = false {
            didSet {
                finalizeIfNeeded()
            }
        }

        var accumulator: OutputTerminal?

        var feed: Consumer<OutputTerminal>

        private func finalizeIfNeeded() {
            if inputTerminalFound && activeSubscriptions.isEmpty {
                feed(accumulator!)
            }
        }
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
