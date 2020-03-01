import Foundation
import Monitor
import XCTest

final class Example7: XCTestCase {
    func test_all_withoutFailFast() throws {
        let dispatcher = ManualDispatcher(name: "supplimentary", simultaneousOperationCount: 1)
        
        let shelf1 = DummyBookshelf(dispatcher: dispatcher, booksCount: 3, terminal: ())
        let shelf2 = DummyBookshelf(dispatcher: dispatcher, booksCount: 5, terminal: Bill())
        
        var result: ([Book], (Void, Bill))?
        let lookingForBooks = dispatcher.sync(flags: .barrier) {
            all(shelf1.search(), shelf2.search())
                .scan(accumulator: [], ephemeralReducer: { $0 + [$1] }, terminalReducer: { ($0, $1) })
                .observe(ephemeral: { _ in }, terminal: { result = $0 })
        }
        
        [dispatcher].XCTAwait(result != nil, on: dispatcher)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0.count, 8)
    
        lookingForBooks.cancel()
        
        [dispatcher].XCTAwait(shelf1.numberOfAbandonedDetected == 0)
        [dispatcher].XCTAwait(shelf2.numberOfAbandonedDetected == 0)
    }
    
    func test_all_withFailFast() throws {
        let dispatcher = ManualDispatcher(name: "supplimentary", simultaneousOperationCount: 1)
        
        let shelf1 = DummyBookshelf(dispatcher: dispatcher,
                                    booksCount: 10,
                                    terminal: Either<Void, Error>.left(()))
        let shelf2 = DummyBookshelf(dispatcher: dispatcher,
                                     booksCount: 2,
                                     terminal: Either<Void, Error>.right(Bill()))
        
        var result: ([Book], Either<(Void, Void), Error>)?
        let lookingForBooks = dispatcher.sync(flags: .barrier) {
            all(shelf1.search(), shelf2.search())
                .scan(accumulator: [], ephemeralReducer: { $0 + [$1] }, terminalReducer: { ($0, $1) })
                .observe(ephemeral: { _ in }, terminal: { result = $0 })
        }
        
        [dispatcher].XCTAwait(result != nil, on: dispatcher)
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result?.1.unwrapError())
        XCTAssertEqual(result?.0.count, 5)
    
        lookingForBooks.cancel()
        
        [dispatcher].XCTAwait(shelf1.numberOfAbandonedDetected == 1)
        [dispatcher].XCTAwait(shelf2.numberOfAbandonedDetected == 0)
    }
}

private struct Book { }

private struct Bill: Error { }

private final class DummyBookshelf<T> {
    private(set) var numberOfAbandonedDetected = 0
    
    init(dispatcher: Dispatching, booksCount: Int, terminal: T) {
        self.dispatcher = dispatcher
        self.booksCount = booksCount
        self.terminal = terminal
    }
    
    func search() -> Monitor<Book, T> {
        let (monitor, signal) = Signal.make(of: Book.self, T.self, boundTo: dispatcher)
        rerun(into: signal, remainingCount: booksCount)
        return monitor
    }
    
    private func rerun(into signal: Signal<Book, T>, remainingCount: Int) {
        dispatcher.async(flags: [.barrier], execute: { self.run(into: signal, remainingCount: remainingCount) })
    }
    
    private func run(into signal: Signal<Book, T>, remainingCount: Int) {
        if signal.abandoned {
            numberOfAbandonedDetected += 1
            return
        }
        let newRemainingCount = remainingCount - 1
        if newRemainingCount < 0 {
            signal.terminate(with: terminal)
        } else {
            signal.emit(ephemeral: Book())
            rerun(into: signal, remainingCount: newRemainingCount)
        }
    }
    
    private let dispatcher: Dispatching
    private let booksCount: Int
    private let terminal: T
}

// Copyright (C) 2020 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
