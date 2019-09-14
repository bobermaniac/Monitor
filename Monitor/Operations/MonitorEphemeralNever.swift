import Foundation

public extension Monitor where Ephemeral == Never {
    func observe(terminal: @escaping Consumer<Terminal>) -> Vanishable {
        return observe(ephemeral: absurd, terminal: terminal)
    }

    func cast<T>(ephemeral _: T.Type = T.self) -> Monitor<T, Terminal> {
        return map(ephemeral: absurd, terminal: identity)
    }

    func map<T>(terminal: @escaping Transform<Terminal, T>) -> Monitor<Never, T> {
        return map(ephemeral: absurd, terminal: terminal)
    }
}

public extension Monitor {
    func filter() -> Monitor<Never, Terminal> {
        return filter(using: alwaysFalse).map(ephemeral: unreachable, terminal: identity)
    }

    func rewire<RewiredTerminal>(ephemeral ephemeralTransform: @escaping Transform<Ephemeral, Monitor<Never, RewiredTerminal>>) -> Monitor<RewiredTerminal, Terminal> {
        return rewire(ephemeral: ephemeralTransform, reduce: absurd, terminalReduce: absurd)
    }

    func rewireAll<RewiredTerminal>(ephemeral ephemeralTransform: @escaping Transform<Ephemeral, Monitor<Never, RewiredTerminal>>) -> Monitor<RewiredTerminal, Terminal> {
        return rewireAll(ephemeral: ephemeralTransform, reduce: absurd, terminalReduce: absurd)
    }

    func rewireSwitch<OutputTerminal>(
        transform ephemeralTransform: @escaping Transform<Ephemeral, Monitor<Never, OutputTerminal>>
        ) -> Monitor<OutputTerminal, Terminal> {
        return rewireSwitch(transform: ephemeralTransform,
                            reduce: absurd,
                            terminalReduce: absurd,
                            threadSafety: CalleeSyncGuaranteed())
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
