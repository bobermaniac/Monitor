import Foundation

public extension Monitor {
    func forward<S: LitteredStrategy>(from sourceDispatcher: Dispatching,
                                      to dispatcher: Dispatching,
                                      into feed: Feed<Ephemeral, Terminal>,
                                      mode: TransferMode,
                                      safetyValve: SafetyValve,
                                      litteredStrategy: S?) where S.Element == Ephemeral {
        sourceDispatcher.assertIsCurrent(flags: [.barrier])
        let transferer = Transferer(sourceDispatcher: sourceDispatcher,
                                    targetDispatcher: dispatcher,
                                    mode: mode,
                                    safetyValve: safetyValve,
                                    mergeStrategy: litteredStrategy,
                                    feed: feed)
        let subscription = observe(ephemeral: transferer.eat, terminal: transferer.eat)
        let storage = TransfererStorage(subscription: subscription, transformer: transferer)
        dispatcher.async(flags: [.barrier]) {
            feed.addCancelationObserver(onCancel: storage.cancel)
        }
    }
    
    func forward(from sourceDispatcher: Dispatching,
                 to dispatcher: Dispatching,
                 into feed: Feed<Ephemeral, Terminal>,
                 mode: TransferMode = .default) {
        forward(from: sourceDispatcher,
                to: dispatcher,
                into: feed,
                mode: mode,
                safetyValve: DirectPass(),
                litteredStrategy: nil as DoNotMerge<Ephemeral>?)
    }
}

private final class TransfererStorage<Transformer: MonitorTransforming> {
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
