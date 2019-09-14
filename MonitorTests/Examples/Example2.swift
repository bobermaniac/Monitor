import Foundation
import Monitor
import XCTest

final class Example2: XCTestCase {
    func test() {
        var log = [] as [String]

        let dispatcher = ManualDispatcher(name: "")
        let networkManager = NetworkManager(dispatcher: dispatcher)
        let (loadedIds, loadedIdsFeed) = Monitor.make(of: String.self, Void.self)
        let token = loadedIds.enumerate()
            .reduceFlatMap(accumulator: [] as [Book],
                       ephemeralTransform: { networkManager.downloadBook(bookId: $0.1, tag: $0.0) },
                       intermediateTerminalReducer: { books, book in books + [book] },
                       terminalReducer: { books, _ in books })
            .gatherProgress()
            .observe(ephemeral: { log.append("Progress: \($0.overallProgress) (\($0.partialProgress.count) tasks)") },
                     terminal: { log.append($0.description) })

        loadedIdsFeed.push(ephemeral: "Wow")
        loadedIdsFeed.push(ephemeral: "Cool")
        loadedIdsFeed.push(ephemeral: "Finita")
        loadedIdsFeed.push(ephemeral: "Alpha")
        loadedIdsFeed.push(ephemeral: "Bravo")
        loadedIdsFeed.push(ephemeral: "Crarlie")
        loadedIdsFeed.push(terminal: ())
        while dispatcher.dispatchNext() { }

        token.cancel()
    }
}

private extension Monitor where Ephemeral == String, Terminal == Void {
    func enumerate() -> Monitor<(Int, String), Void> {
        return scan(accumulator: (0, ""),
                      ephemeralReducer: { acc, next in (acc.0 + 1, next) },
                      terminalReducer: second)
    }
}

private extension Monitor where Ephemeral == (Int, Double), Terminal == [Book] {
    func gatherProgress() -> Monitor<OverallProgress, [Book]> {
        return scan(accumulator: OverallProgress(partialProgress: [:]),
                      ephemeralReducer: { $0.update(index: $1.0, progress: $1.1) },
                      terminalReducer: second)
    }
}

private extension NetworkManager {
    func downloadBook(bookId: String, tag: Int) -> Monitor<(Int, Double), Book> {
        return downloadBook(bookId: bookId).map(ephemeral: { (tag, $0) }, terminal: { $0 })
    }
}

struct OverallProgress {
    let partialProgress: [Int: Double]

    func update(index: Int, progress: Double) -> OverallProgress {
        var newProgress = partialProgress
        newProgress[index] = progress
        return OverallProgress(partialProgress: newProgress)
    }

    var overallProgress: Double {
        return partialProgress.values.reduce(0) { $0 + $1 } / Double(partialProgress.count)
    }
}

struct Book {
    let id: String
    let title: String
}

private final class NetworkManager {
    init(dispatcher: Dispatching) {
        self.dispatcher = dispatcher
    }

    func downloadBook(bookId: String) -> Monitor<Double, Book> {
        let id = arc4random()
        let (result, feed) = Monitor.make(of: Double.self, Book.self)
        downloads[id] = (bookId, 0.0, feed)
        feed.addCancelationObserver { [weak self] in
            self?.downloads[id] = nil
        }
        if downloads.count == 1 {
            dispatcher.async(flags: [.barrier], execute: downloadNextChunk)
        }
        return result
    }

    private func downloadNextChunk() {
        guard let key = downloads.keys.randomElement() else { return }
        let download = downloads[key]!
        let newProgress = download.1 + 0.1
        if newProgress >= 1 {
            download.2.push(terminal: Book(id: download.0, title: "Book title: \(download.0)"))
        } else {
            download.2.push(ephemeral: newProgress)
            downloads[key] = (download.0, newProgress, download.2)
        }
        dispatcher.async(flags: [.barrier], execute: downloadNextChunk)
    }

    private let dispatcher: Dispatching
    private var downloads = [:] as [UInt32:(String, Double, Feed<Double, Book>)]
}

private func second<T1, T2>(_: T1, _ p2: T2) -> T2 {
    return p2
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
