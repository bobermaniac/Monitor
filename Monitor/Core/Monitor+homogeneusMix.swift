import Foundation

public protocol MonitorHomogeneousMixingFactory {
    associatedtype Mixer: MonitorHomogeneousMixing
    typealias InputEphemeral = Mixer.InputEphemeral
    typealias InputTerminal = Mixer.InputTerminal
    typealias OutputEphemeral = Mixer.OutputEphemeral
    typealias OutputTerminal = Mixer.OutputTerminal
    
    func make(count: Int, feed: Feed<OutputEphemeral, OutputTerminal>) -> Mixer
}

public protocol MonitorHomogeneousMixing {
    associatedtype InputEphemeral
    associatedtype InputTerminal
    associatedtype OutputEphemeral
    associatedtype OutputTerminal
    
    func eat(ephemeral: InputEphemeral, at index: Int)
    func eat(terminal: InputTerminal, at index: Int)
    
    func cancel(sourceSubscriptions: [Cancelable])
}

public func mix<Factory: MonitorHomogeneousMixingFactory>(_ monitors: [Monitor<Factory.InputEphemeral, Factory.InputTerminal>],
                                                          factory: Factory) -> Monitor<Factory.OutputEphemeral, Factory.OutputTerminal> {
    let interceptor = TerminalInterceptor()
    let (result, rawFeed) = Monitor.make(of: Factory.OutputEphemeral.self, Factory.OutputTerminal.self)
    let feed = Feed(feed: rawFeed, terminalInterceptor: interceptor.terminalReceived)!
    
    let compressor = factory.make(count: monitors.count, feed: feed)
    let tokens = monitors.enumerated().map { enumerated -> Vanishable in
        let monitor = enumerated.element
        let index = enumerated.offset
        return monitor.observe(ephemeral: { compressor.eat(ephemeral: $0, at: index) },
                               terminal: { compressor.eat(terminal: $0, at: index) })
    }
    interceptor.cancelables = tokens
    
    let storage = MixerStorage(subscriptions: tokens, compressor: compressor)
    feed.addCancelationObserver(onCancel: storage.cancel)
    monitors.first(where: { $0.dispatcher != nil }).flatMap { $0.dispatcher }.map(feed.setTargetDispatcher)
    return result
}

private final class MixerStorage<Compressor: MonitorHomogeneousMixing> {
    init(subscriptions: [Cancelable], compressor: Compressor) {
        self.subscriptions = subscriptions
        self.compressor = compressor
    }
    
    func cancel() {
        compressor.cancel(sourceSubscriptions: subscriptions)
    }
    
    private let subscriptions: [Cancelable]
    private let compressor: Compressor
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
