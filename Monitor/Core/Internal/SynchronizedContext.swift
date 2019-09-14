import Foundation

final class SynchronizedContext<Content> {
    init(content: Content) {
        self.content = content
    }

    func read<Result>(using threadSafety: ThreadSafetyStrategy,
                      block: (Content) throws -> Result) rethrows -> Result {
        return try threadSafety.interlockedRead {
            // When mutating in progress we should always use immutable copy
            let target = immutableCopy ?? content
            return try block(target)
        }
    }

    func readWrite<Result>(using threadSafety: ThreadSafetyStrategy,
        block: (inout Content) throws -> Result) rethrows -> Result {
        return try threadSafety.interlockedReadWrite {
            // We could easily make read operation while mutating content
            // if no synchronization required or using recursive locks
            // To prevent crashes we always make a copy when start to modify content
            // Read operations can use this copy while mutating in progress
            // to access before-mutated state
            immutableCopy = content
            let result = try block(&content)
            immutableCopy = nil
            return result
        }
    }

    private var content: Content
    private var immutableCopy: Content?
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
