import Foundation

public extension Monitor {
    func throttle(timeout: TimeInterval,
                  dispatcher: DelayedDispatching,
                  mode: TransferMode = .default,
                  threadSafety: ThreadSafetyStrategy = CalleeSyncGuaranteed()) -> Monitor {
        dispatcher.assertIsCurrent(flags: [.barrier])
        let factory = ThrottlingFactory(timeout: timeout,
                                        dispatcher: dispatcher,
                                        mode: mode,
                                        threadSafety: threadSafety,
                                        payload: (Ephemeral.self, Terminal.self))
        return transform(factory: factory)
    }
}

struct ThrottlingFactory<Ephemeral, Terminal>: MonitorTransformingFactory {
    init(timeout: TimeInterval,
         dispatcher: DelayedDispatching,
         mode: TransferMode,
         threadSafety: ThreadSafetyStrategy,
         payload: (Ephemeral.Type, Terminal.Type)) {
        self.timeout = timeout
        self.dispatcher = dispatcher
        self.mode = mode
        self.threadSafety = threadSafety
    }

    func make(feed: Feed<Ephemeral, Terminal>) -> Throttler<Ephemeral, Terminal> {
        return Throttler(timeout: timeout,
                         dispatcher: dispatcher,
                         mode: mode,
                         threadSafety: threadSafety,
                         feed: feed)
    }

    typealias Transforming = Throttler<Ephemeral, Terminal>

    private let timeout: TimeInterval
    private let dispatcher: DelayedDispatching
    private let threadSafety: ThreadSafetyStrategy
    private let mode: TransferMode
}

final class Throttler<Ephemeral, Terminal>: MonitorTransforming {
    typealias InputEphemeral = Ephemeral
    typealias InputTerminal = Terminal
    typealias OutputEphemeral = Ephemeral
    typealias OutputTerminal = Terminal

    init(timeout: TimeInterval,
         dispatcher: DelayedDispatching,
         mode: TransferMode,
         threadSafety: ThreadSafetyStrategy,
         feed: Feed<Ephemeral, Terminal>) {
        self.timeout = timeout
        self.dispatcher = dispatcher
        self.feed = feed
        self.threadSafety = threadSafety
        self.synchronizedContext = SynchronizedContext(content: MutableState())
        switch mode {
        case .default:
            flags = []
        case .barrier:
            flags = .barrier
        }
    }

    func eat(ephemeral: Ephemeral) {
        dispatcher.assertIsCurrent(flags: [])
        let sheduleNextInvocation = synchronizedContext.readWrite(using: threadSafety) { state in
            if state.pendingInvocation != nil {
                assert(state.pendingInvocationStorage != nil)
                state.pendingInvocationStorage?.ephemeral = ephemeral
                return false
            } else {
                state.pendingInvocationStorage = MutableStorage(ephemeral: ephemeral)
                return true
            }
        } as Bool
        if sheduleNextInvocation {
            let contextAccessor = ContextAccessor(synchronizedContext, threadSafety: threadSafety)
            dispatcher.async(after: timeout, flags: flags, execute: { [feed] in
                if let payload = contextAccessor.read(block: { $0.pendingInvocationStorage?.ephemeral }) {
                    feed.push(ephemeral: payload)
                }
            }).associate(with: \.pendingInvocation, in: contextAccessor)
        }
    }

    func eat(terminal: Terminal) {
        dispatcher.assertIsCurrent(flags: [.barrier])
        synchronizedContext.read(using: CalleeSyncGuaranteed()) { $0.pendingInvocation?.cancel() }
        feed.push(terminal: terminal)
    }

    func cancel(sourceSubscription: Cancelable) {
        dispatcher.assertIsCurrent(flags: .barrier)
        synchronizedContext.read(using: CalleeSyncGuaranteed()) { $0.pendingInvocation?.cancel() }
        sourceSubscription.cancel()
    }

    private let timeout: TimeInterval
    private let dispatcher: DelayedDispatching
    private let feed: Feed<Ephemeral, Terminal>
    private let threadSafety: ThreadSafetyStrategy
    private let flags: DispatchingFlags
    private let synchronizedContext: SynchronizedContext<MutableState>

    private struct MutableState {
        init() { }

        var pendingInvocationStorage: MutableStorage?
        var pendingInvocation: Vanishable? {
            didSet {
                if pendingInvocation == nil {
                    pendingInvocationStorage = nil
                }
            }
        }
    }

    private final class MutableStorage {
        init(ephemeral: Ephemeral) {
            self.ephemeral = ephemeral
        }

        var ephemeral: Ephemeral
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
