import Foundation

public final class Monitor<Ephemeral, Terminal> {
    public typealias EphemeralObserver = Consumer<Ephemeral>
    public typealias TerminalObserver = Consumer<Terminal>
    public typealias DisposeObserver = Action

    public static func make(of ephemeralType: Ephemeral.Type = Ephemeral.self,
                     _ terminalType: Terminal.Type = Terminal.self) -> (Monitor<Ephemeral, Terminal>, Feed<Ephemeral, Terminal>) {
        let monitor = Monitor(of: ephemeralType, terminalType)
        let feed = Feed(monitor: monitor,
                        ephemeralFeed: Monitor<Ephemeral, Terminal>.eat,
                        terminalFeed: Monitor<Ephemeral, Terminal>.eat,
                        disposeObserver: Monitor<Ephemeral, Terminal>.onDispose,
                        setDispatcher: { $0.dispatcher = $1 })
        return (monitor, feed)
    }
    
    public init(terminal: Terminal, ephemeralType: Ephemeral.Type = Ephemeral.self) {
        state = .terminated(terminal)
    }

    private init(of ephemeralType: Ephemeral.Type = Ephemeral.self,
                 _ terminalType: Terminal.Type = Terminal.self) {
        state = .pending([], [])
    }

    deinit {
        dispatcher?.assertIsCurrent(flags: [.barrier])
        guard case .pending(_, let finalizers) = state else { return }
        for finalizer in finalizers {
            finalizer()
        }
    }

    public func observe(ephemeral ephemeralObserver: @escaping EphemeralObserver,
                        terminal terminalObserver: @escaping TerminalObserver) -> Vanishable {
        dispatcher?.assertIsCurrent(flags: [.barrier])
        switch state {
        case .pending(var subscriptions, let finalizers):
            let subscription = Subscription(ephemeralObserver: ephemeralObserver,
                                            terminalObserver: terminalObserver,
                                            canceler: removeSubscription)
            subscriptions.append(Weak(subscription))
            state = .pending(subscriptions, finalizers)
            return subscription
        case .terminated(let terminal):
            terminalObserver(terminal)
            return Vanished()
        }

    }

    private func onDispose(execute callback: @escaping DisposeObserver) {
        dispatcher?.assertIsCurrent(flags: [.barrier])
        switch state {
        case .pending(let subscriptions, var finalizers):
            finalizers.append(callback)
            state = .pending(subscriptions, finalizers)
        case .terminated(_):
            callback()
        }
    }

    private func eat(ephemeral: Ephemeral) {
        dispatcher?.assertIsCurrent(flags: [])
        guard case .pending(let subscriptions, _) = state else { return }
        for subscription in subscriptions {
            subscription.payload?.ephemeralObserver?(ephemeral)
        }
    }

    private func eat(terminal: Terminal) {
        dispatcher?.assertIsCurrent(flags: [.barrier])
        guard case .pending(let subscriptions, let finalizers) = state else { return }
        state = .terminated(terminal)
        for subscription in subscriptions {
            subscription.payload?.terminalObserver?(terminal)
        }
        for subscription in subscriptions {
            subscription.payload?.cancel()
        }
        for finalizer in finalizers {
            finalizer()
        }
    }

    private func removeSubscription(_ subscription: Subscription<Ephemeral, Terminal>) {
        dispatcher?.assertIsCurrent(flags: [.barrier])
        guard case .pending(var subscriptions, let finalizers) = state else { return }
        subscriptions.removeAll(where: { $0.payload === subscription })
        state = .pending(subscriptions, finalizers)
    }

    private var state: State<Ephemeral, Terminal>
    // Monitor does not dispatch anything. This dispatcher acts like a guard to prevent non thread-safe actions
    private(set) var dispatcher: Dispatching?
}

private enum State<Ephemeral, Terminal> {
    case pending([Weak<Subscription<Ephemeral, Terminal>>], [Action])
    case terminated(Terminal)
}

public struct Feed<Ephemeral, Terminal> {
    public typealias EphemeralFeed = Consumer<Ephemeral>
    public typealias TerminalFeed = Consumer<Terminal>
    public typealias DisposeObserver = (@escaping Action) -> Void

    init(monitor: Monitor<Ephemeral, Terminal>,
         ephemeralFeed: @escaping Transform<Monitor<Ephemeral, Terminal>, EphemeralFeed>,
         terminalFeed: @escaping Transform<Monitor<Ephemeral, Terminal>, TerminalFeed>,
         disposeObserver: @escaping Transform<Monitor<Ephemeral, Terminal>, DisposeObserver>,
         setDispatcher: @escaping (Monitor<Ephemeral, Terminal>, Dispatching) -> Void) {
        self.monitor = monitor
        self.ephemeralFeed = ephemeralFeed
        self.terminalFeed = terminalFeed
        self.disposeObserver = disposeObserver
        self.dispatcherMutator = setDispatcher
    }
    
