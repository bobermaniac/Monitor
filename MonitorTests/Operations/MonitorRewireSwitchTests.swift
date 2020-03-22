import Foundation
import XCTest
import Monitor

final class MonitorRewireSwitchTests: XCTestCase {
    func test_rewire_allSubsequentTerminatesBeforeTerminalEmitted() {
        let (source, signal) = Signal.make(of: Void.self, Void.self)
        
        var produced = [] as [Signal<Int, Int>]
        func next(_: Void) -> Monitor<Int, Int> {
            let (result, signal) = Signal.make(of: Int.self, Int.self)
            produced.append(signal)
            return result
        }
        
        func sum(lhs: Int, rhs: Int) -> Int {
            return lhs + 1 + rhs
        }
        
        func sum2(lhs: Int, rhs: Int) -> Int {
            return -rhs * lhs;
        }
        
        let subscriber = Subscriber(for: source.rewireSwitch(transform: next,
                                                             reduce: sum,
                                                             terminalReduce: sum2))
        
        signal.emit()
        XCTAssertEqual(produced.count, 1)
        XCTAssertEqual(subscriber.ephemerals, [])
        XCTAssertEqual(subscriber.terminals.count, 0)
        
        produced[0].emit(ephemeral: 1)
        produced[0].emit(ephemeral: 3)
        XCTAssertEqual(subscriber.ephemerals, [])
        
        signal.emit()
        XCTAssertTrue(produced[0].abandoned)
        produced[1].emit(ephemeral: 2)
        produced[1].emit(ephemeral: 4)
        XCTAssertEqual(subscriber.ephemerals, [])
        
        produced[1].terminate(with: 6)
        XCTAssertEqual(subscriber.ephemerals, [-42])
        
        signal.terminate()
        XCTAssertEqual(subscriber.terminals.count, 1)
    }
    
    func test_rewire_sourceTerminatesBeforeSubsequent() {
        let (source, signal) = Signal.make(of: Void.self, Void.self)
        
        var produced = [] as [Signal<Int, Int>]
        func next(_: Void) -> Monitor<Int, Int> {
            let (result, signal) = Signal.make(of: Int.self, Int.self)
            produced.append(signal)
            return result
        }
        
        func sum(lhs: Int, rhs: Int) -> Int {
            return lhs + 1 + rhs
        }
        
        func sum2(lhs: Int, rhs: Int) -> Int {
            return -rhs * lhs;
        }
        
        let subscriber = Subscriber(for: source.rewireSwitch(transform: next,
                                                             reduce: sum,
                                                             terminalReduce: sum2))
        
        signal.emit()
        XCTAssertEqual(produced.count, 1)
        XCTAssertEqual(subscriber.ephemerals, [])
        XCTAssertEqual(subscriber.terminals.count, 0)
        
        produced[0].emit(ephemeral: 1)
        produced[0].emit(ephemeral: 3)
        XCTAssertEqual(subscriber.ephemerals, [])
        
        signal.emit()
        XCTAssertTrue(produced[0].abandoned)
        produced[1].emit(ephemeral: 2)
        produced[1].emit(ephemeral: 4)
        
        signal.terminate()
        XCTAssertTrue(produced[1].abandoned)
        XCTAssertEqual(subscriber.ephemerals, [])
        XCTAssertEqual(subscriber.terminals.count, 1)
    }
    
    func test_rewire_concurrent() {
        let dispatcher = ManualDispatcher(name: "main", simultaneousOperationCount: 4)
        
        let (source, signal) = Signal.make(of: Void.self, Void.self)
        
        var produced = [] as [Signal<Int, Int>]
        func next(_: Void) -> Monitor<Int, Int> {
            let (result, signal) = Signal.make(of: Int.self, Int.self)
            produced.append(signal)
            return result
        }
        
        func sum(lhs: Int, rhs: Int) -> Int {
            return lhs + 1 + rhs
        }
        
        func sum2(lhs: Int, rhs: Int) -> Int {
            return -rhs * lhs;
        }
        
        let subscriber = Subscriber(for: source.rewireSwitch(transform: next,
                                                             reduce: sum,
                                                             terminalReduce: sum2,
                                                             threadSafety: ThreadSafety.interlocked()),
                                    sync: true)
        
        dispatcher.async(flags: .barrier) { signal.emit() }
        [dispatcher].XCTAwaitEqual(produced.count, 1)
        XCTAssertEqual(subscriber.ephemerals, [])
        XCTAssertEqual(subscriber.terminals.count, 0)
        
        dispatcher.async(flags: []) { produced[0].emit(ephemeral: 1) }
        dispatcher.async(flags: []) { produced[0].emit(ephemeral: 3) }

        [dispatcher].XCTFinite()
        XCTAssertEqual(subscriber.ephemerals, [])
        
        dispatcher.async(flags: .barrier) { signal.emit() }
        [dispatcher].XCTAwait(produced[0].abandoned)
        [dispatcher].XCTAwaitEqual(produced.count, 2)
    
        dispatcher.async(flags: []) { produced[1].emit(ephemeral: 2) }
        dispatcher.async(flags: []) { produced[1].emit(ephemeral: 4) }
        dispatcher.async(flags: .barrier) { produced[1].terminate(with: 6) }
        [dispatcher].XCTAwaitEqual(subscriber.ephemerals, [-42])
        
        dispatcher.async(flags: .barrier) { signal.terminate() }
        [dispatcher].XCTAwaitEqual(subscriber.terminals.count, 1)
        
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
