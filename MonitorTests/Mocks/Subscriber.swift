import Foundation
import Monitor

final class Subscriber<Ephemeral, Terminal> {
    init(for monitor: Monitor<Ephemeral, Terminal>, sync: Bool = false) {
        self.sync = sync ? NSLock() : nil
        token = monitor.observe(ephemeral: eat, terminal: eat)
        token?.vanished.execute(callback: { [weak self] token in
            self?.vanishReceived = true
        })
    }

    private func eat(ephemeral: Ephemeral) {
        sync?.lock()
        defer { sync?.unlock() }
        ephemerals.append(ephemeral)
    }

    private func eat(terminal: Terminal) {
        terminals.append(terminal)
    }

    func stop() {
        token?.cancel()
    }

    var ephemerals = [] as [Ephemeral]
    var terminals = [] as [Terminal]

    var vanishReceived = false

    private var token: Vanishable?
    private let sync: NSLock?
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
