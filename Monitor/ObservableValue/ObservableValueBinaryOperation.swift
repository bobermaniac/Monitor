import Foundation

public final class ObservableValueBinaryOperation<Left, Right, Result> {
    public init(left: ObservableValue<Left>, right: ObservableValue<Right>, operation: @escaping (Left, Right) -> Result) {
        self.left = left
        self.right = right
        self.operation = operation
    }
    
    public func run() -> ObservableValue<Result> {
        do {
            let value = operation(try left.unwrap(), try right.unwrap())
            let (result, mutate, fail) = ObservableValue.make(initialValue: value)
            let cancelations = [
                left.observable.observe(ephemeral: onLeftChanged, terminal: onTerminated),
                right.observable.observe(ephemeral: onRightChanged, terminal: onTerminated)
            ]
            transform = Transformation(mutate: mutate, fail: fail, subscriptions: cancelations)
            result.addLifetimeObserver(stop)
            return result
        } catch let error {
            return ObservableValue(error: SubsequentObservableValueFailed(subsequentError: error))
        }
    }
    
    private func stop() {
        transform?.fail(ObservableValueWasDisposed())
        for subscription in transform?.subscriptions ?? [] {
            subscription.cancel()
        }
        transform = nil
    }
    
    private func onLeftChanged(_ leftValue: Left) {
        do {
            transform?.mutate(operation(leftValue, try right.unwrap()))
        } catch let error {
            transform?.fail(SubsequentObservableValueFailed(subsequentError: error))
        }
    }
    
    private func onRightChanged(_ rightValue: Right) {
        do {
            transform?.mutate(operation(try left.unwrap(), rightValue))
        } catch let error {
            transform?.fail(SubsequentObservableValueFailed(subsequentError: error))
        }
    }
    
    private func onTerminated(error: Error) {
        transform?.fail(SubsequentObservableValueFailed(subsequentError: error))
    }
    
    private let left: ObservableValue<Left>
    private let right: ObservableValue<Right>
    private let operation: (Left, Right) -> Result
    private var transform: Transformation<Result>?
}

private struct Transformation<T> {
    let mutate: Consumer<T>
    let fail: Consumer<Error>
    let subscriptions: [Cancelable]
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
