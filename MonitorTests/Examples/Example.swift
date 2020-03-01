import Foundation
import Monitor 
import XCTest

final class Example: XCTestCase {
    func test() {
        let managerDispatcher = ManualDispatcher(name: "manager")
        let workerDispatcher = ManualDispatcher(name: "worker")

        let worker = Worker(dispatcher: workerDispatcher)
        let manager = Manager(dispatcher: managerDispatcher, worker: worker)

        managerDispatcher.sync(flags: [.barrier]) {
            manager.startWorkDay()
        }

        [managerDispatcher, workerDispatcher].XCTAwait(manager.workReady == 2)
        
        XCTAssertGreaterThan(manager.progress.count, 8)
        
        [managerDispatcher, workerDispatcher].XCTFinite()
    }

    func testHighConcurrency() {
        let managerDispatcher = ManualDispatcher(name: "manager")
        let workerDispatcher = ManualDispatcher(name: "worker")

        let worker = Worker(dispatcher: workerDispatcher)
        let manager = Manager(dispatcher: managerDispatcher, worker: worker)

        managerDispatcher.sync(flags: [.barrier]) {
            manager.startWorkDay()
        }

        managerDispatcher.simulatingHighConcurrency {
            [managerDispatcher, workerDispatcher].XCTAwait(manager.workReady == 2)
        }
        
        XCTAssertLessThan(manager.progress.count, 8)
        
        [managerDispatcher, workerDispatcher].XCTFinite()
    }
}

struct Work { }

final class Worker {
    init(dispatcher: Dispatching) {
        self.dispatcher = dispatcher
    }

    func startWork(initialProgress: Double, resultDispatcher: Dispatching) -> Monitor<Double, Work> {
        let threadSafety = ThreadSafety.interlocked()
        let max1op = ConcurrencyLimiter(maxOperationsCount: 1,
                                        threadSafetyStrategy: threadSafety)
        let overrideLast = MergeWhenLittered(reducer: { (_, new) -> Double in new },
                                             threadSafetyStrategy: threadSafety)
        return BackgroundTask(task: internalStartWork,
                              param: initialProgress,
                              executeOn: dispatcher)
            .run(resolveDispatcher: resultDispatcher,
                 mode: .default,
                 safetyValve: max1op,
                 litteredStrategy: overrideLast)
    }

    private func internalStartWork(initialProgress: Double) -> Monitor<Double, Work> {
        let (result, feed) = Monitor.make(of: Double.self, Work.self)
        let fId = counter
        counter += 1
        feed.addCancelationObserver { [weak self] in
            self?.activeWork.removeValue(forKey: fId)
        }
        activeWork[fId] = (feed, initialProgress)
        if activeWork.count == 1 {
            dispatcher.async(flags: [.barrier], execute: runWork)
        }
        return result
    }

    private func runWork() {
        activeWork = activeWork.compactMapValues { (feed, progress) in
            let newProgress = progress + 0.1
            if newProgress >= 1 {
                feed.push(terminal: Work())
                return nil
            }
            feed.push(ephemeral: newProgress)
            return (feed, newProgress)
        }
        if activeWork.count > 0 {
            dispatcher.async(flags: [.barrier], execute: runWork)
        }
    }

    private var activeWork = [:] as [UInt32: (feed: Feed<Double, Work>, progress: Double)]
    private let dispatcher: Dispatching
    private var counter = 0 as UInt32
}

final class Manager {
    init(dispatcher: Dispatching, worker: Worker) {
        self.dispatcher = dispatcher
        self.worker = worker
    }

    func startWorkDay() {
        worker.startWork(initialProgress: 0, resultDispatcher: dispatcher)
            .map(ephemeral: { Int($0 * 100) }, terminal: { _ in })
            .observe(ephemeral: { self.progress.append($0) }, terminal: { self.workReady += 1})
            .associate(with: \.leftWork, of: self)
        worker.startWork(initialProgress: 0.5, resultDispatcher: dispatcher)
            .map(ephemeral: { Int($0 * -100) }, terminal: { _ in })
            .observe(ephemeral: { self.progress.append($0) }, terminal: { self.workReady += 2})
            .associate(with: \.rightWork, of: self)
    }

    private(set) var progress =  [] as [Int]
    private(set) var workReady = 0 {
        didSet {
            leftWork?.cancel()
            rightWork?.cancel()
        }
    }

    private var leftWork: Vanishable?
    private var rightWork: Vanishable?

    private let dispatcher: Dispatching
    private let worker: Worker
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
