import Foundation
import XCTest
import Monitor

final class MonitorDistinctTests: XCTestCase {
    func test_distinct() {
        let (monitor, signal) = Signal.make(of: Int.self, Int.self)
        let subscriber = Subscriber(for: monitor.distinct())
        
        signal.emit(ephemeral: 1)
        signal.emit(ephemeral: 2)
        signal.emit(ephemeral: 3)
        signal.emit(ephemeral: 3)
        signal.emit(ephemeral: 3)
        signal.emit(ephemeral: 2)
        XCTAssertEqual(subscriber.ephemerals, [1, 2, 3, 2])
        XCTAssertEqual(subscriber.terminals, [])
        
        signal.terminate(with: 1)
        XCTAssertEqual(subscriber.terminals, [1])
    }
    
    func test_mapping_concurrent() {
        let dispatcher = ManualDispatcher(name: "main", simultaneousOperationCount: 4)
        
        let (monitor, signal) = Signal.make(of: Int.self, Int.self)
        let transformResult = monitor.distinct(threadSafety: ThreadSafety.interlocked())
        let subscriber = Subscriber(for: transformResult, sync: true)
        
        for index in 0...15 {
            dispatcher.async(flags: [], execute: { [index] in signal.emit(ephemeral: index / 4) })
        }
        dispatcher.async(flags: [.barrier], execute: { signal.terminate(with: 0) })
        [dispatcher].XCTAwaitEqual(subscriber.terminals, [0])
        
        XCTAssertEqual(subscriber.ephemerals, Array(0...3))

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
