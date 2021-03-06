import Foundation
import XCTest

extension Sequence where Element == ManualDispatcher {
    func XCTFinite(maxNumberOfInvocations: UInt = 1000,
                   file: StaticString = #file,
                   line: UInt = #line) {
        for _ in 0..<maxNumberOfInvocations {
            var hasInvocation = false
            for dispatcher in self {
                hasInvocation = hasInvocation || dispatcher.dispatchNext(timeInterval: 1)
            }
            if !hasInvocation {
                return
            }
        }
        XCTFail("After \(maxNumberOfInvocations) there is still pending blocks",
                file: file,
                line: line)
    }
}

// Copyright (C) 2020 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
