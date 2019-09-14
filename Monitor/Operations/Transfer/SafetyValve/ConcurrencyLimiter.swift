import Foundation

public final class ConcurrencyLimiter: SafetyValve {
    public init(maxOperationsCount: UInt64, threadSafetyStrategy: ThreadSafetyStrategy) {
        self.numberOfActiveOperation = 0
        self.maxOperationsCount = maxOperationsCount
        self.threadSafetyStrategy = threadSafetyStrategy
    }
    
    public func invocationSheduled() {
        threadSafetyStrategy.interlockedWrite { self.numberOfActiveOperation += 1 }
    }
    
    public func invocationComplete() {
        threadSafetyStrategy.interlockedWrite { self.numberOfActiveOperation -= 1 }
    }
    
    public var isLittered: Bool {
        return threadSafetyStrategy.interlockedRead { return numberOfActiveOperation >= maxOperationsCount }
    }
    
    private var numberOfActiveOperation: UInt64
    private let maxOperationsCount: UInt64
    private let threadSafetyStrategy: ThreadSafetyStrategy
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
