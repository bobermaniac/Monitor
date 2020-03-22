import Foundation
import XCTest
import Monitor

final class MonitorScanningTests: XCTestCase {
    func test_scanning_interlocked_singleThreaded() {
        let (monitor, signal) = Signal.make(of: Int.self, Int.self)
        let transformResult = monitor.scan(accumulator: [] as [Int],
                                           ephemeralReducer: appended(to:value:),
                                           terminalReducer: sum,
                                           mode: .interlocked,
                                           threadSafety: ThreadSafety.none())
        let subscriber = Subscriber(for: transformResult)
        for index in 0..<32 {
            signal.emit(ephemeral: index)
        }
        
        XCTAssertEqual(subscriber.ephemerals.count, 32)
        XCTAssertEqual(subscriber.terminals, [])
        
        signal.terminate(with: 4)
        XCTAssertEqual(subscriber.ephemerals.count, 32)
        XCTValidatePartialSums(of: subscriber.ephemerals)
        XCTAssertEqual(subscriber.terminals, [500])
    }
    
    func test_scanning_interlocked_multithreadedThreaded() {
        let dispatcher = ManualDispatcher(name: "main", simultaneousOperationCount: 16)
        
        let (monitor, signal) = Signal.make(of: Int.self, Int.self)
        let transformResult = monitor.scan(accumulator: [] as [Int],
                                           ephemeralReducer: appended(to:value:),
                                           terminalReducer: sum,
                                           mode: .interlocked,
                                           threadSafety: ThreadSafety.interlocked())
        let subscriber = Subscriber(for: transformResult, sync: true)
        for index in 0..<32 {
            dispatcher.async(flags: [], execute: { [index] in signal.emit(ephemeral: index) })
        }
        [dispatcher].XCTAwaitEqual(subscriber.ephemerals.count, 32)
        
        dispatcher.async(flags: [.barrier], execute: { signal.terminate(with: 4) })
        [dispatcher].XCTAwaitEqual(subscriber.terminals, [500])
        
        XCTValidatePartialSums(of: subscriber.ephemerals)
        
        [dispatcher].XCTFinite()
    }
    
    func test_scanning_concurrent_multithreadedThreaded() {
        let dispatcher = ManualDispatcher(name: "main", simultaneousOperationCount: 16)
        
        let (monitor, signal) = Signal.make(of: Int.self, Int.self)
        let transformResult = monitor.scan(accumulator: [] as [Int],
                                           ephemeralReducer: appended(to:value:),
                                           terminalReducer: sum,
                                           mode: .interlocked,
                                           threadSafety: ThreadSafety.interlocked())
        let subscriber = Subscriber(for: transformResult, sync: true)
        for index in 0..<32 {
            dispatcher.async(flags: [], execute: { [index] in signal.emit(ephemeral: index) })
        }
        [dispatcher].XCTAwaitEqual(subscriber.ephemerals.count, 32)
        
        dispatcher.async(flags: [.barrier], execute: { signal.terminate(with: 4) })
        [dispatcher].XCTAwaitEqual(subscriber.terminals, [500])
        
        XCTValidatePartialSums(of: subscriber.ephemerals)
        
        [dispatcher].XCTFinite()
    }
}

private func appended(to array: [Int], value: Int) -> [Int] {
    return array + [value]
}

private func sum(of elements: [Int], with value: Int) -> Int {
    return elements.reduce(0, { $0 + $1 }) + value
}

private func XCTValidatePartialSums(of array: [[Int]], file: StaticString = #file, line: UInt = #line) {
    let lookup = Dictionary(array.map { ($0.count, $0)}, uniquingKeysWith: { lhs, _ in lhs })
    guard var current = lookup.keys.min() else { return }
    repeat {
        let next = current + 1
        guard let ca = lookup[current], var na = lookup[next] else { return }
        let difference = Set(ca).symmetricDifference(na)
        XCTAssertEqual(difference.count, 1, file: file, line: line)
        na.removeAll(where: difference.contains)
        XCTAssertUnorderedEqual(ca, na, file: file, line: line)
        current = next
    } while true
}

// Copyright (C) 2020 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
