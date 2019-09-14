import Foundation

public extension Monitor {
    func transfer<M: LitteredStrategy>(from source: Dispatching,
                                    to target: Dispatching,
                                    mode: TransferMode,
                                    valve: SafetyValve,
                                    mergeStrategy: M?) -> Monitor where M.Element == Ephemeral {
        typealias FactoryType = TransferingFactory<M, Terminal>
        let factory = FactoryType(sourceDispatcher: source,
                                  targetDispatcher: target,
                                  mode: mode,
                                  safetyValve: valve,
                                  mergeStrategy: mergeStrategy)
        let result = transform(factory: factory)
        return result
    }
    
    func transfer(from source: Dispatching, to target: Dispatching, mode: TransferMode = .default) -> Monitor {
        typealias Factory = TransferingFactory<DoNotMerge<Ephemeral>, Terminal>
        let factory = Factory(sourceDispatcher: source,
                              targetDispatcher: target,
                              mode: mode,
                              safetyValve: DirectPass(),
                              mergeStrategy: nil)
        return transform(factory: factory)
    }
}

private struct TransferingFactory<M: LitteredStrategy, T>: MonitorTransformingFactory {
    typealias Transforming = Transferer<M, T>

    init(sourceDispatcher: Dispatching,
         targetDispatcher: Dispatching,
         mode: TransferMode,
         safetyValve: SafetyValve,
         mergeStrategy: M?) {
        self.sourceDispatcher = sourceDispatcher
        self.targetDispatcher = targetDispatcher
        self.safetyValve = safetyValve
        self.mergeStrategy = mergeStrategy
        self.mode = mode
    }

    func make(feed: Feed<M.Element, T>) -> Transferer<M, T> {
        feed.setTargetDispatcher(targetDispatcher)
        return Transferer(sourceDispatcher: sourceDispatcher,
                          targetDispatcher: targetDispatcher,
                          mode: mode,
                          safetyValve: safetyValve,
                          mergeStrategy: mergeStrategy,
                          feed: feed)
    }

    private let sourceDispatcher: Dispatching
    private let targetDispatcher: Dispatching
    private let safetyValve: SafetyValve
    private let mergeStrategy: M?
    private let mode: TransferMode
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
