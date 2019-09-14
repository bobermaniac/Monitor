import Foundation

final class FreeContext<Content> {
    init(content: Content) {
        self.content = content
    }

    func read<Result>(block: (Content) throws -> Result) rethrows -> Result {
        return try block(immutableCopy ?? content)
    }

    func readWrite<Result>(block: (inout Content) throws -> Result) rethrows -> Result {
        immutableCopy = content
        let result = try block(&content)
        immutableCopy = nil
        return result
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
