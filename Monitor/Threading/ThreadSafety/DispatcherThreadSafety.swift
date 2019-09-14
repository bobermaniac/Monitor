import Foundation

public struct DispatcherThreadSafetyStrategy: ThreadSafetyStrategy {
    public init(dispatcher: Dispatching) {
        self.dispatcher = dispatcher
    }
    
    public func interlockedRead<T>(_ block: () throws -> T) rethrows -> T {
        dispatcher.assertNotIsCurrent()
        return try dispatcher.sync(flags: [], execute: block)
    }
    
    public func interlockedWrite(_ block: @escaping Action) {
        dispatcher.assertNotIsCurrent()
        dispatcher.async(flags: [.barrier], execute: block)
    }
    
    public func interlockedReadWrite<T>(_ block: () throws -> T) rethrows -> T {
        dispatcher.assertNotIsCurrent()
        return try dispatcher.sync(flags: [.barrier], execute: block)
    }
    
    private let dispatcher: Dispatching
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
