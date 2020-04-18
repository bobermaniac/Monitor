import Foundation
import XCTest
import Monitor

final class MonitorDebounceTests: XCTestCase {
    func test_debounce_plain() {
        let dispatcher = ManualDispatcher(name: "main", simultaneousOperationCount: 1)
        let (source, signal) = Signal.make(of: Int.self, Void.self)
        
        let subscriber = dispatcher.sync(flags: .barrier) {
            Subscriber(for: source.debounce(timeout: 1, dispatcher: dispatcher))
        }
        
        dispatcher.sync(flags: []) { signal.emit(ephemeral: 1) }
        dispatcher.dispatchUntil(timeInterval: 0.9)
        XCTAssertEqual(subscriber.ephemerals, [])
        
        dispatcher.dispatchUntil(timeInterval: 0.1)
        XCTAssertEqual(subscriber.ephemerals, [1])
        
        [dispatcher].XCTFinite()
    }
    
    func test_debounce_override() {
        let dispatcher = ManualDispatcher(name: "main", simultaneousOperationCount: 1)
        let (source, signal) = Signal.make(of: Int.self, Void.self)
        
        let subscriber = dispatcher.sync(flags: .barrier) {
            Subscriber(for: source.debounce(timeout: 1, dispatcher: dispatcher))
        }
        
        dispatcher.sync(flags: []) { signal.emit(ephemeral: 1) }
        dispatcher.dispatchUntil(timeInterval: 0.9)
        XCTAssertEqual(subscriber.ephemerals, [])
        
        dispatcher.sync(flags: []) { signal.emit(ephemeral: 2) }
        dispatcher.dispatchUntil(timeInterval: 0.9)
        XCTAssertEqual(subscriber.ephemerals, [])
        
        dispatcher.dispatchUntil(timeInterval: 0.1)
        XCTAssertEqual(subscriber.ephemerals, [2])
        
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
