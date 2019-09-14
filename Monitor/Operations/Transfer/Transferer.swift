import Foundation

struct Transferer<M: LitteredStrategy, T>: MonitorTransforming {
    typealias InputEphemeral = M.Element
    typealias InputTerminal = T
    typealias OutputEphemeral = M.Element
    typealias OutputTerminal = T
    
    init(sourceDispatcher: Dispatching,
         targetDispatcher: Dispatching,
         mode: TransferMode,
         safetyValve: SafetyValve,
         mergeStrategy: M?,
         feed: Feed<M.Element, T>) {
        self.sourceDispatcher = sourceDispatcher
        self.targetDispatcher = targetDispatcher
        self.feed = feed
        self.safetyValve = safetyValve
        self.mergeStrategy = mergeStrategy
        switch mode {
        case .default:
            flags = []
        case .barrier:
            flags = [.barrier]
        }
    }
    
    func eat(ephemeral: M.Element) {
        sourceDispatcher.assertIsCurrent(flags: [])
        if safetyValve.isLittered, let mergeStrategy = mergeStrategy {
            mergeStrategy.put(element: ephemeral)
        } else {
            safetyValve.invocationSheduled()
            targetDispatcher.async(flags: flags) { [feed, safetyValve, mergeStrategy] in
                feed.push(ephemeral: ephemeral)
                repeat {
                    if let next = mergeStrategy?.push() {
                        feed.push(ephemeral: next)
                    } else  {
                        safetyValve.invocationComplete()
                        return 
                    }
                } while true
            }
        }
    }
    
    func eat(terminal: T) {
        targetDispatcher.async(flags: [.barrier]) { [feed] in feed.push(terminal: terminal) }
    }
    
    func cancel(sourceSubscription: Cancelable) {
        targetDispatcher.assertIsCurrent(flags: [.barrier])
        sourceDispatcher.async(flags: [.barrier], execute: { sourceSubscription.cancel() })
    }
    
    private let sourceDispatcher: Dispatching
    private let targetDispatcher: Dispatching
    private let safetyValve: SafetyValve
    private let mergeStrategy: M?
    private let feed: Feed<M.Element, T>
    private let flags: DispatchingFlags
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
