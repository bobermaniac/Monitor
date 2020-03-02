import Foundation
import XCTest

final class ManualDispatcherTests: XCTestCase {
    func test_syncInvocation_noFlags_runs_noDispatch() {
        let dispatcher = ManualDispatcher()
        var executed = false
        dispatcher.sync(flags: []) {
            dispatcher.assertIsCurrent(flags: [])
            executed = true
        }
        XCTAssertTrue(executed)
    }

    func test_syncInvocation_barrier_runs_noDispatch() {
        let dispatcher = ManualDispatcher()
        var executed = false
        dispatcher.sync(flags: .barrier) {
            dispatcher.assertIsCurrent(flags: .barrier)
            executed = true
        }
        XCTAssertTrue(executed)
    }

    func test_asyncInvocation_noFlags_runs_whenDispatched() {
        let dispatcher = ManualDispatcher()
        var executed = false
        dispatcher.async(flags: []) {
            dispatcher.assertIsCurrent(flags: [])
            executed = true
        }
        XCTAssertFalse(executed)
        XCTAssertTrue(dispatcher.dispatchNext())
        XCTAssertTrue(executed)
        XCTAssertFalse(dispatcher.dispatchNext())
    }

    func test_asyncInvocation_barrier_runs_whenDispatched() {
        let dispatcher = ManualDispatcher()
        var executed = false
        dispatcher.async(flags: .barrier) {
            dispatcher.assertIsCurrent(flags: .barrier)
            executed = true
        }
        XCTAssertFalse(executed)
        XCTAssertTrue(dispatcher.dispatchNext())
        XCTAssertTrue(executed)
        XCTAssertFalse(dispatcher.dispatchNext())
    }

    func test_asyncAfterInvocation_noFlags_run_whenDispatched_whenTimeout() {
        let dispatcher = ManualDispatcher()
        var executed = false
        dispatcher.async(after: 2, flags: []) {
            dispatcher.assertIsCurrent(flags: [])
            executed = true
        }

        XCTAssertFalse(executed)
        XCTAssertTrue(dispatcher.dispatchNext(timeInterval: 1))
        XCTAssertFalse(executed)
        XCTAssertTrue(dispatcher.dispatchNext(timeInterval: 1))
        XCTAssertTrue(executed)
        XCTAssertFalse(dispatcher.dispatchNext(timeInterval: 1))
    }

    func test_asyncAfterInvocation_noFlags_doesNotRun_whenCanceled_whenDispatched_whenTimeout() {
        let dispatcher = ManualDispatcher()
        var executed = false
        let token = dispatcher.async(after: 2, flags: []) {
            dispatcher.assertIsCurrent(flags: [])
            executed = true
        }

        XCTAssertFalse(executed)
        XCTAssertTrue(dispatcher.dispatchNext(timeInterval: 1))
        XCTAssertFalse(executed)

        dispatcher.sync(flags: [.barrier]) {
            token.cancel()
        }

        XCTAssertFalse(dispatcher.dispatchNext(timeInterval: 1))
        XCTAssertFalse(executed)
    }

    func test_asyncAfterInvocation_andAsyncInvocation_invokesInProperOrder() {
        let dispatcher = ManualDispatcher()
        var executedAfter = false
        var executedAsync = false
        dispatcher.async(after: 2, flags: []) {
            dispatcher.assertIsCurrent(flags: [])
            executedAfter = true
        }

        XCTAssertFalse(executedAfter)

        dispatcher.async(flags: []) {
            executedAsync = true
        }

        XCTAssertTrue(dispatcher.dispatchNext(timeInterval: 1))
        XCTAssertTrue(executedAsync)
        XCTAssertFalse(executedAfter)
        XCTAssertTrue(dispatcher.dispatchNext(timeInterval: 1))
        XCTAssertTrue(executedAfter)
        XCTAssertFalse(dispatcher.dispatchNext(timeInterval: 1))
    }

    func test_asyncAfterInvocation_andAsyncInvocation_simultaneously_invokesAfterFirst() {
        let dispatcher = ManualDispatcher()
        var executedAfter = false
        var executedAsync = false
        dispatcher.async(after: 2, flags: []) {
            dispatcher.assertIsCurrent(flags: [])
            executedAfter = true
        }

        XCTAssertFalse(executedAfter)

        XCTAssertTrue(dispatcher.dispatchNext(timeInterval: 1))
        dispatcher.async(flags: []) {
            executedAsync = true
        }
        XCTAssertFalse(executedAfter)
        XCTAssertFalse(executedAsync)

        XCTAssertTrue(dispatcher.dispatchNext(timeInterval: 1))
        XCTAssertTrue(executedAfter)
        XCTAssertFalse(executedAsync)

        XCTAssertTrue(dispatcher.dispatchNext(timeInterval: 1))
        XCTAssertTrue(executedAsync)

        XCTAssertFalse(dispatcher.dispatchNext(timeInterval: 1))
    }

