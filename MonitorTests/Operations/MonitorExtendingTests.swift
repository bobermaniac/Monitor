import Foundation
import XCTest
import Monitor

final class MonitorExtendingTests: XCTestCase {
    func test_extend() {
        let (first, signal1) = Signal.make(of: Int.self, Int.self)
        let (second, signal2) = Signal.make(of: Int.self, Int.self)
        
        func extender(input: Int) -> Monitor<Int, Int> {
            XCTAssertEqual(input, 50)
            return second
        }
        
        let subscriber = Subscriber(for: first.extend(using: extender(input:)))
        signal1.emit(ephemeral: 1)
        signal1.emit(ephemeral: 2)
        signal2.emit(ephemeral: 3)
        signal1.terminate(with: 50)
        signal2.emit(ephemeral: 4)
        signal2.terminate(with: 100)
        
        XCTAssertEqual(subscriber.ephemerals, [1, 2, 4])
        XCTAssertEqual(subscriber.terminals, [100])
    }
    
    func test_extend_concurrent() {
        let dispatcher = ManualDispatcher(name: "main", simultaneousOperationCount: 16)
        
        let (first, signal1) = Signal.make(of: Int.self, Int.self)
        let (second, signal2) = Signal.make(of: Int.self, Int.self)
        
        func extender(input: Int) -> Monitor<Int, Int> {
            XCTAssertEqual(input, 50)
            return second
        }
        
        let subscriber = Subscriber(for: first.extend(using: extender(input:)), sync: true)
        for index in 1...16 {
            dispatcher.async(flags: [], execute: { [index] in signal1.emit(ephemeral: index) })
        }
        dispatcher.async(flags: .barrier, execute: { signal1.terminate(with: 50) })
        for index in 1...16 {
            dispatcher.async(flags: [], execute: { [index] in signal2.emit(ephemeral: index) })
        }
        dispatcher.async(flags: .barrier, execute: { signal2.terminate(with: 100) })
        
        [dispatcher].XCTAwaitEqual(subscriber.terminals, [100])
        XCTAssertUnorderedEqual(subscriber.ephemerals, Array(1...16) + Array(1...16))
        XCTAssertEqual(subscriber.ephemerals.count, 32)
        
        [dispatcher].XCTFinite()
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
