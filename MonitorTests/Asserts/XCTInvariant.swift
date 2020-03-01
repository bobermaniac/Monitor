import Foundation
import XCTest

func XCTInvariant<T: Comparable>(expression: @escaping () -> T,
                                 file: StaticString = #file,
                                 line: UInt = #line) -> XCTNeverScope {
    let initialValue = expression()
    let predicate = XCTNeverPredicate(condition: { initialValue != expression() },
                                      message: "invariant failed: initial value \(initialValue) was changed to \(expression())",
                                      file: file,
                                      line: line)
    return XCTNeverScope(predicates: [predicate])
}

func XCTInvariant<T: Comparable>(_ expression: @autoclosure @escaping () -> T,
                                 file: StaticString = #file,
                                 line: UInt = #line) -> XCTNeverScope {
    return XCTInvariant(expression: expression, file: file, line: line)
}

func XCTInvariant<T1: Comparable, T2: Comparable>(
    _ expression1: @autoclosure @escaping () -> T1,
    _ expression2: @autoclosure @escaping () -> T2,
    file: StaticString = #file,
    line: UInt = #line) -> XCTNeverScope {
    return XCTInvariant(expression: expression1, file: file, line: line)
        && XCTInvariant(expression: expression2, file: file, line: line)
}

struct XCTNeverPredicate {
    init(condition: @escaping () -> Bool,
         message: @autoclosure @escaping () -> String,
         file: StaticString,
         line: UInt) {
        self.condition = condition
        self.message = message
        self.file = file
        self.line = line
    }
    
    let condition: () -> Bool
    let message: () -> String
    let file: StaticString
    let line: UInt
}

struct XCTNeverScope {
    init(predicates: [XCTNeverPredicate]) {
        self.predicates = predicates
    }
    
    func ensure(in scope: () -> Void) {
        let advice = ManualDispatcher.introduce(in: .afterDispatchedEntitiyInvocation) {
            for predicate in self.predicates {
                XCTAssertFalse(predicate.condition(),
                               predicate.message(),
                               file: predicate.file,
                               line: predicate.line)
            }

        }
        scope()
        advice.cancel()
        for predicate in self.predicates {
            XCTAssertFalse(predicate.condition(),
                           predicate.message(),
                           file: predicate.file,
                           line: predicate.line)
        }
    }
    
    private let predicates: [XCTNeverPredicate]
    
    static func &&(lhs: XCTNeverScope, rhs: XCTNeverScope) -> XCTNeverScope {
        return XCTNeverScope(predicates: lhs.predicates + rhs.predicates)
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
