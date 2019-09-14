import Foundation

public extension Monitor {
    func debounce(timeout: TimeInterval,
                  dispatcher: DelayedDispatching,
                  mode: TransferMode = .default,
                  threadSafety: ThreadSafetyStrategy = CalleeSyncGuaranteed()) -> Monitor {
        dispatcher.assertIsCurrent(flags: [.barrier])
        let factory = DebouncingFactory(timeout: timeout,
                                        dispatcher: dispatcher,
                                        mode: mode,
                                        threadSafety: threadSafety,
                                        payload: (Ephemeral.self, Terminal.self))
        return transform(factory: factory)
    }
}

struct DebouncingFactory<Ephemeral, Terminal>: MonitorTransformingFactory {
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

    func make(feed: Feed<Ephemeral, Terminal>) -> Debouncer<Ephemeral, Terminal> {
        return Debouncer(timeout: timeout, dispatcher: dispatcher, mode: mode, threadSafety: threadSafety, feed: feed)
    }

    typealias Transforming = Debouncer<Ephemeral, Terminal>

    private let timeout: TimeInterval
    private let dispatcher: DelayedDispatching
    private let mode: TransferMode
    private let threadSafety: ThreadSafetyStrategy
}

final class Debouncer<Ephemeral, Terminal>: MonitorTransforming {
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
        self.threadSafety = threadSafety
        self.feed = feed
        switch mode {
        case .default:
            flags = []
        case .barrier:
            flags = .barrier
        }
        self.synchronizedContext = SynchronizedContext(content: MutableState())
    }

    func eat(ephemeral: Ephemeral) {
        dispatcher.assertIsCurrent(flags: [])
        execute(block: { [feed] in feed.push(ephemeral: ephemeral) }, with: threadSafety)
    }

    func eat(terminal: Terminal) {
        dispatcher.assertIsCurrent(flags: .barrier)
        execute(block: { [feed] in feed.push(terminal: terminal) }, with: CalleeSyncGuaranteed())
    }

    func cancel(sourceSubscription: Cancelable) {
        dispatcher.assertIsCurrent(flags: .barrier)
        synchronizedContext.read(using: CalleeSyncGuaranteed()) { $0.activeTask?.cancel() }
        sourceSubscription.cancel()
    }

    private func execute(block: @escaping Action, with threadSafety: ThreadSafetyStrategy) {
        synchronizedContext.read(using: CalleeSyncGuaranteed()) { $0.activeTask?.cancel() }
        dispatcher.async(after: timeout, flags: flags, execute: block)
            .associate(with: \.activeTask, in: ContextAccessor(synchronizedContext, threadSafety: threadSafety))
    }

    private let timeout: TimeInterval
    private let dispatcher: DelayedDispatching
    private let feed: Feed<Ephemeral, Terminal>
    private let synchronizedContext: SynchronizedContext<MutableState>
    private let threadSafety: ThreadSafetyStrategy
    private let flags: DispatchingFlags

    private struct MutableState {
        init() { }

        var activeTask: Vanishable?
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
