import Foundation
import XCTest
import Monitor

final class MonitorCollectTests: XCTestCase {
    func test_collect2() {
        let (m1, s1) = Signal.make(of: Int.self, Int.self)
        let (m2, s2) = Signal.make(of: Int.self, Int.self)
        
        func map(e: Either<Int, Int>) -> Int {
            switch e {
            case .left(let l):
                return l * 7
            case .right(let r):
                return r * 13
            }
        }
        
        func reduce(a: inout Int, t: Either<Int, Int>) -> Bool {
            switch t {
            case .left(let l):
                a = a + l * 2
            case .right(let r):
                a = a - r * 3
            }
            return false
        }
        
        let m = collect(monitors: m1, m2,
                        ephemeralMapper: map,
                        accumulator: 0,
                        terminalReducer: reduce)
        
        let subscriber = Subscriber(for: m)
        
        s1.emit(ephemeral: 5)
        XCTAssertEqual(subscriber.ephemerals, [35])
        s1.terminate(with: 8)
        s2.emit(ephemeral: 3)
        XCTAssertEqual(subscriber.ephemerals, [35, 39])
        s2.terminate(with: 7)
        XCTAssertEqual(subscriber.terminals, [-5])
    }
    
    func test_collect_failFast() {
        let (m1, s1) = Signal.make(of: Int.self, Int.self)
        let (m2, _) = Signal.make(of: Int.self, Int.self)
        
        func map(e: Either<Int, Int>) -> Int {
            switch e {
            case .left(let l):
                return l * 7
            case .right(let r):
                XCTFail()
                return r * 13
            }
        }
        
        func reduce(a: inout Int, t: Either<Int, Int>) -> Bool {
            switch t {
            case .left(let l):
                a = a + l * 2
            case .right(let r):
                XCTFail()
                a = a - r * 3
            }
            return true
        }
        
        let m = collect(monitors: m1, m2,
                        ephemeralMapper: map,
                        accumulator: 0,
                        terminalReducer: reduce)
        
        let subscriber = Subscriber(for: m)
        
        s1.emit(ephemeral: 5)
        XCTAssertEqual(subscriber.ephemerals, [35])
        s1.terminate(with: 8)
        XCTAssertEqual(subscriber.terminals, [16])
    }
    
    func test_collect_failLast() {
        let (m1, s1) = Signal.make(of: Int.self, Int.self)
        let (m2, s2) = Signal.make(of: Int.self, Int.self)
        
        func map(e: Either<Int, Int>) -> Int {
            switch e {
            case .left(let l):
                return l * 7
            case .right(let r):
                return r * 13
            }
        }
        
        func reduce(a: inout Int, t: Either<Int, Int>) -> Bool {
            switch t {
            case .left(let l):
                a = a + l * 2
                return false
            case .right(let r):
                a = a - r * 3
                return true
            }
        }
        
        let m = collect(monitors: m1, m2,
                        ephemeralMapper: map,
                        accumulator: 0,
                        terminalReducer: reduce)
        
        let subscriber = Subscriber(for: m)
        
        s1.emit(ephemeral: 5)
        XCTAssertEqual(subscriber.ephemerals, [35])
        s1.terminate(with: 8)
        s2.emit(ephemeral: 3)
        XCTAssertEqual(subscriber.ephemerals, [35, 39])
        s2.terminate(with: 7)
        XCTAssertEqual(subscriber.terminals, [-5])
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
