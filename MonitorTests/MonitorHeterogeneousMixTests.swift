import Foundation
import XCTest
import Monitor

final class MonitorHetorogeneousMixTests: XCTest {
    func testProcessorReceivesInputFromFirstSlot() {
        let input = (0..<10).map { _ in Monitor.make(of: Int.self, Int.self)}
        let mixerFactory = DummyFactory()
        withExtendedLifetime(mix(input[0].0, input[1].0, input[2].0, input[3].0, input[4].0, input[5].0, input[6].0, input[7].0, input[8].0, factory: mixerFactory)) {
            input[0].1.push(ephemeral: 0)
            input[0].1.push(terminal: 5)
    
            XCTAssertNotNil(mixerFactory.lastCreatedMixer)
            XCTAssertEqual(mixerFactory.lastCreatedMixer?.eaten, [
                EatenInfo(value: 0, index: 1, kind: .ephemeral),
                EatenInfo(value: 5, index: 1, kind: .terminal)
            ])
        }
    }
    
    func testProcessorReceivesInputFromSecoundSlot() {
        let input = (0..<10).map { _ in Monitor.make(of: Int.self, Int.self)}
        let mixerFactory = DummyFactory()
        withExtendedLifetime(mix(input[0].0, input[1].0, input[2].0, input[3].0, input[4].0, input[5].0, input[6].0, input[7].0, input[8].0, factory: mixerFactory)) {
            input[1].1.push(ephemeral: 0)
            input[1].1.push(terminal: 5)
            
            XCTAssertNotNil(mixerFactory.lastCreatedMixer)
            XCTAssertEqual(mixerFactory.lastCreatedMixer?.eaten, [
                EatenInfo(value: 0, index: 2, kind: .ephemeral),
                EatenInfo(value: 5, index: 2, kind: .terminal)
                ])
        }
    }
    
    func testProcessorReceivesInputFromThirdSlot() {
        let input = (0..<10).map { _ in Monitor.make(of: Int.self, Int.self)}
        let mixerFactory = DummyFactory()
        withExtendedLifetime(mix(input[0].0, input[1].0, input[2].0, input[3].0, input[4].0, input[5].0, input[6].0, input[7].0, input[8].0, factory: mixerFactory)) {
            input[2].1.push(ephemeral: 0)
            input[2].1.push(terminal: 5)
            
            XCTAssertNotNil(mixerFactory.lastCreatedMixer)
            XCTAssertEqual(mixerFactory.lastCreatedMixer?.eaten, [
                EatenInfo(value: 0, index: 3, kind: .ephemeral),
                EatenInfo(value: 5, index: 3, kind: .terminal)
                ])
        }
    }
    
    func testProcessorReceivesInputFromForthSlot() {
        let input = (0..<10).map { _ in Monitor.make(of: Int.self, Int.self)}
        let mixerFactory = DummyFactory()
        withExtendedLifetime(mix(input[0].0, input[1].0, input[2].0, input[3].0, input[4].0, input[5].0, input[6].0, input[7].0, input[8].0, factory: mixerFactory)) {
            input[3].1.push(ephemeral: 0)
            input[3].1.push(terminal: 5)
            
            XCTAssertNotNil(mixerFactory.lastCreatedMixer)
            XCTAssertEqual(mixerFactory.lastCreatedMixer?.eaten, [
                EatenInfo(value: 0, index: 4, kind: .ephemeral),
                EatenInfo(value: 5, index: 4, kind: .terminal)
                ])
        }
    }
    
    func testProcessorReceivesInputFromFifthSlot() {
        let input = (0..<10).map { _ in Monitor.make(of: Int.self, Int.self)}
        let mixerFactory = DummyFactory()
        withExtendedLifetime(mix(input[0].0, input[1].0, input[2].0, input[3].0, input[4].0, input[5].0, input[6].0, input[7].0, input[8].0, factory: mixerFactory)) {
            input[4].1.push(ephemeral: 0)
            input[4].1.push(terminal: 5)
            
            XCTAssertNotNil(mixerFactory.lastCreatedMixer)
            XCTAssertEqual(mixerFactory.lastCreatedMixer?.eaten, [
                EatenInfo(value: 0, index: 5, kind: .ephemeral),
                EatenInfo(value: 5, index: 5, kind: .terminal)
                ])
        }
    }
    
