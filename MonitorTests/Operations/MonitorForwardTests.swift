import Foundation
import Monitor
import XCTest

final class MonitorForwardTests: XCTestCase {
    func test_whenNotLittered_transfersDirectly() {
        let (source, sourceFeed) = Monitor.make(of: Int.self, Void.self)
        let (target, targetFeed) = Monitor.make(of: Int.self, Void.self)
        let subscriber = Subscriber(for: target)

        let sourceDispatcher = ManualDispatcher(name: "source")
        let targetDispatcher = ManualDispatcher(name: "target")

        let safetyValve = ManualSafetyValve()
        let litteredStrategy = ManualLitteredStrategy()
        sourceDispatcher.sync(flags: [.barrier]) {
            source.forward(from: sourceDispatcher,
                           to: targetDispatcher,
                           into: targetFeed,
                           mode: .default,
                           safetyValve: safetyValve,
                           litteredStrategy: litteredStrategy)
        }

        sourceDispatcher.sync(flags: []) {
            sourceFeed.push(ephemeral: 0)
            XCTAssertEqual(safetyValve.numberOfInvocationsScheduled, 1)
            XCTAssertEqual(safetyValve.numberOfInvocationsComplete, 0)
            XCTAssertEqual(subscriber.ephemerals, [])
        }

        sourceDispatcher.sync(flags: []) {
            sourceFeed.push(ephemeral: 1)
            XCTAssertEqual(safetyValve.numberOfInvocationsScheduled, 2)
            XCTAssertEqual(safetyValve.numberOfInvocationsComplete, 0)
            XCTAssertEqual(subscriber.ephemerals, [])
        }

        // This dispatch prepares cancelation signal backward emitting
        targetDispatcher.dispatchNext()
        targetDispatcher.dispatchNext()
        XCTAssertEqual(safetyValve.numberOfInvocationsScheduled, 2)
        XCTAssertEqual(safetyValve.numberOfInvocationsComplete, 1)
        XCTAssertEqual(subscriber.ephemerals, [0])

        targetDispatcher.dispatchNext()
        XCTAssertEqual(safetyValve.numberOfInvocationsScheduled, 2)
        XCTAssertEqual(safetyValve.numberOfInvocationsComplete, 2)
        XCTAssertEqual(subscriber.ephemerals, [0, 1])

        sourceDispatcher.sync(flags: []) {
            sourceFeed.push(terminal: ())
            // Terminals is not forwarding through safety valve
            XCTAssertEqual(safetyValve.numberOfInvocationsScheduled, 2)
            XCTAssertEqual(safetyValve.numberOfInvocationsComplete, 2)
            XCTAssertEqual(subscriber.terminals.count, 0)
        }

        targetDispatcher.dispatchNext()
        XCTAssertEqual(subscriber.terminals.count, 1)
    }

    func test_whenLittered_transfersThroughStrategy() {
        let (source, sourceFeed) = Monitor.make(of: Int.self, Void.self)
        let (target, targetFeed) = Monitor.make(of: Int.self, Void.self)
        let subscriber = Subscriber(for: target)

        let sourceDispatcher = ManualDispatcher(name: "source")
        let targetDispatcher = ManualDispatcher(name: "target")

        let safetyValve = ManualSafetyValve()
        let litteredStrategy = ManualLitteredStrategy()
        sourceDispatcher.sync(flags: [.barrier]) {
            source.forward(from: sourceDispatcher,
                           to: targetDispatcher,
                           into: targetFeed,
                           mode: .default,
                           safetyValve: safetyValve,
                           litteredStrategy: litteredStrategy)
        }

        sourceDispatcher.sync(flags: []) {
            sourceFeed.push(ephemeral: 0)
            XCTAssertEqual(safetyValve.numberOfInvocationsScheduled, 1)
            XCTAssertEqual(safetyValve.numberOfInvocationsComplete, 0)
            XCTAssertEqual(subscriber.ephemerals, [])
        }

        // Now dispatcher becomes littered
        safetyValve.isLittered = true

        sourceDispatcher.sync(flags: []) {
            sourceFeed.push(ephemeral: 1)
            XCTAssertEqual(safetyValve.numberOfInvocationsScheduled, 1)
            XCTAssertEqual(safetyValve.numberOfInvocationsComplete, 0)
            XCTAssertEqual(subscriber.ephemerals, [])
            XCTAssertEqual(litteredStrategy.buffer, [1])
        }

        sourceDispatcher.sync(flags: []) {
            sourceFeed.push(ephemeral: 2)
            XCTAssertEqual(safetyValve.numberOfInvocationsScheduled, 1)
            XCTAssertEqual(safetyValve.numberOfInvocationsComplete, 0)
            XCTAssertEqual(subscriber.ephemerals, [])
            XCTAssertEqual(litteredStrategy.buffer, [1, 2])
        }

        // This dispatch prepares cancelation signal backward emitting
        targetDispatcher.dispatchNext()
        targetDispatcher.dispatchNext()
        XCTAssertEqual(safetyValve.numberOfInvocationsScheduled, 1)
        XCTAssertEqual(safetyValve.numberOfInvocationsComplete, 1)
        XCTAssertEqual(subscriber.ephemerals, [0, 1, 2])

        safetyValve.isLittered = false

        sourceDispatcher.sync(flags: []) {
            sourceFeed.push(terminal: ())
            // Terminals is not forwarding through safety valve
            XCTAssertEqual(safetyValve.numberOfInvocationsScheduled, 1)
            XCTAssertEqual(safetyValve.numberOfInvocationsComplete, 1)
            XCTAssertEqual(subscriber.terminals.count, 0)
        }

        targetDispatcher.dispatchNext()
        XCTAssertEqual(subscriber.terminals.count, 1)
    }
}

private final class ManualSafetyValve: SafetyValve {
    func invocationSheduled() {
        numberOfInvocationsScheduled += 1
    }

    func invocationComplete() {
        numberOfInvocationsComplete += 1
    }

    var isLittered = false

    var numberOfInvocationsScheduled = 0
    var numberOfInvocationsComplete = 0
}

private final class ManualLitteredStrategy: LitteredStrategy {
    func put(element: Int) {
        buffer.append(element)
    }

    func push() -> Int? {
        guard buffer.count > 0 else {
            return nil
        }
        return buffer.removeFirst()
    }

    var buffer = [] as [Int]

    typealias Element = Int
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
