import Foundation
import XCTest

func XCTNever(condition: @escaping () -> Bool,
              message: String,
              file: StaticString = #file,
              line: UInt = #line,
              in scope: () -> Void) {
    let advice = ManualDispatcher.introduce(in: .afterDispatchedEntitiyInvocation) {
        XCTAssertFalse(condition(), message, file: file, line: line)
    }
    scope()
    advice.cancel()
    XCTAssertFalse(condition(), message, file: file, line: line)
}

func XCTNever(_ condition: @autoclosure @escaping () -> Bool,
              message: String,
              file: StaticString = #file,
              line: UInt = #line,
              in scope: () -> Void) {
    XCTNever(condition: condition, message: message, file: file, line: line, in: scope)
}

// Copyright (C) 2020 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
