import Foundation

public extension Monitor where Terminal == Void {
    func map<T>(ephemeral transform: @escaping Transform<Ephemeral, T>) -> Monitor<T, Void> {
        return map(ephemeral: transform, terminal: identity)
    }

    func scan<U>(accumulator: U,
                 reducer: @escaping Reduce<U, Ephemeral>,
                 threadSafety: ThreadSafetyStrategy = CalleeSyncGuaranteed()) -> Monitor<U, Void> {
        return scan(accumulator: accumulator, ephemeralReducer: reducer, terminalReducer: second, threadSafety: threadSafety)
    }

    func reduce<U>(accumulator: U,
                   reducer: @escaping Reduce<U, Ephemeral>,
                   threadSafety: ThreadSafetyStrategy = CalleeSyncGuaranteed()) -> Monitor<Never, U> {
        return scan(accumulator: accumulator, ephemeralReducer: reducer, terminalReducer: first, threadSafety: threadSafety).filter()
    }

    func flatMap<T>(ephemeral transform: @escaping Transform<Ephemeral, Monitor<T, Void>>,
                    threadSafety: ThreadSafetyStrategy = CalleeSyncGuaranteed()) -> Monitor<T, Void> {
        return reduceFlatMap(accumulator: (),
                             ephemeralTransform: transform,
                             intermediateTerminalReducer: first,
                             terminalReducer: first,
                             threadSafety: threadSafety)
    }

    func switchMap<T>(ephemeral transform: @escaping Transform<Ephemeral, Monitor<T, Void>>,
                      threadSafety: ThreadSafetyStrategy = CalleeSyncGuaranteed()) -> Monitor<T, Void> {
        return switchMap(ephemeral: transform,
                         terminal: mkv,
                         threadSafety: threadSafety)
    }
}

private func mkv<T, U>(_: T) -> Monitor<U, Void> {
    return Monitor(terminal: ())
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