    func testProcessorReceivesInputFromSixthSlot() {
        let input = (0..<10).map { _ in Monitor.make(of: Int.self, Int.self)}
        let mixerFactory = DummyFactory()
        withExtendedLifetime(mix(input[0].0, input[1].0, input[2].0, input[3].0, input[4].0, input[5].0, input[6].0, input[7].0, input[8].0, factory: mixerFactory)) {
            input[5].1.push(ephemeral: 0)
            input[5].1.push(terminal: 5)
            
            XCTAssertNotNil(mixerFactory.lastCreatedMixer)
            XCTAssertEqual(mixerFactory.lastCreatedMixer?.eaten, [
                EatenInfo(value: 0, index: 6, kind: .ephemeral),
                EatenInfo(value: 5, index: 6, kind: .terminal)
                ])
        }
    }
    
    func testProcessorReceivesInputFromSeventhSlot() {
        let input = (0..<10).map { _ in Monitor.make(of: Int.self, Int.self)}
        let mixerFactory = DummyFactory()
        withExtendedLifetime(mix(input[0].0, input[1].0, input[2].0, input[3].0, input[4].0, input[5].0, input[6].0, input[7].0, input[8].0, factory: mixerFactory)) {
            input[6].1.push(ephemeral: 0)
            input[6].1.push(terminal: 5)
            
            XCTAssertNotNil(mixerFactory.lastCreatedMixer)
            XCTAssertEqual(mixerFactory.lastCreatedMixer?.eaten, [
                EatenInfo(value: 0, index: 7, kind: .ephemeral),
                EatenInfo(value: 5, index: 7, kind: .terminal)
                ])
        }
    }
    
    func testProcessorReceivesInputFromEightSlot() {
        let input = (0..<10).map { _ in Monitor.make(of: Int.self, Int.self)}
        let mixerFactory = DummyFactory()
        withExtendedLifetime(mix(input[0].0, input[1].0, input[2].0, input[3].0, input[4].0, input[5].0, input[6].0, input[7].0, input[8].0, factory: mixerFactory)) {
            input[7].1.push(ephemeral: 0)
            input[7].1.push(terminal: 5)
            
            XCTAssertNotNil(mixerFactory.lastCreatedMixer)
            XCTAssertEqual(mixerFactory.lastCreatedMixer?.eaten, [
                EatenInfo(value: 0, index: 8, kind: .ephemeral),
                EatenInfo(value: 5, index: 8, kind: .terminal)
                ])
        }
    }
    
    func testProcessorReceivesInputFromNinethSlot() {
        let input = (0..<10).map { _ in Monitor.make(of: Int.self, Int.self)}
        let mixerFactory = DummyFactory()
        withExtendedLifetime(mix(input[0].0, input[1].0, input[2].0, input[3].0, input[4].0, input[5].0, input[6].0, input[7].0, input[8].0, factory: mixerFactory)) {
            input[8].1.push(ephemeral: 0)
            input[8].1.push(terminal: 5)
            
            XCTAssertNotNil(mixerFactory.lastCreatedMixer)
            XCTAssertEqual(mixerFactory.lastCreatedMixer?.eaten, [
                EatenInfo(value: 0, index: 9, kind: .ephemeral),
                EatenInfo(value: 5, index: 9, kind: .terminal)
                ])
        }
    }
    
    func testProcessorsAllowsAccessToOutputFeed() {
        let input = (0..<10).map { _ in Monitor.make(of: Int.self, Int.self) }.map { $0.0 }
        let mixerFactory = DummyFactory()
        let observer = Subscriber(for: mix(input[0], input[1], input[2], input[3], input[4], input[5], input[6], input[7], input[8], factory: mixerFactory))
        
        XCTAssertNotNil(mixerFactory.lastReceivedFeed)
        
        mixerFactory.lastReceivedFeed?.push(ephemeral: 1)
        mixerFactory.lastReceivedFeed?.push(terminal: 2)
        
        XCTAssertEqual(observer.ephemerals, [1])
        XCTAssertEqual(observer.terminals, [2])
    }
}

final class MonitorHetorogeneousMixOwnershipTests: XCTestCase {
    func testProcessorReceivesCancelationOnDeallocation() {
        let sources = (0...9).map { _ in Monitor.make(of: Int.self, Int.self).0 }
        let mixerFactory = DummyFactory()
        let observer = Subscriber(for: mix(sources[0], sources[1], sources[2], sources[3], sources[4], sources[5], sources[6], sources[7], sources[8], factory: mixerFactory))
        
        XCTAssertNil(mixerFactory.lastCreatedMixer?.receivedCancelables)
        observer.stop()
        XCTAssertNotNil(mixerFactory.lastCreatedMixer?.receivedCancelables)
        XCTAssertEqual(mixerFactory.lastCreatedMixer?.receivedCancelables?.count, 9)
    }
    
