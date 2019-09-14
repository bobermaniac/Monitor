import Foundation

public extension Monitor {
    func filter(using predicate: @escaping Transform<Ephemeral, Bool>) -> Monitor {
        let factory = FilterFactory(predicate: predicate, terminalType: Terminal.self)
        return transform(factory: factory)
    }
}

struct FilterFactory<Ephemeral, Terminal>: MonitorTransformingFactory {
    typealias Transforming = Filter<Ephemeral, Terminal>

    init(predicate: @escaping Transform<Ephemeral, Bool>, terminalType: Terminal.Type) {
        self.predicate = predicate
    }

    func make(feed: Feed<Ephemeral, Terminal>) -> Filter<Ephemeral, Terminal> {
        return Filter(predicate: predicate, feed: feed)
    }

    private let predicate: Transform<Ephemeral, Bool>
}

struct Filter<Ephemeral, Terminal>: MonitorTransforming {
    typealias InputEphemeral = Ephemeral
    typealias InputTerminal = Terminal
    typealias OutputEphemeral = Ephemeral
    typealias OutputTerminal = Terminal

    init(predicate: @escaping Transform<Ephemeral, Bool>, feed: Feed<Ephemeral, Terminal>) {
        self.predicate = predicate
        self.feed = feed
    }

    func eat(ephemeral: Ephemeral) {
        // Context: free
        if predicate(ephemeral) {
            feed.push(ephemeral: ephemeral)
        }
    }

    func eat(terminal: Terminal) {
        // Context: synchronized
        feed.push(terminal: terminal)
    }

    func cancel(sourceSubscription: Cancelable) {
        // Context: synchronized
        sourceSubscription.cancel()
    }

    private let predicate: Transform<Ephemeral, Bool>
    private let feed: Feed<Ephemeral, Terminal>
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