    init?(feed: Feed<Ephemeral, Terminal>, terminalInterceptor: @escaping Action) {
        guard let monitor = feed.monitor else { return nil }
        self.init(monitor: monitor,
                  ephemeralFeed: feed.ephemeralFeed,
                  terminalFeed: Feed.makeTerminalInterceptor(invocation: feed.terminalFeed, interceptor: terminalInterceptor),
                  disposeObserver: feed.disposeObserver,
                  setDispatcher: feed.dispatcherMutator)
    }

    func setTargetDispatcher(_ dispatcher: Dispatching) {
        guard let monitor = self.monitor else { return }
        dispatcherMutator(monitor, dispatcher)
    }
    
    public var abandoned: Bool {
        return monitor == nil
    }
    
    public func addCancelationObserver(onCancel: @escaping Action) {
        guard let monitor = self.monitor else {
            onCancel()
            return
        }
        disposeObserver(monitor)(onCancel)
    }

    public func push(ephemeral: Ephemeral) {
        guard let monitor = self.monitor else { return }
        ephemeralFeed(monitor)(ephemeral)
    }

    public func push(terminal: Terminal) {
        guard let monitor = self.monitor else { return }
        terminalFeed(monitor)(terminal)
    }

    private static func makeTerminalInterceptor(invocation: @escaping Transform<Monitor<Ephemeral, Terminal>, TerminalFeed>,
                                                interceptor: @escaping Action) -> Transform<Monitor<Ephemeral, Terminal>, TerminalFeed> {
        func makeForwarder(for monitor: Monitor<Ephemeral, Terminal>) -> TerminalFeed {
            return { terminal in
                interceptor()
                invocation(monitor)(terminal)
            }
        }
        return makeForwarder
    }
    
    private weak var monitor: Monitor<Ephemeral, Terminal>?
    private let ephemeralFeed: Transform<Monitor<Ephemeral, Terminal>, Consumer<Ephemeral>>
    private let terminalFeed: Transform<Monitor<Ephemeral, Terminal>, Consumer<Terminal>>
    private let disposeObserver: Transform<Monitor<Ephemeral, Terminal>, DisposeObserver>
    private let dispatcherMutator: (Monitor<Ephemeral, Terminal>, Dispatching) -> Void
}

private final class Subscription<Ephemeral, Terminal>: Vanishable {
    public typealias EphemeralObserver = Monitor<Ephemeral, Terminal>.EphemeralObserver
    public typealias TerminalObserver = Monitor<Ephemeral, Terminal>.TerminalObserver
    public typealias Canceler = Consumer<Subscription<Ephemeral, Terminal>>

    init(ephemeralObserver: @escaping EphemeralObserver,
         terminalObserver: @escaping TerminalObserver,
         canceler: @escaping Canceler) {
        self.ephemeralObserver = ephemeralObserver
        self.terminalObserver = terminalObserver
        self.canceler = canceler
    }

    var ephemeralObserver: EphemeralObserver?
    var terminalObserver: TerminalObserver?

    func cancel() {
        ephemeralObserver = nil
        terminalObserver = nil
        canceler?(self)
        canceler = nil

        vanishEvent.runIfRequested { $0.runCallbacks() }
    }

    var vanished: VanishEventObservable {
        return vanishEvent.requestResource(self)
    }

    func same(as vanishable: Vanishable) -> Bool {
        guard let ref = vanishable as? Subscription<Ephemeral, Terminal> else { return false }
        return ref === self
    }

    private var canceler: Canceler?
    private var vanishEvent = OnDemand(factory: VanishEventImpl.init)

    private final class VanishEventImpl: VanishEventObservable {
        init(parent: Subscription) {
            self.parent = parent
        }

        func execute(callback: @escaping Consumer<Vanishable>) {
            if parent?.canceler == nil {
                guard let parent = self.parent else {
                    fatalError("Unable to run callbacks of VanishEventImpl because it's parent was gone")
                }
                callback(parent)
            } else {
                cancelCallbacks.append(callback)
            }
        }

        func runCallbacks() {
            guard let parent = self.parent else {
                fatalError("Unable to run callbacks of VanishEventImpl because it's parent was gone")
            }
            let callbacks = cancelCallbacks
            cancelCallbacks.removeAll()
            for callback in callbacks {
                callback(parent)
            }
        }

        private weak var parent: Subscription?
        private var cancelCallbacks = [] as [Consumer<Vanishable>]
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
