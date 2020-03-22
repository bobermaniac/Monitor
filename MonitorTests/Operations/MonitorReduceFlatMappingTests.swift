import Foundation
import XCTest
import Monitor

final class MonitorReduceFlatMappingTests: XCTestCase {
    func test_reduceFlatMap() {
        let (initial, signal) = Signal.make(of: Int.self, Int.self)
        
        var produced = [] as [Signal<Int, Void>]
        func makeNext(for source: Int) -> Monitor<Int, Void> {
            let (result, signal) = Signal.make(of: Int.self, Void.self)
            produced.append(signal)
            return result
        }
        
        func sum(lhs: Int, rhs: Int) -> Int { return lhs + rhs }
        func sum2(lhs: Int, rhs: Void) -> Int { return lhs + 1 }
        
        let subscriber = Subscriber(for: initial.reduceFlatMap(accumulator: 0,
                                                               ephemeralTransform: makeNext,
                                                               intermediateTerminalReducer: sum2,
                                                               terminalReducer: sum))
        signal.emit(ephemeral: 1)
        signal.emit(ephemeral: 2)
        signal.emit(ephemeral: 3)
        
        XCTAssertEqual(subscriber.ephemerals, [])
        XCTAssertEqual(subscriber.terminals, [])
        XCTAssertEqual(produced.count, 3)
        
        produced[0].emit(ephemeral: 1)
        produced[2].emit(ephemeral: 3)
        produced[1].terminate(with: ())
        
        XCTAssertEqual(subscriber.ephemerals, [1, 3])
        XCTAssertEqual(subscriber.terminals, [])
        
        produced[0].emit(ephemeral: 5)
        produced[2].terminate(with: ())
        produced[0].terminate(with: ())
        
        XCTAssertEqual(subscriber.ephemerals, [1, 3, 5])
        XCTAssertEqual(subscriber.terminals, [])
        
        signal.terminate(with: 7)

        XCTAssertEqual(subscriber.ephemerals, [1, 3, 5])
        XCTAssertEqual(subscriber.terminals, [10])
    }
    
    func test_reduceFlatMap_concurrent() {
        let dispatcher = ManualDispatcher(name: "main", simultaneousOperationCount: 4)
        let (initial, signal) = Signal.make(of: Int.self, Int.self)
        
        var produced = [] as [Signal<Int, Void>]
        func makeNext(for source: Int) -> Monitor<Int, Void> {
            let (result, signal) = Signal.make(of: Int.self, Void.self)
            produced.append(signal)
            return result
        }
        
        func sum(lhs: Int, rhs: Int) -> Int { return lhs + rhs }
        func inc(lhs: Int, rhs: Void) -> Int { return lhs + 1 }
        
        let subscriber = Subscriber(for: initial.reduceFlatMap(accumulator: 0,
                                                               ephemeralTransform: makeNext,
                                                               intermediateTerminalReducer: inc,
                                                               terminalReducer: sum),
                                    sync: true)
        for index in 0..<4 {
            dispatcher.async(flags: [.barrier]) { [index] in signal.emit(ephemeral: index) }
        }
        
        [dispatcher].XCTAwaitEqual(produced.count, 4)
        XCTAssertEqual(subscriber.ephemerals, [])
        XCTAssertEqual(subscriber.terminals, [])
        
        dispatcher.async(flags: []) { produced[0].emit(ephemeral: 1) }
        dispatcher.async(flags: []) { produced[2].emit(ephemeral: 3) }
        dispatcher.async(flags: []) { produced[3].emit(ephemeral: 5) }
        dispatcher.async(flags: .barrier) { produced[1].terminate(with: ()) }
        
        [dispatcher].XCTAwaitUnorderedEqual(subscriber.ephemerals, [1, 3, 5])
        XCTAssertEqual(subscriber.terminals, [])
        
        dispatcher.async(flags: []) { produced[0].emit(ephemeral: 7)}
        dispatcher.async(flags: .barrier) { produced[2].terminate(with: ()) }
        dispatcher.async(flags: .barrier) { produced[0].terminate(with: ()) }
        dispatcher.async(flags: .barrier) { produced[3].terminate(with: ()) }
        
        [dispatcher].XCTAwaitUnorderedEqual(subscriber.ephemerals, [1, 3, 5, 7])
        XCTAssertEqual(subscriber.terminals, [])
        
        dispatcher.async(flags: .barrier) { signal.terminate(with: 7) }
        
        [dispatcher].XCTAwaitEqual(subscriber.terminals, [11])
        XCTAssertUnorderedEqual(subscriber.ephemerals, [1, 3, 5, 7])
        
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
