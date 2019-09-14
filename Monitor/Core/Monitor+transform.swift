import Foundation

public protocol MonitorTransformingFactory {
    associatedtype Transforming: MonitorTransforming
    typealias InputEphemeral = Transforming.InputEphemeral
    typealias InputTerminal = Transforming.InputTerminal
    typealias OutputEphemeral = Transforming.OutputEphemeral
    typealias OutputTerminal = Transforming.OutputTerminal

    func make(feed: Feed<Transforming.OutputEphemeral, Transforming.OutputTerminal>) -> Transforming
}

public protocol MonitorTransforming {
    associatedtype InputEphemeral
    associatedtype InputTerminal
    associatedtype OutputEphemeral
    associatedtype OutputTerminal

    func eat(ephemeral: InputEphemeral)
    func eat(terminal: InputTerminal)

    func cancel(sourceSubscription: Cancelable)
}

public extension Monitor {
    func transform<Factory: MonitorTransformingFactory>(
        factory: Factory
    ) -> Monitor<Factory.OutputEphemeral, Factory.OutputTerminal>
    where Factory.InputEphemeral == Ephemeral, Factory.InputTerminal == Terminal {
        // If transformer emits terminal to output feed we should cancel source subscription
        // because we need no more events from input stream
        let interceptor = TerminalInterceptor()
        let (result, rawFeed) = Monitor<Factory.OutputEphemeral, Factory.OutputTerminal>.make()
        let feed = Feed(feed: rawFeed, terminalInterceptor: interceptor.terminalReceived)!

        // After subscription we should set received cancelation token to interceptor
        let transformer = factory.make(feed: feed)
        let subscription = observe(ephemeral: transformer.eat, terminal: transformer.eat)
        interceptor.cancelables = [subscription]
        
        // We store source monitor reference in target monitor to prevent deallocation while observing
        let storage = TransformerStorage(subscription: subscription, transformer: transformer)
        feed.addCancelationObserver(onCancel: storage.cancel)
        
        // Transformned monitor inherits source dispatcher
        dispatcher.map(feed.setTargetDispatcher)
        return result
    }
}

private final class TransformerStorage<Transformer: MonitorTransforming> {
    init(subscription: Cancelable, transformer: Transformer) {
        self.subscription = subscription
        self.transformer = transformer
    }

    func cancel() {
        transformer.cancel(sourceSubscription: subscription)
    }

    private let subscription: Cancelable
    private let transformer: Transformer
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
