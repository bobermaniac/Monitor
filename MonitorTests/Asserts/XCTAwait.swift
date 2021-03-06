import Foundation
import XCTest

extension Sequence where Element == ManualDispatcher {
    func XCTAwait(condition: () -> Bool,
                  on targetDispatcher: ManualDispatcher?,
                  file: StaticString = #file,
                  line: UInt = #line) {
        if let targetDispatcher = targetDispatcher {
            assert(self.contains(targetDispatcher))
            XCTAssertFalse(condition(), "await condition is intially false", file: file, line: line)
        }
        
        var wasAnythingDispatched = false
        repeat {
            wasAnythingDispatched = false
            for dispatcher in self {
                if dispatcher.dispatchNext() {
                    wasAnythingDispatched = true
                    if condition() {
                        if let targetDispatcher = targetDispatcher {
                            XCTAssertTrue(dispatcher === targetDispatcher,
                                          "expected \(targetDispatcher), found \(dispatcher)",
                                          file: file,
                                          line: line)
                        }
                        return
                    }
                }
            }
        } while wasAnythingDispatched
        XCTAssertTrue(condition(), "await condition does not met", file: file, line: line)
    }
    
    func XCTAwait(_ condition: @autoclosure () -> Bool,
                  file: StaticString = #file,
                  line: UInt = #line) {
        return XCTAwait(condition: condition, on: nil, file: file, line: line)
    }
    
    func XCTAwait(_ condition: @autoclosure () -> Bool,
                  on targetDispatcher: ManualDispatcher,
                  file: StaticString = #file,
                  line: UInt = #line) {
        return XCTAwait(condition: condition, on: targetDispatcher, file: file, line: line)
    }
    
    func XCTAwaitEqual<T: Equatable>(_ lhs: @autoclosure () -> T,
                                     _ rhs: @autoclosure () -> T,
                                     file: StaticString = #file,
                                     line: UInt = #line) {
        return XCTAwait(condition: { lhs() == rhs() }, on: nil, file: file, line: line)
    }
    
    func XCTAwaitUnorderedEqual<C1: Sequence, C2: Sequence>(
        _ lhs: @autoclosure () -> C1,
        _ rhs: @autoclosure () -> C2,
        file: StaticString = #file,
        line: UInt = #line
    ) where C1.Element == C2.Element, C1.Element: Comparable {
        return XCTAwait(condition: { lhs().sorted() == rhs().sorted() }, on: nil, file: file, line: line)
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
