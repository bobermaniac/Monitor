import Foundation

public extension Monitor {
    func switchMap<OutputEphemeral, OutputTerminal>(
        ephemeral ephemeralTransform: @escaping Transform<Ephemeral, Monitor<OutputEphemeral, OutputTerminal>>,
        terminal terminalTransform: @escaping Transform<Terminal, Monitor<OutputEphemeral, OutputTerminal>>,
        threadSafety: ThreadSafetyStrategy = CalleeSyncGuaranteed()
    ) -> Monitor<OutputEphemeral, OutputTerminal> {
        let factory = SwitchMapperFactory(ephemeralTransform: ephemeralTransform,
                                          terminalTransform: terminalTransform,
                                          threadSafety: threadSafety)
        return transform(factory: factory)
    }
}

struct SwitchMapperFactory<InputEphemeral, InputTerminal, OutputEphemeral, OutputTerminal>: MonitorTransformingFactory {
    typealias Transforming = SwitchMapper<InputEphemeral, InputTerminal, OutputEphemeral, OutputTerminal>

    init(ephemeralTransform: @escaping Transform<InputEphemeral, Monitor<OutputEphemeral, OutputTerminal>>,
         terminalTransform: @escaping Transform<InputTerminal, Monitor<OutputEphemeral, OutputTerminal>>,
         threadSafety: ThreadSafetyStrategy) {
        self.ephemeralTransform = ephemeralTransform
        self.terminalTransform = terminalTransform
        self.threadSafety = threadSafety
    }

    func make(feed: Feed<OutputEphemeral, OutputTerminal>) -> SwitchMapper<InputEphemeral, InputTerminal, OutputEphemeral, OutputTerminal> {
        return SwitchMapper(ephemeralTransform: ephemeralTransform,
                            terminalTransform: terminalTransform,
                            threadSafety: threadSafety,
                            feed: feed)
    }

    private let ephemeralTransform: Transform<InputEphemeral, Monitor<OutputEphemeral, OutputTerminal>>
    private let terminalTransform: Transform<InputTerminal, Monitor<OutputEphemeral, OutputTerminal>>
    private let threadSafety: ThreadSafetyStrategy
}

struct SwitchMapper<InputEphemeral, InputTerminal, OutputEphemeral, OutputTerminal>: MonitorTransforming {
    init(ephemeralTransform: @escaping Transform<InputEphemeral, Monitor<OutputEphemeral, OutputTerminal>>,
         terminalTransform: @escaping Transform<InputTerminal, Monitor<OutputEphemeral, OutputTerminal>>,
         threadSafety: ThreadSafetyStrategy,
         feed: Feed<OutputEphemeral, OutputTerminal>) {
        self.ephemeralTransform = ephemeralTransform
        self.terminalTransform = terminalTransform
        self.threadSafety = threadSafety
        self.feed = feed
        self.context = FreeContext(content: MutableState())
    }

    func eat(ephemeral: InputEphemeral) {
        // Context: synchronized [subseqeunt call]
        observe(monitor: ephemeralTransform(ephemeral))
    }

    func eat(terminal: InputTerminal) {
        // Context: synchronized [terminal, subsequent call]
        observe(monitor: terminalTransform(terminal))
    }

    func cancel(sourceSubscription: Cancelable) {
        // Context: synchronized [cancelation]
        sourceSubscription.cancel()
        context.read { $0.activeSubscription?.cancel() }
    }

    private func observe(monitor: Monitor<OutputEphemeral, OutputTerminal>) {
        // Context: synchronized [subscription]
        monitor.observe(ephemeral: feed.push(ephemeral:), terminal: feed.push(terminal:))
            .associate(with: \.activeSubscription, in: ContextAccessor(context))
    }

    private let ephemeralTransform: Transform<InputEphemeral, Monitor<OutputEphemeral, OutputTerminal>>
    private let terminalTransform: Transform<InputTerminal, Monitor<OutputEphemeral, OutputTerminal>>
    private let threadSafety: ThreadSafetyStrategy
    private let feed: Feed<OutputEphemeral, OutputTerminal>
    private let context: FreeContext<MutableState>

    private struct MutableState {
        init() { }

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
