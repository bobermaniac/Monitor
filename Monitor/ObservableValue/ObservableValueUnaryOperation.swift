import Foundation

public final class ObservableValueUnaryOperation<Input, Output> {
    public init(value: ObservableValue<Input>, operation: @escaping Transform<Input, Output>) {
        self.value = value
        self.operation = operation
    }
    
    public func run() -> ObservableValue<Output> {
        do {
            let (result, mutate, fail) = ObservableValue.make(initialValue: operation(try value.unwrap()))
            let cancelation = value.observable.observe(ephemeral: onValueChanged, terminal: onTerminated)
            transform = Transformation(mutate: mutate, fail: fail, subscription: cancelation)
            result.addLifetimeObserver(stop)
            return result
        } catch let error {
            return ObservableValue(error: SubsequentObservableValueFailed(subsequentError: error))
        }
    }
    
    private func stop() {
        transform?.fail(ObservableValueWasDisposed())
        transform?.subscription.cancel()
        transform = nil
    }
    
    private func onValueChanged(_ newValue: Input) {
        transform?.mutate(operation(newValue))
    }

    private func onTerminated(error: Error) {
        transform?.fail(SubsequentObservableValueFailed(subsequentError: error))
    }
    
    private let value: ObservableValue<Input>
    private let operation: Transform<Input, Output>
    private var transform: Transformation<Output>?
}

private struct Transformation<T> {
    let mutate: Consumer<T>
    let fail: Consumer<Error>
    let subscription: Cancelable
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
