import Foundation
import Monitor

extension ManualDispatcher {
    func beginHighConcurrencySimulation(multiplier: UInt = 10) -> Vanishable {
        return HighConcurencySimulator(multiplier: multiplier, dispatcher: self)
    }
    
    func simulatingHighConcurrency<T>(multiplier: UInt = 10, run suite: () throws -> T) rethrows -> T {
        let sumulation = beginHighConcurrencySimulation(multiplier: multiplier)
        defer { sumulation.cancel() }
        return try suite()
    }
}

private extension ManualDispatcher {
    final class HighConcurencySimulator: Vanishable, VanishEventObservable {
        init(multiplier: UInt, dispatcher: ManualDispatcher) {
            self.multiplier = multiplier
            self.dispatcher = dispatcher

            self.interception = ManualDispatcher.introduce(in: .afterScheduleInvocation) { [weak self] in
                self?.onInvocationScheduled(dispatcher: $0)
            }
            populate()
        }
        
        deinit {
            precondition(interception == nil)
        }
        
        private func onInvocationScheduled(dispatcher: ManualDispatcher) {
            guard dispatcher == self.dispatcher else { return }
            populate()
        }
        
        private func populate() {
            if !isPopulating {
                isPopulating = true
                for _ in 0..<multiplier {
                    dispatcher.async(flags: [], execute: {})
                }
                isPopulating = false
            }
        }
        
        func cancel() {
            interception?.cancel()
            interception = nil
        
            let callbacks = completionCallbacks
            completionCallbacks.removeAll()
            for callback in callbacks {
                callback(self)
            }
        }
        
        var vanished: VanishEventObservable {
            return self
        }
        
        func same(as vanishable: Vanishable) -> Bool {
            return (vanishable as? HighConcurencySimulator) === self
        }
        
        func execute(callback: @escaping Consumer<Vanishable>) {
            if interception == nil {
                callback(self)
            } else {
                completionCallbacks.append(callback)
            }
        }
    
        private let dispatcher: ManualDispatcher
        private let multiplier: UInt
        private var interception: Cancelable?
        private var completionCallbacks = [] as [Consumer<Vanishable>]
        private var isPopulating = false
    }
}

// Copyright (C) 2020 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
