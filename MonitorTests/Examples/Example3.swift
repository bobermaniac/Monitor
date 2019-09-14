import Foundation
import Monitor
import XCTest

final class Example3: XCTestCase {
    private weak var textField: TextField?
    private weak var networkService: NetworkService?

    override func tearDown() {
        XCTAssertNil(textField)
        XCTAssertNil(networkService)
    }

    func test() {
        let mainThreadDispatcher = ManualDispatcher(name: "main")
        let textField = TextField()
        var output = [] as [String]
        let networkService = NetworkService(dispatcher: mainThreadDispatcher)
        var token: Vanishable?

        mainThreadDispatcher.sync(flags: .barrier) {
            token = textField.changed
                .filter { $0.count > 1 }
                .debounce(timeout: 3, dispatcher: mainThreadDispatcher)
                .distinct()
                .rewireSwitch(transform: networkService.search(text:))
                .observe(ephemeral: { output.append($0) }, terminal: { output.append("stop") })
            token?.vanished.execute { _ in
                token = nil
            }
        }

        // Second 0: type
        mainThreadDispatcher.sync(flags: .barrier) { textField.type(substring: "1" ) }
        // No task scheduled because result was filtered
        XCTAssertFalse(mainThreadDispatcher.dispatchNext(timeInterval: 5))
        // Second 6: type more symbols
        mainThreadDispatcher.sync(flags: .barrier) { textField.type(substring: "2" ) }
        // Now debounce was scheduled for 3 seconds
        XCTAssertTrue(mainThreadDispatcher.dispatchNext(timeInterval: 2))
        // Second 8: Debounce was rescheduled
        mainThreadDispatcher.sync(flags: .barrier) { textField.type(substring: "3" ) }
        // And invoked
        XCTAssertTrue(mainThreadDispatcher.dispatchNext(timeInterval: 3))
        // Second 11: Now search request is pending for responce
        XCTAssertTrue(mainThreadDispatcher.dispatchNext(timeInterval: 1))
        // Second 12: User enters another symbols and it cancels search request
        mainThreadDispatcher.sync(flags: .barrier) { textField.type(substring: "4" ) }
        // Second 15: Debounce refires and cancels previous task
        XCTAssertTrue(mainThreadDispatcher.dispatchNext(timeInterval: 3))
        // Second 20: Network responce received
        XCTAssertTrue(mainThreadDispatcher.dispatchNext(timeInterval: 5))
        // Now user types more symbols
        mainThreadDispatcher.sync(flags: .barrier) { textField.type(substring: "5" ) }
        // Second 23: debounce completes
        XCTAssertTrue(mainThreadDispatcher.dispatchNext(timeInterval: 3))
        // Second 28: result received
        XCTAssertTrue(mainThreadDispatcher.dispatchNext(timeInterval: 5))
        // Now user types more symbols
        mainThreadDispatcher.sync(flags: .barrier) { textField.type(substring: "6" ) }
        // Second 31: debounce completes
        XCTAssertTrue(mainThreadDispatcher.dispatchNext(timeInterval: 3))
        // Second 32: user exit while network request is still pending
        XCTAssertTrue(mainThreadDispatcher.dispatchNext(timeInterval: 1))
        mainThreadDispatcher.sync(flags: .barrier) { token?.cancel() }

        // Now all tasks done and nothing more scheduled
        XCTAssertFalse(mainThreadDispatcher.dispatchNext(timeInterval: 999))

        XCTAssertEqual(output, ["1234 found", "12345 found"])
        XCTAssertEqual(networkService.scheduledSearchs, ["123", "1234", "12345", "123456"])
        XCTAssertEqual(networkService.completedSearchs, ["1234", "12345"])
        XCTAssertEqual(networkService.canceledSearchs, ["123", "123456"])

        self.networkService = networkService
        self.textField = textField
    }
}

private final class TextField {
    deinit {
        changing.complete()
    }

    func type(substring: String) {
        buffer += substring
        changing.next(event: buffer)
    }

    private var buffer: String = ""

    var changed: Observable<String> {
        return changing.observable
    }

    private let changing = EventSource(of: String.self)
}

private final class NetworkService {
    init(dispatcher: Dispatching & DelayedDispatching) {
        self.dispatcher = dispatcher
    }

    func search(text: String) -> Future<String> {
        let (future, feed) = Future.make(of: Never.self, String.self)
        scheduledSearchs.append(text)
        let operation = dispatcher.async(after: 5, flags: .barrier) {
            self.completedSearchs.append(text)
            feed.push(terminal: "\(text) found")
        }
        feed.addCancelationObserver {
            if !self.completedSearchs.contains(text) {
                self.canceledSearchs.append(text)
            }
            operation.cancel()
        }
        return future
    }

    private let dispatcher: Dispatching & DelayedDispatching

    var scheduledSearchs = [] as [String]
    var completedSearchs = [] as [String]
    var canceledSearchs = [] as [String]
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
