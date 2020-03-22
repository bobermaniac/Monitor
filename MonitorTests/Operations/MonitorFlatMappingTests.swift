import Foundation
import XCTest
import Monitor

final class MonitorFlatMappingTests: XCTestCase {
    func test_flatMap() {
        let (initial, signal) = Signal.make(of: Int.self, Int.self)
        
        var produced = [] as [Signal<Int, Int>]
        func makeNext(for source: Int) -> Monitor<Int, Int> {
            let (result, signal) = Signal.make(of: Int.self, Int.self)
            produced.append(signal)
            return result
        }
        
        let subscriber = Subscriber(for: initial.flatMap(ephemeral: makeNext,
                                                         terminal: makeNext,
                                                         reducer: { $0 + $1 }))
        signal.emit(ephemeral: 1)
        signal.emit(ephemeral: 2)
        signal.emit(ephemeral: 3)
        
        XCTAssertEqual(subscriber.ephemerals, [])
        XCTAssertEqual(subscriber.terminals, [])
        XCTAssertEqual(produced.count, 3)
        
        produced[0].emit(ephemeral: 1)
        produced[2].emit(ephemeral: 3)
        produced[1].terminate(with: 2)
        
        XCTAssertEqual(subscriber.ephemerals, [1, 3])
        XCTAssertEqual(subscriber.terminals, [])
        
        produced[0].emit(ephemeral: 5)
        produced[2].terminate(with: 5)
        produced[0].terminate(with: 7)
        
        XCTAssertEqual(subscriber.ephemerals, [1, 3, 5])
        XCTAssertEqual(subscriber.terminals, [])
        
        signal.terminate(with: 0)
        
        produced[3].emit(ephemeral: 7)
        produced[3].terminate(with: 9)
        XCTAssertEqual(subscriber.ephemerals, [1, 3, 5, 7])
        XCTAssertEqual(subscriber.terminals, [23])
    }
    
    func test_flatMap_concurrent() {
        let dispatcher = ManualDispatcher(name: "main", simultaneousOperationCount: 4)
        let (initial, signal) = Signal.make(of: Int.self, Int.self)
        
        var produced = [] as [Signal<Int, Int>]
        func makeNext(for source: Int) -> Monitor<Int, Int> {
            let (result, signal) = Signal.make(of: Int.self, Int.self)
            produced.append(signal)
            return result
        }
        
        let subscriber = Subscriber(for: initial.flatMap(ephemeral: makeNext,
                                                         terminal: makeNext,
                                                         reducer: { $0 + $1 }),
                                    sync: true)
        
        for index in 0..<4 {
            dispatcher.async(flags: .barrier, execute: { [index] in signal.emit(ephemeral: index) })
        }
        
        [dispatcher].XCTAwait(produced.count == 4)
        XCTAssertEqual(subscriber.ephemerals, [])
        XCTAssertEqual(subscriber.terminals, [])
        
        dispatcher.async(flags: [], execute: { produced[0].emit(ephemeral: 1) })
        dispatcher.async(flags: [], execute: { produced[2].emit(ephemeral: 3) })
        dispatcher.async(flags: [], execute: { produced[3].emit(ephemeral: 5) })
        dispatcher.async(flags: .barrier, execute: { produced[1].terminate(with: 2) })
        
        [dispatcher].XCTAwaitUnorderedEqual(subscriber.ephemerals, [1, 3, 5])
        XCTAssertEqual(subscriber.terminals, [])
        
        dispatcher.async(flags: [], execute: { produced[0].emit(ephemeral: 7) })
        dispatcher.async(flags: .barrier, execute: { produced[2].terminate(with: 5) })
        dispatcher.async(flags: .barrier, execute: { produced[0].terminate(with: 7) })
        dispatcher.async(flags: .barrier, execute: { produced[3].terminate(with: 9) })
        
        [dispatcher].XCTAwaitUnorderedEqual(subscriber.ephemerals, [1, 3, 5, 7])
        XCTAssertEqual(subscriber.terminals, [])
        
        dispatcher.async(flags: .barrier, execute: { signal.terminate(with: 0) })
        dispatcher.async(flags: [], execute: { produced[4].emit(ephemeral: 9) })
        dispatcher.async(flags: .barrier, execute: { produced[4].terminate(with: 9) })
        
        [dispatcher].XCTAwaitEqual(subscriber.terminals, [32])
        XCTAssertUnorderedEqual(subscriber.ephemerals, [1, 3, 5, 7, 9])
        
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
