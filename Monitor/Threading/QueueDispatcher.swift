import Foundation

public extension DispatchQueue {
    var dispatcher: Dispatching & DelayedDispatching {
        return QueueDispatcher(queue: self)
    }
}

private struct QueueDispatcher: Dispatching, DelayedDispatching {
    init(queue: DispatchQueue) {
        self.queue = queue
    }

    func assertIsCurrent(flags: DispatchingFlags) {
        if flags.contains(.barrier) {
            dispatchPrecondition(condition: .onQueueAsBarrier(queue))
        } else {
            dispatchPrecondition(condition: .onQueue(queue))
        }
    }

    func assertNotIsCurrent() {
        dispatchPrecondition(condition: .notOnQueue(queue))
    }

    func async(flags: DispatchingFlags, execute block: @escaping Action) -> Vanishable {
        let task = AsyncTask(block: block, flags: flags)
        task.schedule(on: queue)
        return task
    }

    func sync<T>(flags: DispatchingFlags, execute block: () throws -> T) rethrows -> T {
        return try queue.sync(flags: DispatchWorkItemFlags(flags), execute: block)
    }

    func async(after timeout: TimeInterval,
               flags: DispatchingFlags,
               execute block: @escaping Action) -> Vanishable {
        let task = AsyncTask(block: block, flags: flags)
        task.schedule(after: timeout, on: queue)
        return task
    }

    private let queue: DispatchQueue
}

private extension DispatchWorkItemFlags {
    init(_ flags: DispatchingFlags) {
        if flags.contains(.barrier) {
            self = [.barrier]
        } else {
            self = []
        }
    }
}

private final class AsyncTask: Vanishable, VanishEventObservable {
    init(block: @escaping Action, flags: DispatchingFlags) {
        self.block = block

        // There is an intentional retain cycle
        // It will be broken if:
        // 1. callback is executed, or
        // 2. invocation is canceled
        workItem = DispatchWorkItem(qos: .default, flags: DispatchWorkItemFlags(flags), block: run)
    }

    var vanished: VanishEventObservable {
        return self
    }

    func same(as vanishable: Vanishable) -> Bool {
        guard let other = vanishable as? AsyncTask else { return false }
        return other === self
    }

    func execute(callback: @escaping Consumer<Vanishable>) {
        if workItem == nil {
            callback(self)
        } else {
            vanishedCallbacks.append(callback)
        }
    }

    func schedule(after timeInterval: TimeInterval, on queue: DispatchQueue) {
        guard let workItem = self.workItem else { return }
        queue.asyncAfter(deadline: .now() + .microseconds(Int(timeInterval * 1000000)), execute: workItem)
    }

    func schedule(on queue: DispatchQueue) {
        guard let workItem = self.workItem else { return }
        queue.async(execute: workItem)
    }

    func run() {
        block()
        finalize()
    }

    func cancel() {
        workItem?.cancel()
        finalize()
    }

    private func finalize() {
        workItem = nil
        for callback in vanishedCallbacks {
            callback(self)
        }
    }

    private var workItem: DispatchWorkItem?
    private let block: Action
    private var vanishedCallbacks = [] as [Consumer<Vanishable>]
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
