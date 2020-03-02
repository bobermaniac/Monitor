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

    func async(flags: DispatchingFlags, execute block: @escaping Action) -> Cancelable {
        let workItem = DispatchWorkItem(qos: .default,
                                        flags: DispatchWorkItemFlags(flags),
                                        block: block)
        queue.async(execute: workItem)
        return CancelableWorkItem(workItem: workItem)
    }

    func sync<T>(flags: DispatchingFlags, execute block: () throws -> T) rethrows -> T {
        return try queue.sync(flags: DispatchWorkItemFlags(flags), execute: block)
    }

    func async(after timeout: TimeInterval,
               flags: DispatchingFlags,
               execute block: @escaping Action) -> Cancelable {
        let workItem = DispatchWorkItem(qos: .default,
                                        flags: DispatchWorkItemFlags(flags),
                                        block: block)
        queue.asyncAfter(deadline: .now() + .microseconds(Int(timeout * 1_000_000)), execute: workItem)
        return CancelableWorkItem(workItem: workItem)
    }

    private let queue: DispatchQueue
}

private struct CancelableWorkItem: Cancelable {
    init(workItem: DispatchWorkItem) {
        self.workItem = workItem
    }
    
    func cancel() {
        workItem?.cancel()
    }
    
    private weak var workItem: DispatchWorkItem?
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

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
