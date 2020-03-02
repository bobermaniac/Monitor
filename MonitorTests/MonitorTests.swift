import XCTest
@testable import Monitor

class MonitorTests: XCTestCase {
    func testMonitorForwardsAllPayloadsToSubscriber() {
        let (monitor, feed) = Monitor.make(of: Int.self, Int.self)
        let subscriber = Subscriber(for: monitor)

        feed.push(ephemeral: 1)
        feed.push(ephemeral: 2)
        feed.push(ephemeral: 3)
        feed.push(terminal: 5)

        XCTAssertEqual(subscriber.ephemerals, [1, 2, 3])
        XCTAssertEqual(subscriber.terminals, [5])
    }

    func testThereIsNoEventsAfterTerminalReceivedBySubscrber() {
        let (monitor, feed) = Monitor.make(of: Int.self, Int.self)
        let subscriber = Subscriber(for: monitor)

        feed.push(ephemeral: 1)
        feed.push(ephemeral: 2)
        feed.push(ephemeral: 3)
        feed.push(terminal: 5)
        feed.push(ephemeral: 1)
        feed.push(terminal: 2)

        XCTAssertEqual(subscriber.ephemerals, [1, 2, 3])
        XCTAssertEqual(subscriber.terminals, [5])
    }

    func testAllSubscribersReceiveSameData() {
        let (monitor, feed) = Monitor.make(of: Int.self, Int.self)
        let s1 = Subscriber(for: monitor)
        let s2 = Subscriber(for: monitor)

        feed.push(ephemeral: 1)
        feed.push(ephemeral: 2)
        feed.push(ephemeral: 3)
        feed.push(terminal: 5)
        XCTAssertEqual(s1.ephemerals, s2.ephemerals)
        XCTAssertEqual(s1.terminals, s2.terminals)
    }

    func testSubscibersReceivesOnlyEventsAfterSubsciption() {
        let (monitor, feed) = Monitor.make(of: Int.self, Int.self)

        feed.push(ephemeral: 1)
        feed.push(ephemeral: 2)

        let subscriber = Subscriber(for: monitor)

        feed.push(ephemeral: 3)
        feed.push(terminal: 5)

        XCTAssertEqual(subscriber.ephemerals, [3])
        XCTAssertEqual(subscriber.terminals, [5])
    }

    func testSubscribersStopsReceivingEventsAfterCancelation() {
        let (monitor, feed) = Monitor.make(of: Int.self, Int.self)
        let subscriber = Subscriber(for: monitor)

        feed.push(ephemeral: 1)
        feed.push(ephemeral: 2)

        subscriber.stop()

        feed.push(ephemeral: 3)
        feed.push(terminal: 5)

        XCTAssertEqual(subscriber.ephemerals, [1, 2])
        XCTAssertEqual(subscriber.terminals, [])
    }

    func testCancelReceivedWhenMonitorDeallocated() {
        var subscriber: Subscriber<Int, Int>?
        var cancelationObserver: CancelationObserver?

        repeat {
            let (monitor, feed) = Monitor.make(of: Int.self, Int.self)
            let s = Subscriber(for: monitor)
            let c = CancelationObserver(for: feed)
            subscriber = s
            cancelationObserver = c
        } while false

        XCTAssertFalse(cancelationObserver?.canceled ?? true)
        subscriber?.stop()
        XCTAssertTrue(cancelationObserver?.canceled ?? false)
    }

    func testCancelReceivedWhenTerminalEmitted() {
        let (monitor, feed) = Monitor.make(of: Int.self, Int.self)
        let subscriber = Subscriber(for: monitor)
        let observer = CancelationObserver(for: feed)

        XCTAssertFalse(observer.canceled)

        feed.push(terminal: 0)

        XCTAssertTrue(observer.canceled)

        subscriber.stop()
    }

    func testTokenReceivesVanishedEventWhenTerminalEmitted() {
        let (monitor, feed) = Monitor.make(of: Int.self, Int.self)
        let subscriber = Subscriber(for: monitor)

        XCTAssertFalse(subscriber.vanishReceived)

        feed.push(terminal: 0)

        XCTAssertTrue(subscriber.vanishReceived)
    }

    func testTokenReceivesVanishedEventWhenCanceled() {
        let (monitor, _) = Monitor.make(of: Int.self, Int.self)
        let subscriber = Subscriber(for: monitor)

        XCTAssertFalse(subscriber.vanishReceived)

        subscriber.stop()

        XCTAssertTrue(subscriber.vanishReceived)
    }

