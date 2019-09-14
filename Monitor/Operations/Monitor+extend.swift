import Foundation

public extension Monitor {
    func extend<ResultTerminal>(using extender: @escaping Transform<Terminal, Monitor<Ephemeral, ResultTerminal>>) -> Monitor<Ephemeral, ResultTerminal> {
        let factory = ExtenderFactory(extender: extender)
        return transform(factory: factory)
    }
}

struct ExtenderFactory<Ephemeral, Terminal, ResultTerminal>: MonitorTransformingFactory {
    typealias Transforming = Extender<Ephemeral, Terminal, ResultTerminal>

    init(extender: @escaping Transform<Terminal, Monitor<Ephemeral, ResultTerminal>>) {
        self.extender = extender
    }

    func make(feed: Feed<Ephemeral, ResultTerminal>) -> Extender<Ephemeral, Terminal, ResultTerminal> {
        return Extender(extender: extender, feed: feed)
    }

    private let extender: Transform<Terminal, Monitor<Ephemeral, ResultTerminal>>
}

struct Extender<Ephemeral, Terminal, ResultTerminal>: MonitorTransforming {
    typealias InputEphemeral = Ephemeral
    typealias InputTerminal = Terminal
    typealias OutputEphemeral = Ephemeral
    typealias OutputTerminal = ResultTerminal

    init(extender: @escaping Transform<Terminal, Monitor<Ephemeral, ResultTerminal>>, feed: Feed<Ephemeral, ResultTerminal>) {
        self.extender = extender
        self.feed = feed
        self.context = FreeContext(content: MutableState())
    }

    func eat(ephemeral: Ephemeral) {
        // Context: free
        feed.push(ephemeral: ephemeral)
    }

    func eat(terminal: Terminal) {
        // Context: synchronized [terminal, subscribtion]
        extender(terminal)
            .observe(ephemeral: feed.push, terminal: feed.push)
            .associate(with: \.extendedMonitorSubsciption, in: ContextAccessor(context))
    }

    func cancel(sourceSubscription: Cancelable) {
        // Context: synchronized [cancelation]
        sourceSubscription.cancel()
        context.read { $0.extendedMonitorSubsciption?.cancel() }
    }

    private let extender: Transform<Terminal, Monitor<Ephemeral, ResultTerminal>>
    private let feed: Feed<Ephemeral, ResultTerminal>
    private let context: FreeContext<MutableState>

    private struct MutableState {
        init() { }

        var extendedMonitorSubsciption: Vanishable?
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
