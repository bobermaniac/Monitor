import Foundation
import Monitor
import XCTest

final class ManualDispatcher: Dispatching, DelayedDispatching, Equatable {
    init(name: String = "anonymous", simultaneousOperationCount: UInt8 = 1) {
        self.name = name
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
    func async(flags: DispatchingFlags, execute block: @escaping Action) -> Vanishable {
        let task = ScheduledTask(block: block, flags: flags, timeout: 0)
        pendingTasks.append(task)
        return task
    }
    
    func sync<T>(flags: DispatchingFlags, execute block: () throws -> T) rethrows -> T {
        var virtualExecutionComplete = false
        let task = ScheduledTask(block: { virtualExecutionComplete = true },
                                 flags: flags,
                                 timeout: 0)
        pendingTasks.append(task)
        while !virtualExecutionComplete {
            dispatchNext(timeInterval: 0)
        }
        ManualDispatcher.dispatchersStack.append((flags, self))
        defer { ManualDispatcher.dispatchersStack.removeLast() }
        return try ManualDispatcher.run(block)

    }

    @discardableResult
    func async(after timeout: TimeInterval,
               flags: DispatchingFlags,
               execute block: @escaping Action) -> Vanishable {
        let task = ScheduledTask(block: block, flags: flags, timeout: timeout)
        pendingTasks.append(task)
        return task
    }

    @discardableResult
    func dispatchNext(timeInterval: TimeInterval = 0) -> Bool {
        if pendingTasks.isEmpty { return false }
        pendingTasks.removeAll { $0.state.isCanceled }

        if pendingTasks.isEmpty { return false }
        pendingTasks.forEach { $0.eat(timeInterval: timeInterval) }

        let tasksReadyToBeExecuted = pendingTasks.filter { !$0.state.isPending }
        if tasksReadyToBeExecuted.isEmpty { return true }

        if simultaneousOperationCount == 1 {
            executeSingle(task: tasksReadyToBeExecuted.first!)
        } else {
            executeMultiple(tasks: tasksReadyToBeExecuted)
        }
        return true
    }

    private func executeSingle(task: ScheduledTask) {
        guard case .execute(let block, let flags) = task.state else {
            fatalError("Inconsistent state")
        }
        executeInContext(blocks: [block, task.cancel], flags: flags)
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
            let blocks = executingTasks.map { task -> [Action] in
                guard case .execute(let block, _) = task.state else {
                    fatalError("Inconsistent state")
                }
                return [block, task.cancel]
            }
            executeManyInContext(blocks: blocks, flags: [])
            pendingTasks.removeAll(where: executingTasks.contains)
        }
    }

    private func executeInContext(blocks: [Action], flags: DispatchingFlags) {
        ManualDispatcher.dispatchersStack.append((flags, self))
        for block in blocks {
            ManualDispatcher.run(block)
        }
        ManualDispatcher.dispatchersStack.removeLast()
    }

    private func executeManyInContext(blocks: [[Action]], flags: DispatchingFlags) {
        ManualDispatcher.dispatchersStack.append((flags, self))
        for block in blocks.flatMap({ $0 }) {
            ManualDispatcher.run(block)
        }
        ManualDispatcher.dispatchersStack.removeLast()
    }
    
    private static func run<T>(_ block: () throws -> T) rethrows -> T {
        ManualDispatcher.invoke(joinPoint: .beforeDispatchedEntityInvocation)
        do {
            let result = try block()
            ManualDispatcher.invoke(joinPoint: .afterDispatchedEntitiyInvocation)
            return result
        } catch let error {
            ManualDispatcher.invoke(joinPoint: .afterDispatchedEntitiyInvocation)
            throw error
        }
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
    }
    
    static func introduce(in joinPoint: JoinPoint, invocation: @escaping Action) -> Cancelable {
        let tag = (0..<Int.max).first { !introductions.keys.contains($0) }!
        introductions[tag] = (joinPoint, invocation)
        return Token(tag: tag)
    }
    
    private static func detachIntroduction(at tag: Int) {
        introductions.removeValue(forKey: tag)
    }
    
    private static func invoke(joinPoint: JoinPoint) {
        for introduction in introductions.values {
            if introduction.0 == joinPoint {
                introduction.1()
            }
        }
    }
    
    private static var introductions = [:] as [Int: (JoinPoint, Action)]
    
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

private final class ScheduledTask: Vanishable, VanishEventObservable, Equatable {
    static func ==(lhs: ScheduledTask, rhs: ScheduledTask) -> Bool {
        return lhs === rhs
    }

    init(block: @escaping Action, flags: DispatchingFlags, timeout: TimeInterval) {
        self.block = block
        self.flags = flags
        self.elapsedPendingTime = timeout
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

    var vanished: VanishEventObservable {
        return self
    }

    func execute(callback: @escaping Consumer<Vanishable>) {
        if block == nil {
            callback(self)
        } else {
            pendingCallbacks.append(callback)
        }
    }

    func same(as vanishable: Vanishable) -> Bool {
        guard let task = vanishable as? ScheduledTask else {
            return false
        }
        return task === self
    }

    func cancel() {
        block = nil
    }

    func eat(timeInterval: TimeInterval) {
        elapsedPendingTime -= timeInterval
    }

    var state: State {
        guard let block = self.block else {
            return .canceled
        }
        if elapsedPendingTime > 0 {
            return .pending
        }
        return .execute(block: block, flags: flags)
    }

    private let flags: DispatchingFlags
    private var block: (Action)? {
        didSet {
            if block == nil {
                for callback in pendingCallbacks {
                    callback(self)
                }
                pendingCallbacks.removeAll()
            }
        }
    }
    
    private var pendingCallbacks = [] as [Consumer<Vanishable>]
    private var elapsedPendingTime: TimeInterval
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
