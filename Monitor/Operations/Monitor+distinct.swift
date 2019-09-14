import Foundation

public extension Monitor {
    func distinct(comparator isEqual: @escaping Comparator<Ephemeral>,
                  threadSafety: ThreadSafetyStrategy = CalleeSyncGuaranteed()) -> Monitor {
        let factory = DistinctFactory(comparator: isEqual, threadSafety: threadSafety, terminalType: Terminal.self)
        return transform(factory: factory)
    }
}

public extension Monitor where Ephemeral: Equatable {
    func distinct(threadSafety: ThreadSafetyStrategy = CalleeSyncGuaranteed()) -> Monitor {
        return distinct(comparator: ==, threadSafety: threadSafety)
    }
}

struct DistinctFactory<Ephemeral, Terminal>: MonitorTransformingFactory {
    typealias Transforming = Distinct<Ephemeral, Terminal>

    init(comparator isEqual: @escaping Comparator<Ephemeral>,
         threadSafety: ThreadSafetyStrategy,
         terminalType: Terminal.Type) {
        self.isEqual = isEqual
        self.threadSafety = threadSafety
    }

    func make(feed: Feed<Ephemeral, Terminal>) -> Distinct<Ephemeral, Terminal> {
        return Distinct(comparator: isEqual, threadSafety: threadSafety, feed: feed)
    }

    private let isEqual: Comparator<Ephemeral>
    private let threadSafety: ThreadSafetyStrategy
}

struct Distinct<Ephemeral, Terminal>: MonitorTransforming {
    typealias InputEphemeral = Ephemeral
    typealias InputTerminal = Terminal
    typealias OutputEphemeral = Ephemeral
    typealias OutputTerminal = Terminal

    init(comparator isEqual: @escaping Comparator<Ephemeral>,
         threadSafety: ThreadSafetyStrategy,
         feed: Feed<Ephemeral, Terminal>) {
        self.isEqual = isEqual
        self.threadSafety = threadSafety
        self.feed = feed
        self.synchronizedContext = SynchronizedContext(content: MutableState())
    }

    func eat(ephemeral: Ephemeral) {
        // Context: free
        let sync = threadSafety

        let shoudEmit = synchronizedContext.readWrite(using: sync) { state in
            if let previous = state.previousEmittedEphemeral, isEqual(previous, ephemeral) {
                return false
            }
            state.previousEmittedEphemeral = ephemeral
            return true
        } as Bool

        if shoudEmit {
            feed.push(ephemeral: ephemeral)
        }
    }

    func eat(terminal: Terminal) {
        // Context: synchronized [terminal]
        feed.push(terminal: terminal)
    }

    func cancel(sourceSubscription: Cancelable) {
        // Context: synchronized [cancelation]
        sourceSubscription.cancel()
    }

    private let isEqual: Comparator<Ephemeral>
    private let threadSafety: ThreadSafetyStrategy
    private let feed: Feed<Ephemeral, Terminal>
    private let synchronizedContext: SynchronizedContext<MutableState>

    private struct MutableState {
        init() { }

        var previousEmittedEphemeral: Ephemeral?
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
