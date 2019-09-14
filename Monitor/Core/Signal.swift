import Foundation

public struct Signal<Ephemeral, Terminal> {
    public init(of _: Ephemeral.Type = Ephemeral.self, _: Terminal.Type = Terminal.self) {
        (monitor, feed) = Monitor.make()
    }

    public let monitor: Monitor<Ephemeral, Terminal>

    public func emit(ephemeral: Ephemeral) {
        feed.push(ephemeral: ephemeral)
    }

    public func terminate(with terminal: Terminal) {
        feed.push(terminal: terminal)
    }

    public func canceled(callback: @escaping Action) {
        feed.addCancelationObserver(onCancel: callback)
    }

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
