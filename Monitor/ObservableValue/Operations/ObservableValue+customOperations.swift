import Foundation

public extension ObservableValue {
    func apply<U>(fun: @escaping Transform<T, U>) -> ObservableValue<U> {
        return ObservableValueUnaryOperation(value: self, operation: fun).run()
    }
}

public func pow(_ lhs: ObservableValue<Double>, _ rhs: Double) -> ObservableValue<Double> {
    return lhs.apply(fun: { pow($0, rhs) })
}

public func sqrt<X: FloatingPoint>(_ value: ObservableValue<X>) -> ObservableValue<X> {
    return value.apply(fun: sqrt)
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