    func testAllVanishableSubscribtionIsCalledAfterAllTerminal() {
        let (monitor, feed) = Monitor.make(of: Int.self, Int.self)
        var calls = [] as [String]

        let token = monitor.observe(ephemeral: { _ in }, terminal: { _ in calls.append("terminal 1") })
        let token2 = monitor.observe(ephemeral: { _ in }, terminal: { _ in calls.append("terminal 2") })
        token.vanished.execute(callback: { _ in calls.append("vanished 1") })
        token2.vanished.execute(callback: { _ in calls.append("vanished 2") })
        feed.push(terminal: 0)

        XCTAssertEqual(calls, ["terminal 1", "terminal 2", "vanished 1", "vanished 2"])
    }

    func testSubscriptionInTerminalBlockProducecInstantToken() {
        let (monitor, feed) = Monitor.make(of: Int.self, Int.self)
        var calls = [] as [String]

        let token = monitor.observe(ephemeral: { _ in }, terminal: { _ in
            calls.append("terminal")
            let token2 = monitor.observe(ephemeral: { _ in }, terminal: { _ in calls.append("inner terminal")})
            token2.vanished.execute(callback: { _ in calls.append("inner vanished") })
        })
        token.vanished.execute(callback: { _ in calls.append("vanished") })

        feed.push(terminal: 0)

        XCTAssertEqual(calls, ["terminal", "inner terminal", "inner vanished", "vanished"])
    }

    func testSubscriptionInVanishedBlockProducecInstantToken() {
        let (monitor, feed) = Monitor.make(of: Int.self, Int.self)
        var calls = [] as [String]

        let token = monitor.observe(ephemeral: { _ in }, terminal: { _ in calls.append("terminal") })
        token.vanished.execute(callback: { _ in
            calls.append("vanished")
            let token2 = monitor.observe(ephemeral: { _ in }, terminal: { _ in calls.append("inner terminal")})
            token2.vanished.execute(callback: { _ in calls.append("inner vanished") })
        })

        feed.push(terminal: 0)

        XCTAssertEqual(calls, ["terminal", "vanished", "inner terminal", "inner vanished"])
    }
}

class MonitorOwnershipTests: XCTestCase {
    func testFeedDoesNotOwnCorrespondingMonitor() {
        weak var monitor: Monitor<Int, Void>?
        var feed: Feed<Int, Void>
        repeat {
            let (m, f) = Monitor.make(of: Int.self, Void.self)
            monitor = m
            feed = f
        } while false
        
        XCTAssertNil(monitor)
        XCTAssertNotNil(feed)
    }
    
    func testMonitorDoesNotOwnItsSubscriptions() {
        let (monitor, _) = Monitor.make(of: Int.self, Void.self)
        weak var ephemeralObserver: DummyObserver<Int>?
        weak var terminalObserver: DummyObserver<Void>?
        repeat {
            let e = DummyObserver<Int>()
            let t = DummyObserver<Void>()
            _ = monitor.observe(ephemeral: e.observe(value:), terminal: t.observe(value:))
        } while false
        
        XCTAssertNil(ephemeralObserver)
        XCTAssertNil(terminalObserver)
    }
    
    func testMonitorCancelationControlsSubscriptionLifetime() {
        let (monitor, _) = Monitor.make(of: Int.self, Void.self)
        weak var ephemeralObserver: DummyObserver<Int>?
        weak var terminalObserver: DummyObserver<Void>?
        var observation: Cancelable?
        repeat {
            let e = DummyObserver<Int>()
            let t = DummyObserver<Void>()
            observation = monitor.observe(ephemeral: e.observe(value:), terminal: t.observe(value:))
            ephemeralObserver = e
            terminalObserver = t
        } while false
        
        XCTAssertNotNil(observation)
        XCTAssertNotNil(ephemeralObserver)
        XCTAssertNotNil(terminalObserver)
        observation = nil
        XCTAssertNil(ephemeralObserver)
        XCTAssertNil(terminalObserver)
    }
    
    func testMonitorCancelationRemovesOwnership() {
        let (monitor, _) = Monitor.make(of: Int.self, Void.self)
        weak var ephemeralObserver: DummyObserver<Int>?
        weak var terminalObserver: DummyObserver<Void>?
        var observation: Cancelable?
        repeat {
            let e = DummyObserver<Int>()
            let t = DummyObserver<Void>()
            observation = monitor.observe(ephemeral: e.observe(value:), terminal: t.observe(value:))
            ephemeralObserver = e
            terminalObserver = t
        } while false
        
        XCTAssertNotNil(observation)
        XCTAssertNotNil(ephemeralObserver)
        XCTAssertNotNil(terminalObserver)
        observation?.cancel()
        XCTAssertNil(ephemeralObserver)
        XCTAssertNil(terminalObserver)
    }
    
