import Foundation
import Monitor
import XCTest

final class Example4: XCTestCase {
    func test() {
        let mainDispatcher = ManualDispatcher()
        let concurrentDownloadDispatcher = ManualDispatcher(name: "download", simultaneousOperationCount: 8)
        let concurrentDecodeDispatcher = ManualDispatcher(name: "decode", simultaneousOperationCount: 2)
        let downloader = AsyncDownloader(dispatcher: concurrentDownloadDispatcher)
        let decoder = AsyncDecoder(dispatcher: concurrentDecodeDispatcher)

        let (fileIds, fileIdsFeed) = Monitor.make(of: String.self, Void.self)
        let token = mainDispatcher.sync(flags: .barrier) {
            return fileIds.rewire(ephemeral: { downloader.download(fileId: $0, resolveDispatcher: mainDispatcher) })
                .rewire(ephemeral: { decoder.decode(data: $0, resolveDispatcher: mainDispatcher) })
                .scan(accumulator: [] as [Image],
                      ephemeralReducer: { (acc: [Image], next: Image) in acc + [next] },
                      terminalReducer: { $1 })
                .observe(ephemeral: { print("Images: \($0)") }, terminal: { print("All images") })
        }

        mainDispatcher.sync(flags: [.barrier]) {
            for i in 0..<100 {
                fileIdsFeed.push(ephemeral: "file_\(i)")
            }
        }

        for _ in 0...200 {
            mainDispatcher.dispatchNext(timeInterval: 1)
            concurrentDownloadDispatcher.dispatchNext(timeInterval: 1)
            concurrentDecodeDispatcher.dispatchNext(timeInterval: 1)
        }

        mainDispatcher.sync(flags: .barrier) {
            fileIdsFeed.push(terminal: ())
            token.cancel()
        }
    }
}

private struct ImageData { }

private struct Image { }

private final class AsyncDownloader {
    init(dispatcher: Dispatching & DelayedDispatching) {
        self.dispatcher = dispatcher
    }

    func download(fileId: String, resolveDispatcher: Dispatching) -> Future<ImageData> {
        return BackgroundTask(task: { self.internalDownload(fileId: fileId) },
                              executeOn: dispatcher)
            .run(resolveDispatcher: resolveDispatcher)
    }

    private func internalDownload(fileId: String) -> Future<ImageData> {
        dispatcher.assertIsCurrent(flags: [])
        let result = Promise<ImageData>()

        dispatcher.async(after: TimeInterval(arc4random() % 3 + 3), flags: []) {
            result.resolve(with: ImageData())
        }

        return result.future
    }

    private let dispatcher: Dispatching & DelayedDispatching
}

private final class AsyncDecoder {
    init(dispatcher: Dispatching & DelayedDispatching) {
        self.dispatcher = dispatcher
    }

    func decode(data: ImageData, resolveDispatcher: Dispatching) -> Future<Image> {
        return BackgroundTask(task: { self.internalDecode(data: data) },
                              executeOn: dispatcher)
            .run(resolveDispatcher: resolveDispatcher)
    }

    private func internalDecode(data: ImageData) -> Future<Image> {
        dispatcher.assertIsCurrent(flags: [])
        let result = Promise<Image>()

        dispatcher.async(after: TimeInterval(arc4random() % 2 + 1), flags: []) {
            result.resolve(with: Image())
        }

        return result.future
    }

    private let dispatcher: Dispatching & DelayedDispatching
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