    /*func testSubsciptionOwnsSourceMonitor() {
        weak var sourceMonitor: Monitor<Int, Int>?
        var observer: Subscriber<Int, Int>
        
        let mixerFactory = DummyFactory()
        
        repeat {
            let (monitor, _) = Monitor.make(of: Int.self, Int.self)
            observer = Subscriber(for: monitor.transform(factory: mixerFactory))
            
            sourceMonitor = monitor
        } while false
        
        XCTAssertNotNil(sourceMonitor)
        observer.stop()
        XCTAssertNotNil(sourceMonitor)
        mixerFactory.lastCreatedProcessor?.sourceSubscription?.cancel()
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
    }*/
}

private final class DummyFactory: MonitorHetorogeneusMixingFactory {
    typealias Mixer = DummyMixer
    
    func make(feed: Feed<Int, Int>) -> DummyMixer {
        lastReceivedFeed = feed
        lastCreatedMixer = DummyMixer()
        return lastCreatedMixer!
    }
    
    var lastCreatedMixer: DummyMixer?
    var lastReceivedFeed: Feed<Int, Int>?
}

private final class DummyMixer: MonitorHetorogeneusMixing {
    func eat1(ephemeral: Int) {
        eat(value: ephemeral, index: 1, kind: .ephemeral)
    }
    
    func eat1(terminal: Int) {
        eat(value: terminal, index: 1, kind: .terminal)
    }
    
    func eat2(ephemeral: Int) {
        eat(value: ephemeral, index: 2, kind: .ephemeral)
    }
    
    func eat2(terminal: Int) {
        eat(value: terminal, index: 2, kind: .terminal)
    }
    
    func eat3(ephemeral: Int) {
        eat(value: ephemeral, index: 3, kind: .ephemeral)
    }
    
    func eat3(terminal: Int) {
        eat(value: terminal, index: 3, kind: .terminal)
    }
    
    func eat4(ephemeral: Int) {
        eat(value: ephemeral, index: 4, kind: .ephemeral)
    }
    
    func eat4(terminal: Int) {
        eat(value: terminal, index: 4, kind: .terminal)
    }
    
    func eat5(ephemeral: Int) {
        eat(value: ephemeral, index: 5, kind: .ephemeral)
    }
    
    func eat5(terminal: Int) {
        eat(value: terminal, index: 5, kind: .terminal)
    }
    
    func eat6(ephemeral: Int) {
        eat(value: ephemeral, index: 6, kind: .ephemeral)
    }
    
    func eat6(terminal: Int) {
        eat(value: terminal, index: 6, kind: .terminal)
    }
    
    func eat7(ephemeral: Int) {
        eat(value: ephemeral, index: 7, kind: .ephemeral)
    }
    
    func eat7(terminal: Int) {
        eat(value: terminal, index: 7, kind: .terminal)
    }
    
    func eat8(ephemeral: Int) {
        eat(value: ephemeral, index: 8, kind: .ephemeral)
    }
    
    func eat8(terminal: Int) {
        eat(value: terminal, index: 8, kind: .terminal)
    }
    
    func eat9(ephemeral: Int) {
        eat(value: ephemeral, index: 9, kind: .ephemeral)
    }
    
    func eat9(terminal: Int) {
        eat(value: terminal, index: 9, kind: .terminal)
    }
    
    func cancel(subscriptions: [Cancelable]) {
        receivedCancelables = subscriptions
    }
    
    private func eat(value: Int, index: Int, kind: EatenInfo.Kind) {
        eaten.append(EatenInfo(value: value, index: index, kind: kind))
    }
    
    typealias Types = SignalTypeSet<
        SignalType<Int, Int>,
        SignalType<Int, Int>,
        SignalType<Int, Int>,
        SignalType<Int, Int>,
        SignalType<Int, Int>,
        SignalType<Int, Int>,
        SignalType<Int, Int>,
        SignalType<Int, Int>,
        SignalType<Int, Int>,
        SignalType<Int, Int>
    >
    
    var eaten = [] as [EatenInfo]
    var receivedCancelables: [Cancelable]?
}

private struct EatenInfo: Equatable {
    enum Kind {
        case ephemeral
        case terminal
    }
    
    var value: Int
    var index: Int
    var kind: Kind
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
