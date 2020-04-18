import Foundation
import Monitor
import XCTest

final class ManualDispatcher: Dispatching, DelayedDispatching, Equatable {
    let clock: ManualClock
    
    init(name: String = "anonymous",
         simultaneousOperationCount: UInt8 = 1,
         clock: ManualClock = ManualClock()) {
        self.name = name
        self.clock = clock
        self.simultaneousOperationCount = simultaneousOperationCount
    }
    
    func assertIsCurrent(flags: DispatchingFlags) {
        guard let top = ManualDispatcher.dispatchersStack.last else {
            XCTFail("No dispatcher is currently executed")
            return
        }
        XCTAssertEqual(top.dispatcher, self)

        if top.flags.intersection(flags) != flags {
            XCTFail("Invalid flags, expected \(flags), actual \(top.flags)")
        }
    }
    
    func assertNotIsCurrent() {
        guard let top = ManualDispatcher.dispatchersStack.last else {
            return
        }
        XCTAssertNotEqual(top.dispatcher, self)
    }

    @discardableResult
    func async(flags: DispatchingFlags, execute block: @escaping Action) -> Cancelable {
        let task = ScheduledTask(block: block, flags: flags, timeout: 0, clock: clock)
        ManualDispatcher.invoke(joinPoint: .beforeScheduleInvocation, dispatcher: self)
        pendingTasks.append(task)
        ManualDispatcher.invoke(joinPoint: .afterScheduleInvocation, dispatcher: self)
        return task
    }
    
    func sync<T>(flags: DispatchingFlags, execute block: () throws -> T) rethrows -> T {
        if ManualDispatcher.dispatchersStack.last?.dispatcher == self {
            XCTFail("Deadlock detected: trying to schedule sync operation on current dispatcher")
        }
        var virtualExecutionComplete = false
        let task = ScheduledTask(block: { virtualExecutionComplete = true },
                                 flags: flags,
                                 timeout: 0,
                                 clock: clock)
        ManualDispatcher.invoke(joinPoint: .beforeScheduleInvocation, dispatcher: self)
        pendingTasks.append(task)
        ManualDispatcher.invoke(joinPoint: .afterScheduleInvocation, dispatcher: self)
        while !virtualExecutionComplete {
            dispatchNext(timeInterval: 0)
        }
        ManualDispatcher.dispatchersStack.append((flags, self))
        defer { ManualDispatcher.dispatchersStack.removeLast() }
        return try ManualDispatcher.run(block, dispatcher: self)

    }

    @discardableResult
    func async(after timeout: TimeInterval,
               flags: DispatchingFlags,
               execute block: @escaping Action) -> Cancelable {
        let task = ScheduledTask(block: block, flags: flags, timeout: timeout, clock: clock)
        ManualDispatcher.invoke(joinPoint: .beforeScheduleInvocation, dispatcher: self)
        pendingTasks.append(task)
        ManualDispatcher.invoke(joinPoint: .afterScheduleInvocation, dispatcher: self)
        return task
    }

    @discardableResult
    func dispatchNext(timeInterval: TimeInterval = 0) -> Bool {
        return dispatchNext(timeInterval: timeInterval, returnsTrueOnPendingInvocation: true)
    }
    
    private func dispatchNext(timeInterval: TimeInterval, returnsTrueOnPendingInvocation: Bool) -> Bool {
        clock.increment(by: timeInterval)

        if pendingTasks.isEmpty { return false }
        pendingTasks.removeAll { $0.state.isCanceled }

        if pendingTasks.isEmpty { return false }

        let tasksReadyToBeExecuted = pendingTasks.filter { !$0.state.isPending }
        if tasksReadyToBeExecuted.isEmpty { return returnsTrueOnPendingInvocation }

        if simultaneousOperationCount == 1 {
            executeSingle(task: tasksReadyToBeExecuted.first!)
        } else {
            executeMultiple(tasks: tasksReadyToBeExecuted)
        }
        return true
    }
    
    @discardableResult
    func dispatchUntil(timeInterval: TimeInterval) -> Bool {
        clock.increment(by: timeInterval)
        var dispatched = false
        while dispatchNext(timeInterval: 0, returnsTrueOnPendingInvocation: false) { dispatched = true }
        return dispatched
    }

    private func executeSingle(task: ScheduledTask) {
        guard case .execute(let block, let flags) = task.state else {
            fatalError("Inconsistent state")
        }
        executeInContext(block: { block(); task.cancel() }, flags: flags)
        pendingTasks.remove(at: pendingTasks.firstIndex(of: task)!)
    }

    private func executeMultiple(tasks: [ScheduledTask]) {
        var executingTasks = [] as [ScheduledTask]
        for candidate in tasks {
            guard case .execute(_, let flags) = candidate.state else {
                fatalError("Inconsistent state")
            }
            if flags.contains(.barrier) {
                if executingTasks.isEmpty {
                    executeSingle(task: candidate)
                    return
                }
                break
            }
            executingTasks.append(candidate)
            if executingTasks.count == simultaneousOperationCount {
                break
            }
        }
        if executingTasks.count == 1 {
            executeSingle(task: executingTasks.first!)
        } else {
            let blocks = executingTasks.map { task -> Action in
                guard case .execute(let block, _) = task.state else {
                    fatalError("Inconsistent state")
                }
                return {
                    block()
                    task.cancel()
                }
            }
            executeManyInContext(blocks: blocks, flags: [])
            pendingTasks.removeAll(where: executingTasks.contains)
        }
    }

