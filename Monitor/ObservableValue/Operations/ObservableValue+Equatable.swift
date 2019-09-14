import Foundation

extension ObservableValue where T: Equatable {
    public static func == (lhs: ObservableValue<T>, rhs: ObservableValue<T>) -> ObservableValue<Bool> {
        return ObservableValueBinaryOperation(left: lhs, right: rhs, operation: ==).run()
    }
    
    public static func != (lhs: ObservableValue<T>, rhs: ObservableValue<T>) -> ObservableValue<Bool> {
        return ObservableValueBinaryOperation(left: lhs, right: rhs, operation: !=).run()
    }

    public static func == (lhs: ObservableValue<T>, rhs: T) -> ObservableValue<Bool> {
        return ObservableValueUnaryOperation(value: lhs, operation: { $0 == rhs }).run()
    }

    public static func != (lhs: ObservableValue<T>, rhs: T) -> ObservableValue<Bool> {
        return ObservableValueUnaryOperation(value: lhs, operation: { $0 != rhs }).run()
    }

    public static func == (lhs: T, rhs: ObservableValue<T>) -> ObservableValue<Bool> {
        return ObservableValueUnaryOperation(value: rhs, operation: { lhs == $0 }).run()
    }

    public static func != (lhs: T, rhs: ObservableValue<T>) -> ObservableValue<Bool> {
        return ObservableValueUnaryOperation(value: rhs, operation: { lhs != $0 }).run()
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
