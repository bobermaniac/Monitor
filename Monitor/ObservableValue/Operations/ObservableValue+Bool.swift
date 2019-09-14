import Foundation

extension ObservableValue where T == Bool {
    public static func &&(lhs: ObservableValue, rhs: ObservableValue) -> ObservableValue {
        return ObservableValueBinaryOperation(left: lhs, right: rhs, operation: and).run()
    }
    
    public static func ||(lhs: ObservableValue, rhs: ObservableValue) -> ObservableValue {
        return ObservableValueBinaryOperation(left: lhs, right: rhs, operation: or).run()
    }
    
    public static prefix func !(value: ObservableValue) -> ObservableValue {
        return ObservableValueUnaryOperation(value: value, operation: not).run()
    }
}

private func and(lhs: Bool, rhs: Bool) -> Bool {
    return lhs && rhs
}

private func or(lhs: Bool, rhs: Bool) -> Bool {
    return lhs || rhs
}

private func not(value: Bool) -> Bool {
    return !value
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
