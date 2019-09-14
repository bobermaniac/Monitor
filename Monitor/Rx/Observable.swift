import Foundation

public struct EventSource<T> {
    public init(of type: T.Type = T.self) {
        (observable, feed) = Monitor.make()
    }

    public func next(event: T) {
        feed.push(ephemeral: event)
    }

    public func complete() {
        feed.push(terminal: ())
    }

    public func canceled(callback: @escaping Action) {
        feed.addCancelationObserver(onCancel: callback)
    }

    public let observable: Observable<T>

    private let feed: Feed<T, Void>
}

public typealias Observable<T> = Monitor<T, Void>

public struct FailableEventSource<T> {
    public init(of type: T.Type = T.self) {
        (observable, feed) = Monitor.make()
    }

    public func next(event: T) {
        feed.push(ephemeral: event)
    }

    public func complete() {
        feed.push(terminal: .left(()))
    }

    public func fail(with error: Error) {
        feed.push(terminal: .right(error))
    }

    public func canceled(callback: @escaping Action) {
        feed.addCancelationObserver(onCancel: callback)
    }

    public let observable: FailableObservable<T>

    private let feed: Feed<T, Either<Void, Error>>
}

public typealias FailableObservable<T> = Monitor<T, Either<Void, Error>>

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
