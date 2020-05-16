import Foundation
import XCTest
import Monitor

final class StrictOrderedSignalTest: XCTestCase {
    func test_ephemeralPushInsideObservation_DoesNotAffectEphemeralPropagationOrder() {
        let (monitor, signal) = StrictOrderedSignal.create(of: Int.self, Int.self)
        var events1 = [] as [Int]
        var events2 = [] as [Int]

        let token1 = monitor.observe(ephemeral: { value in
            events1.append(value)
            if value % 2 == 0 {
                signal.emit(ephemeral: value + 1)
            }
        }, terminal: pass)

        let token2 = monitor.observe(ephemeral: { value in
            events2.append(value)
        }, terminal: pass)

        (0...3).map { $0 * 2 }.forEach(signal.emit(ephemeral:))

        let expected = [0, 1, 2, 3, 4, 5, 6, 7]
        XCTAssertEqual(events1, expected)
        XCTAssertEqual(events2, expected)

        [token1, token2].forEach { $0.cancel() }
    }

    func test_terminalPushInsideObservation_DoesNotAffectPropagationOrder() {
        let (monitor, signal) = StrictOrderedSignal.create(of: Int.self, Int.self)
        var events1 = [] as [Int]
        var events2 = [] as [Int]

        let token1 = monitor.observe(ephemeral: { value in
            events1.append(value)
            signal.terminate(with: 25)
        }, terminal: { value in
            events1.append(value)
        })

        let token2 = monitor.observe(ephemeral: { value in
            events2.append(value)
        }, terminal: { value in
            events2.append(value)
        })

        signal.emit(ephemeral: 0)

        let expected = [0, 25]
        XCTAssertEqual(events1, expected)
        XCTAssertEqual(events2, expected)

        [token1, token2].forEach { $0.cancel() }
    }

    func test_subscribtionInsideObservation_doesNotReceiveCurrentEvent() {
        let (monitor, signal) = StrictOrderedSignal.create(of: Int.self, Int.self)
        var events1 = [] as [Int]
        var events2 = [] as [Int]
        var events3 = [] as [Int]

        var token3: Vanishable?

        let token1 = monitor.observe(ephemeral: { value in
            events1.append(value)
            token3 = monitor.observe(ephemeral: { value in
                events3.append(value)
            }, terminal: pass)
        }, terminal: pass)

        let token2 = monitor.observe(ephemeral: { value in
            events2.append(value)
        }, terminal: pass)

        signal.emit(ephemeral: 1)

        XCTAssertEqual(events1, [1])
        XCTAssertEqual(events2, [1])
        XCTAssertEqual(events3, [])

        [token1, token2, token3].forEach { $0?.cancel() }
    }

    func test_ephemeralPushedInObservation_followedByTerminal_areDiscarded() {
        let (monitor, signal) = StrictOrderedSignal.create(of: Int.self, Int.self)
        var events1 = [] as [Int]
        var events2 = [] as [Int]
        var events3 = [] as [Int]

        let token1 = monitor.observe(ephemeral: { value in
            events1.append(value)
            signal.emit(ephemeral: 2)
        }, terminal: { value in
            events1.append(value)
        })

        let token2 = monitor.observe(ephemeral: { value in
            events2.append(value)
            signal.emit(ephemeral: 3)
        }, terminal: { value in
            events2.append(value)
        })

        let token3 = monitor.observe(ephemeral: { value in
            events3.append(value)
            signal.terminate(with: 25)
        }, terminal: { value in
            events3.append(value)
        })

        signal.emit(ephemeral: 1)

        let expected = [1, 25]
        XCTAssertEqual(events1, expected)
        XCTAssertEqual(events2, expected)
        XCTAssertEqual(events3, expected)

        [token1, token2, token3].forEach { $0?.cancel() }
    }

    func test_terminalSubscriptionInTerminalObservation_receivesTerminal() {
        let (monitor, signal) = StrictOrderedSignal.create(of: Int.self, Int.self)
        var events1 = [] as [Int]
        var events2 = [] as [Int]
        var events3 = [] as [Int]

        var token3: Vanishable?

        let token1 = monitor.observe(ephemeral: pass, terminal: { value in
            events1.append(value)
            token3 = monitor.observe(ephemeral: pass, terminal: { value in
                events3.append(value)
            })
        })

        let token2 = monitor.observe(ephemeral: pass, terminal: { value in
            events2.append(value)
        })

        signal.terminate(with: 0)

        let expected = [0]
        XCTAssertEqual(events1, expected)
        XCTAssertEqual(events2, expected)
        XCTAssertEqual(events3, expected)

        [token1, token2, token3].forEach { $0?.cancel() }
    }

    func test_disposeSubscriptionInTerminalObservation_receivesEvent() {
        let (monitor, signal) = StrictOrderedSignal.create(of: Int.self, Int.self)
        var events1 = [] as [Int]
        var events2 = [] as [Int]
        var events3 = [] as [Int]

        let token1 = monitor.observe(ephemeral: pass, terminal: { value in
            events1.append(value)
            signal.cancelled {
                events3.append(25)
            }
        })

        let token2 = monitor.observe(ephemeral: pass, terminal: { value in
            events2.append(value)
        })

        signal.terminate(with: 0)

        let expected = [0]
        XCTAssertEqual(events1, expected)
        XCTAssertEqual(events2, expected)
        XCTAssertEqual(events3, [25])

        [token1, token2].forEach { $0?.cancel() }
    }
}

private func pass<T>(_: T) { }
