import Foundation

public final class ReadPreferredReaderWriterLockThreadSafety: ThreadSafetyStrategy {
    public init() { }
    
    public func interlockedRead<T>(_ block: () throws -> T) rethrows -> T {
        enterReadLock()
        defer { exitReadLock() }
        return try block()
    }
    
    public func interlockedWrite(_ block: @escaping Action) {
        enterWriteLock()
        defer { exitWriteLock() }
        block()
    }
    
    public func interlockedReadWrite<T>(_ block: () throws -> T) rethrows -> T {
        enterWriteLock()
        defer { exitWriteLock() }
        return try block()
    }
    
    private func enterReadLock() {
        numberOfReadersMutex.lock()
        numberOfReaders += 1
        if numberOfReaders == 1 {
            writeAllowed.wait()
        }
        numberOfReadersMutex.unlock()
    }
    
    private func exitReadLock() {
        numberOfReadersMutex.lock()
        numberOfReaders -= 1
        if numberOfReaders == 0 {
            writeAllowed.signal()
        }
        numberOfReadersMutex.unlock()
    }
    
    private func enterWriteLock() {
        writeAllowed.wait()
    }
    
    private func exitWriteLock() {
        writeAllowed.signal()
    }
    
    private let writeAllowed = DispatchSemaphore(value: 1) // We can't use NSLock here because it can't be unlocked from another thread
    private let numberOfReadersMutex = NSLock()
    private var numberOfReaders: UInt = 0
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