    private func executeInContext(block: Action, flags: DispatchingFlags) {
        ManualDispatcher.dispatchersStack.append((flags, self))
        ManualDispatcher.run(block, dispatcher: self)
        ManualDispatcher.dispatchersStack.removeLast()
    }

    private func executeManyInContext(blocks: [Action], flags: DispatchingFlags) {
        ManualDispatcher.dispatchersStack.append((flags, self))
        for _ in 0..<blocks.count {
            ManualDispatcher.invoke(joinPoint: .beforeDispatchedEntityInvocation, dispatcher: self)
        }
        ManualDispatcher.runSimultaneously(blocks)
        for _ in 0..<blocks.count {
            ManualDispatcher.invoke(joinPoint: .afterDispatchedEntitiyInvocation, dispatcher: self)
        }
        ManualDispatcher.dispatchersStack.removeLast()
    }
    
    private static func run<T>(_ block: () throws -> T, dispatcher: ManualDispatcher) rethrows -> T {
        ManualDispatcher.invoke(joinPoint: .beforeDispatchedEntityInvocation, dispatcher: dispatcher)
        do {
            let result = try block()
            ManualDispatcher.invoke(joinPoint: .afterDispatchedEntitiyInvocation, dispatcher: dispatcher)
            return result
        } catch let error {
            ManualDispatcher.invoke(joinPoint: .afterDispatchedEntitiyInvocation, dispatcher: dispatcher)
            throw error
        }
    }
    
    private static func runSimultaneously(_ blocks: [Action]) {
        let group = DispatchGroup()
        let tasks = blocks.map { block -> Action in
            group.enter()
            return {
                block()
                group.leave()
            }
        }
        let queue = DispatchQueue.global(qos: .default)
        for task in tasks {
            queue.async(execute: task)
        }
        return group.wait()
    }
    
    static func == (lhs: ManualDispatcher, rhs: ManualDispatcher) -> Bool {
        return lhs === rhs
    }

    private var pendingTasks = [] as [(ScheduledTask)]
    let name: String
    let simultaneousOperationCount: UInt8
    
    private static var dispatchersStack = [] as [(flags: DispatchingFlags, dispatcher: ManualDispatcher)]
}

extension ManualDispatcher {
    enum JoinPoint {
        case beforeDispatchedEntityInvocation
        case afterDispatchedEntitiyInvocation
        case beforeScheduleInvocation
        case afterScheduleInvocation
    }
    
    static func introduce(in joinPoint: JoinPoint, invocation: @escaping Consumer<ManualDispatcher>) -> Cancelable {
        let tag = (0..<Int.max).first { !introductions.keys.contains($0) }!
        introductions[tag] = (joinPoint, invocation)
        return Token(tag: tag)
    }
    
    private static func detachIntroduction(at tag: Int) {
        introductions.removeValue(forKey: tag)
    }
    
    private static func invoke(joinPoint: JoinPoint, dispatcher: ManualDispatcher) {
        for introduction in introductions.values {
            if introduction.0 == joinPoint {
                introduction.1(dispatcher)
            }
        }
    }
    
    private static var introductions = [:] as [Int: (JoinPoint, Consumer<ManualDispatcher>)]
    
    private final class Token: Cancelable {
        init(tag: Int) {
            self.tag = tag
        }
        
        func cancel() {
            guard let tag = tag else { return }
            ManualDispatcher.detachIntroduction(at: tag)
            self.tag = nil
        }
        
        private var tag: Int?
    }
}

private final class ScheduledTask: Cancelable, Equatable {
    static func ==(lhs: ScheduledTask, rhs: ScheduledTask) -> Bool {
        return lhs === rhs
    }

    init(block: @escaping Action, flags: DispatchingFlags, timeout: TimeInterval, clock: ManualClock) {
        self.block = block
        self.flags = flags
        self.scheduledInvocationTime = clock.currentTime + timeout
        self.clock = clock
    }

    enum State {
        case pending
        case execute(block: Action, flags: DispatchingFlags)
        case canceled

        var isCanceled: Bool {
            if case .canceled = self { return true }
            return false
        }

        var isPending: Bool {
            if case .pending = self { return true }
            return false
        }
    }

    func cancel() {
        block = nil
    }

    var state: State {
        guard let block = self.block else {
            return .canceled
        }
        if scheduledInvocationTime > clock.currentTime {
            return .pending
        }
        return .execute(block: block, flags: flags)
    }

    private let flags: DispatchingFlags
    private let clock: ManualClock
    private var block: Action?
    private var scheduledInvocationTime: TimeInterval
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
