import Foundation
import XCTest
import Monitor

final class MonitorSwitchMappingTests: XCTestCase {
    func test_switchMap() {
        let (source, signal) = Signal.make(of: Void.self, Int.self)
        
        var pending = [] as [Signal<Int, Int>]
        func makeNext<T>(_: T) -> Monitor<Int, Int> {
            let (result, signal) = Signal.make(of: Int.self, Int.self)
            pending.append(signal)
            return result
        }
        
        let subscriber = Subscriber(for: source.switchMap(ephemeral: makeNext,
                                                          terminal: makeNext))
        signal.emit(ephemeral: ())
        XCTAssertEqual(pending.count, 1)
        
        pending[0].emit(ephemeral: 1)
        pending[0].emit(ephemeral: 2)
        
        signal.emit(ephemeral: ())
        XCTAssertTrue(pending[0].abandoned)
        
        pending[0].emit(ephemeral: 3)
        pending[0].terminate(with: 4)
        
        XCTAssertEqual(subscriber.ephemerals, [1, 2])
        XCTAssertEqual(subscriber.terminals, [])
        
        pending[1].emit(ephemeral: 5)
        signal.terminate(with: 0)
        pending[2].emit(ephemeral: 6)
        pending[2].terminate(with: 7)
        
        XCTAssertEqual(subscriber.ephemerals, [1, 2, 5, 6])
        XCTAssertEqual(subscriber.terminals, [7])
    }
    
    func test_switchMap_concurrent() {
        let dispatcher = ManualDispatcher(name: "main", simultaneousOperationCount: 4)
        let (source, signal) = Signal.make(of: Void.self, Int.self)
        
        var pending = [] as [Signal<Int, Int>]
        func makeNext<T>(_: T) -> Monitor<Int, Int> {
            let (result, signal) = Signal.make(of: Int.self, Int.self)
            pending.append(signal)
            return result
        }
        
        let subscriber = Subscriber(for: source.switchMap(ephemeral: makeNext,
                                                          terminal: makeNext),
                                    sync: true)
        dispatcher.async(flags: .barrier) { signal.emit(ephemeral: ()) }
        [dispatcher].XCTAwaitEqual(pending.count, 1)
        
        dispatcher.async(flags: []) { pending[0].emit(ephemeral: 1) }
        dispatcher.async(flags: []) { pending[0].emit(ephemeral: 2) }
        
        dispatcher.async(flags: .barrier) { signal.emit(ephemeral: ()) }
        
        [dispatcher].XCTAwait(pending[0].abandoned)
        
        dispatcher.async(flags: []) { pending[0].emit(ephemeral: 3) }
        dispatcher.async(flags: .barrier) { pending[0].terminate(with: 4) }
        
        [dispatcher].XCTAwaitUnorderedEqual(subscriber.ephemerals, [1, 2])
        XCTAssertEqual(subscriber.terminals, [])
        
        dispatcher.async(flags: []) { pending[1].emit(ephemeral: 5) }
        dispatcher.async(flags: .barrier) { signal.terminate(with: 0) }
        dispatcher.async(flags: []) { pending[2].emit(ephemeral: 6) }
        dispatcher.async(flags: .barrier) { pending[2].terminate(with: 7) }
        
        [dispatcher].XCTAwaitEqual(subscriber.terminals, [7])
        XCTAssertUnorderedEqual(subscriber.ephemerals, [1, 2, 5, 6])
        
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
