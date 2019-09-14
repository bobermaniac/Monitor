import Foundation

public struct MutableValue<T> {
    public init(_ value: T) {
        (observableValue, mutate, fail) = ObservableValue.make(initialValue: value)
    }
    
    public var value: T {
        get {
            return try! observableValue.unwrap()
        }
        nonmutating set {
            mutate(newValue)
        }
    }
    
    public let observableValue: ObservableValue<T>

    public var observable: Monitor<T, Error> {
        return observableValue.observable
    }
    
    private let mutate: Consumer<T>
    private let fail: Consumer<Error>
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
