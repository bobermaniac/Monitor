import Foundation
import Monitor
import XCTest

final class Example6: XCTestCase {
    func test() throws {
        let x = MutableValue(5 as Double)
        let y = MutableValue(0 as Double)

        let isPointOfCircle = sqrt(pow(x.observableValue, 2) + pow(y.observableValue, 2)) == 5
        let token = isPointOfCircle.observable.observe(ephemeral: { print($0) }, terminal: { _ in })
        XCTAssertTrue(try isPointOfCircle.unwrap())

        x.value = 0
        XCTAssertFalse(try isPointOfCircle.unwrap())

        y.value = 5
        XCTAssertTrue(try isPointOfCircle.unwrap())
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
