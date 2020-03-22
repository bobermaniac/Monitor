import Foundation
import XCTest
import Monitor

final class MonitorMapTests: XCTestCase {
    func test_mapping() {
        let (monitor, signal) = Signal.make(of: Int.self, Int.self)
        let transformResult = monitor.map(ephemeral: { $0 + 1 }, terminal: { $0 + 2})
        let subscriber = Subscriber(for: transformResult)
        
        signal.emit(ephemeral: 1)
        signal.emit(ephemeral: 2)
        signal.emit(ephemeral: 3)
        XCTAssertEqual(subscriber.ephemerals, [2, 3, 4])
        XCTAssertEqual(subscriber.terminals, [])
        
        signal.terminate(with: 1)
        XCTAssertEqual(subscriber.terminals, [3])
    }
    
    func test_mapping_concurrent() {
        let dispatcher = ManualDispatcher(name: "main", simultaneousOperationCount: 16)
        
        let (monitor, signal) = Signal.make(of: Int.self, Int.self)
        let transformResult = monitor.map(ephemeral: { $0 + 1 }, terminal: { $0 + 2 })
        let subscriber = Subscriber(for: transformResult, sync: true)
        
        for index in 1...16 {
            dispatcher.async(flags: [], execute: { [index] in signal.emit(ephemeral: index) })
        }
        dispatcher.async(flags: [.barrier], execute: { signal.terminate(with: 0) })
        [dispatcher].XCTAwaitEqual(subscriber.terminals, [2])
        
        XCTAssertUnorderedEqual(2...17, subscriber.ephemerals)

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