    func testMonitorOwnsItsLifetimeObservers() {
        var monitor: Monitor<Int, Void>?
        weak var observer: DummyVoidObserver?
        repeat {
            let (m, f) = Monitor.make(of: Int.self, Void.self)
            let o = DummyVoidObserver()
            f.addCancelationObserver(onCancel: o.observe)
            observer = o
            monitor = m
        } while false
        XCTAssertNotNil(monitor)
        XCTAssertNotNil(observer)
        monitor = nil
        XCTAssertNil(observer)
    }

    func testTokenOwnsVanishableSubscriptionsAndReleasesItOnCancel() {
        let (monitor, _) = Monitor.make(of: Int.self, Void.self)
        let observation = monitor.observe(ephemeral: { _ in }, terminal: { _ in })
        weak var vanishSubscription: DummyObserver<Vanishable>?
        repeat {
            let s = DummyObserver<Vanishable>()
            observation.vanished.execute(callback: s.observe(value:))
            vanishSubscription = s
        } while false

        XCTAssertNotNil(vanishSubscription)
        observation.cancel()
        XCTAssertNil(vanishSubscription)
    }

    func testTokenOwnsVanishableSubscriptionsAndReleasesItOnTerminal() {
        let (monitor, feed) = Monitor.make(of: Int.self, Void.self)
        let observation = monitor.observe(ephemeral: { _ in }, terminal: { _ in })
        weak var vanishSubscription: DummyObserver<Vanishable>?
        repeat {
            let s = DummyObserver<Vanishable>()
            observation.vanished.execute(callback: s.observe(value:))
            vanishSubscription = s
        } while false

        XCTAssertNotNil(vanishSubscription)
        feed.push(terminal: ())
        XCTAssertNil(vanishSubscription)
    }
}

final class MonitorDispatcingValidationTests: XCTestCase {
    func test_observing_validation_hasBarrier_onQueue() {
        let (monitor, feed) = Monitor.make(of: Int.self, Void.self)
        let probe = DispatcherInterceptor()
        feed.setTargetDispatcher(probe)

        _ = monitor.observe(ephemeral: pass, terminal: pass)
        XCTAssertEqual(probe.invocations, [DispatcherInterceptor.Invocation(current: true, flags: .barrier)])
    }

    func test_emitting_ephemeral_onQueue() {
        let (monitor, feed) = Monitor.make(of: Int.self, Void.self)
        let probe = DispatcherInterceptor()
        feed.setTargetDispatcher(probe)

        feed.push(ephemeral: 0)
        XCTAssertNotNil(monitor)
        XCTAssertEqual(probe.invocations, [DispatcherInterceptor.Invocation(current: true, flags: [])])
    }

    func test_emitting_terminal_hasBarrier_onQueue() {
        let (monitor, feed) = Monitor.make(of: Int.self, Void.self)
        let probe = DispatcherInterceptor()
        feed.setTargetDispatcher(probe)

        feed.push(terminal: ())
        XCTAssertNotNil(monitor)
        XCTAssertEqual(probe.invocations, [DispatcherInterceptor.Invocation(current: true, flags: .barrier)])
    }
}

private final class DummyObserver<T> {
    func observe(value: T) { }
}

private final class DummyVoidObserver {
    func observe() { }
}

private final class CancelationObserver {
    init<Ephemeral, Terminal>(for feed: Feed<Ephemeral, Terminal>) {
        feed.addCancelationObserver(onCancel: onCancel)
    }

    private func onCancel() {
        canceled = true
    }

    var canceled = false
}

private final class DispatcherInterceptor: Dispatching {
    func assertIsCurrent(flags: DispatchingFlags) {
        invocations.append(Invocation(current: true, flags: flags))
    }

    func assertNotIsCurrent() {
        invocations.append(Invocation(current: false, flags: []))
    }

    func sync<T>(flags: DispatchingFlags, execute: () throws -> T) rethrows -> T {
        XCTFail("There should not be dispatcing in monitor")
        return try execute()
    }

    func async(flags: DispatchingFlags, execute: @escaping Action) -> Cancelable {
        XCTFail("There should not be dispatcing in monitor")
        return Vanished()
    }

    struct Invocation: Equatable {
        let current: Bool
        let flags: DispatchingFlags
    }

    var invocations = [] as [Invocation]
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