    func test_twoAsyncAfter_executingSumultaneously_executesInOrderOfScheduling() {
        let dispatcher = ManualDispatcher()
        var executed1 = false
        var executed2 = false

        dispatcher.async(after: 1, flags: [], execute: { executed1 = true })
        dispatcher.async(after: 1, flags: [], execute: { executed2 = true })

        XCTAssertFalse(executed1)
        XCTAssertFalse(executed2)

        XCTAssertTrue(dispatcher.dispatchNext(timeInterval: 1))

        XCTAssertTrue(executed1)
        XCTAssertFalse(executed2)

        XCTAssertTrue(dispatcher.dispatchNext(timeInterval: 1))
        XCTAssertTrue(executed2)

        XCTAssertFalse(dispatcher.dispatchNext(timeInterval: 1))
    }

    func test_overlappingAsyncAfter_executesInProperOrder() {
        let dispatcher = ManualDispatcher()
        var executed = [false, false, false, false]

        dispatcher.async(after: 4, flags: [], execute: { executed[3] = true } )
        dispatcher.async(after: 2, flags: [], execute: { executed[1] = true } )
        dispatcher.async(after: 1, flags: [], execute: { executed[0] = true } )
        dispatcher.async(after: 3, flags: [], execute: { executed[2] = true } )

        XCTAssertEqual(executed, [false, false, false, false])

        XCTAssertTrue(dispatcher.dispatchNext(timeInterval: 1))
        XCTAssertEqual(executed, [true, false, false, false])

        XCTAssertTrue(dispatcher.dispatchNext(timeInterval: 1))
        XCTAssertEqual(executed, [true, true, false, false])

        XCTAssertTrue(dispatcher.dispatchNext(timeInterval: 1))
        XCTAssertEqual(executed, [true, true, true, false])

        XCTAssertTrue(dispatcher.dispatchNext(timeInterval: 1))
        XCTAssertEqual(executed, [true, true, true, true])

        XCTAssertFalse(dispatcher.dispatchNext(timeInterval: 1))
    }

    func test_multipleAsyncOperations() {
        let dispatcher = ManualDispatcher(simultaneousOperationCount: 2)
        var executed1 = false
        var executed2 = false
        var executed3 = false

        dispatcher.async(flags: [], execute: { executed1 = true })
        dispatcher.async(flags: [], execute: { executed2 = true })
        dispatcher.async(flags: [], execute: { executed3 = true })

        XCTAssertFalse(executed1)
        XCTAssertFalse(executed2)
        XCTAssertFalse(executed3)

        XCTAssertTrue(dispatcher.dispatchNext())
        XCTAssertTrue(executed1)
        XCTAssertTrue(executed2)
        XCTAssertFalse(executed3)

        XCTAssertTrue(dispatcher.dispatchNext())
        XCTAssertTrue(executed3)

        XCTAssertFalse(dispatcher.dispatchNext())
    }

    func test_multipleAsyncOperations_withBarrier() {
        let dispatcher = ManualDispatcher(simultaneousOperationCount: 2)
        var executed1 = false
        var executed2 = false
        var executed3 = false

        dispatcher.async(flags: [], execute: { executed1 = true })
        dispatcher.async(flags: .barrier, execute: { executed2 = true })
        dispatcher.async(flags: [], execute: { executed3 = true })

        XCTAssertFalse(executed1)
        XCTAssertFalse(executed2)
        XCTAssertFalse(executed3)

        XCTAssertTrue(dispatcher.dispatchNext())
        XCTAssertTrue(executed1)
        XCTAssertFalse(executed2)
        XCTAssertFalse(executed3)

        XCTAssertTrue(dispatcher.dispatchNext())
        XCTAssertTrue(executed2)
        XCTAssertFalse(executed3)

        XCTAssertTrue(dispatcher.dispatchNext())
        XCTAssertTrue(executed3)

        XCTAssertFalse(dispatcher.dispatchNext())
    }

    func test_multipleAsyncOperations_withSyncInConcurrency() {
        let dispatcher = ManualDispatcher(simultaneousOperationCount: 3)
        var executed1 = false
        var executed2 = false
        var executed3 = false

        dispatcher.async(flags: [], execute: { executed1 = true })
        dispatcher.async(flags: [], execute: { executed2 = true })
        dispatcher.sync(flags: [], execute: { executed3 = true })

        XCTAssertTrue(executed1)
        XCTAssertTrue(executed2)
        XCTAssertTrue(executed3)
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
