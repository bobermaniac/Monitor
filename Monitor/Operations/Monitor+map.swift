import Foundation

public extension Monitor {
    func map<OutputEphemeral, OutputTerminal>(
        ephemeral ephemeralTransform: @escaping Transform<Ephemeral, OutputEphemeral>,
        terminal terminalTransform: @escaping Transform<Terminal, OutputTerminal>
    ) -> Monitor<OutputEphemeral, OutputTerminal> {
        let factory = MapperFactory(ephemeralTransform: ephemeralTransform, terminalTransform: terminalTransform)
        return transform(factory: factory)
    }
}

struct MapperFactory<InputEphemeral, InputTerminal, OutputEphemeral, OutputTerminal>: MonitorTransformingFactory {
    typealias Transforming = Mapper<InputEphemeral, InputTerminal, OutputEphemeral, OutputTerminal>

    init(ephemeralTransform: @escaping Transform<InputEphemeral, OutputEphemeral>,
         terminalTransform: @escaping Transform<InputTerminal, OutputTerminal>) {
        self.ephemeralTransform = ephemeralTransform
        self.terminalTransform = terminalTransform
    }

    func make(feed: Feed<OutputEphemeral, OutputTerminal>) -> Mapper<InputEphemeral, InputTerminal, OutputEphemeral, OutputTerminal> {
        return Mapper(ephemeralTransform: ephemeralTransform, terminalTransform: terminalTransform, feed: feed)
    }

    private let ephemeralTransform: Transform<InputEphemeral, OutputEphemeral>
    private let terminalTransform: Transform<InputTerminal, OutputTerminal>
}

struct Mapper<InputEphemeral, InputTerminal, OutputEphemeral, OutputTerminal>: MonitorTransforming {
    init(ephemeralTransform: @escaping Transform<InputEphemeral, OutputEphemeral>,
         terminalTransform: @escaping Transform<InputTerminal, OutputTerminal>,
         feed: Feed<OutputEphemeral, OutputTerminal>) {
        self.ephemeralTransform = ephemeralTransform
        self.terminalTransform = terminalTransform
        self.feed = feed
    }

    func eat(ephemeral: InputEphemeral) {
        // Context: free
        feed.push(ephemeral: ephemeralTransform(ephemeral))
    }

    func eat(terminal: InputTerminal) {
        // Context: synchronized
        feed.push(terminal: terminalTransform(terminal))
    }

    func cancel(sourceSubscription: Cancelable) {
        // Context: synchronized
        sourceSubscription.cancel()
    }

    private let ephemeralTransform: Transform<InputEphemeral, OutputEphemeral>
    private let terminalTransform: Transform<InputTerminal, OutputTerminal>
    private let feed: Feed<OutputEphemeral, OutputTerminal>
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
