import XCTest
import Monitor

final class MonitorTransformationTests: XCTestCase {
    func testProcessorReceivesAllInput() {
        let (source, feed) = Monitor.make(of: Int.self, Int.self)
        let processorFactory = DummyFactory()
        withExtendedLifetime(source.transform(factory: processorFactory)) {
            feed.push(ephemeral: 1)
            feed.push(terminal: 2)

            XCTAssertNotNil(processorFactory.lastCreatedProcessor)
            XCTAssertEqual(processorFactory.lastCreatedProcessor?.receivedEphemerals, [1])
            XCTAssertEqual(processorFactory.lastCreatedProcessor?.receivedTerminals, [2])
        }
    }

    func testProcessorsAllowsAccessToOutputFeed() {
        let (source, _) = Monitor.make(of: Int.self, Int.self)
        let processorFactory = DummyFactory()
        let observer = Subscriber(for: source.transform(factory: processorFactory))

        XCTAssertNotNil(processorFactory.lastReceivedFeed)

        processorFactory.lastReceivedFeed?.push(ephemeral: 1)
        processorFactory.lastReceivedFeed?.push(terminal: 2)

        XCTAssertEqual(observer.ephemerals, [1])
        XCTAssertEqual(observer.terminals, [2])
    }
}

final class MonitorTransformationOwnershipTests: XCTestCase {
    func testProcessorReceivesCancelationOnDeallocation() {
        let (source, _) = Monitor.make(of: Int.self, Int.self)
        let processorFactory = DummyFactory()
        let observer = Subscriber(for: source.transform(factory: processorFactory))

        XCTAssertNil(processorFactory.lastCreatedProcessor?.sourceSubscription)
        observer.stop()
        XCTAssertNotNil(processorFactory.lastCreatedProcessor?.sourceSubscription)
    }

    func testSubsciptionOwnsSourceMonitor() {
        weak var sourceMonitor: Monitor<Int, Int>?
        var observer: Subscriber<Int, Int>
        
        let processorFactory = DummyFactory()

        repeat {
            let (monitor, _) = Monitor.make(of: Int.self, Int.self)
            observer = Subscriber(for: monitor.transform(factory: processorFactory))

            sourceMonitor = monitor
        } while false

        XCTAssertNotNil(sourceMonitor)
        observer.stop()
        XCTAssertNotNil(sourceMonitor)
        processorFactory.lastCreatedProcessor?.sourceSubscription?.cancel()
        XCTAssertNil(sourceMonitor)
    }

    func testSubscriptionOwnsProcessor() {
        let (source, _) = Monitor.make(of: Int.self, Int.self)
        weak var processor: DummyProcessor?
        var observer: Subscriber<Int, Int>

        repeat {
            let factory = DummyFactory()
            observer = Subscriber(for: source.transform(factory: factory))
            processor = factory.lastCreatedProcessor
        } while false

        XCTAssertNotNil(processor)
        observer.stop()
        XCTAssertNotNil(processor)
        processor?.sourceSubscription?.cancel()
        XCTAssertNil(processor)
    }

    func testSourceMonitorDoesNotOwnTarget() {
        let (source, _) = Monitor.make(of: Int.self, Int.self)
        weak var result: Monitor<Int, Int>?

        repeat {
            let factory = DummyFactory()
            let target = source.transform(factory: factory)
            result = target

            XCTAssertNotNil(result)
        } while false

        XCTAssertNil(result)
    }

    func testPushTerminalRemovesSubscription() {
        weak var source: Monitor<Int, Int>?
        var target: Monitor<Int, Int>?
        let factory = DummyFactory()
        repeat {
            let (s, _) = Monitor.make(of: Int.self, Int.self)
            target = s.transform(factory: factory)
            source = s
        } while false

        XCTAssertNotNil(target)
        XCTAssertNotNil(source)
        factory.lastReceivedFeed?.push(terminal: 0)
        XCTAssertNil(source)
    }
}

private final class DummyFactory: MonitorTransformingFactory {
    func make(feed: Feed<Int, Int>) -> DummyProcessor {
        XCTAssertTrue(calledOnce)
        calledOnce = false

        lastReceivedFeed = feed
        lastCreatedProcessor = DummyProcessor()
        return lastCreatedProcessor!
    }

    typealias Processor = DummyProcessor

    var lastReceivedFeed: Feed<Int, Int>?
    var lastCreatedProcessor: DummyProcessor?

    private var calledOnce = true
}

private final class DummyProcessor: MonitorTransforming {
    func eat(ephemeral: Int) {
        receivedEphemerals.append(ephemeral)
    }

    func eat(terminal: Int) {
        receivedTerminals.append(terminal)
    }

    func cancel(sourceSubscription: Cancelable) {
        self.sourceSubscription = sourceSubscription
    }
    
    private(set) var sourceSubscription: Cancelable?

    typealias InputEphemeral = Int
    typealias InputTerminal = Int
    typealias OutputEphemeral = Int
    typealias OutputTerminal = Int

    var receivedEphemerals = [] as [Int]
    var receivedTerminals = [] as [Int]
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
