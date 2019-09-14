import Foundation

public func any<T>(of monitors: [Monitor<Never, T>]) -> Monitor<Never, T> {
    return mix(monitors, factory: AnyFactory())
}

private struct AnyFactory<T>: MonitorHomogeneousMixingFactory {
    typealias Compressor = AnyCompressor<T>
    
    func make(count: Int, feed: Feed<Never, T>) -> AnyCompressor<T> {
        return AnyCompressor(feed: feed)
    }
}

private final class AnyCompressor<T>: MonitorHomogeneousMixing {
    typealias InputEphemeral = Never
    typealias InputTerminal = T
    typealias OutputEphemeral = Never
    typealias OutputTerminal = T
    
    init(feed: Feed<Never, T>) {
        self.feed = feed
    }
    
    func eat(ephemeral: Never, at _: Int) { }
    
    func eat(terminal: T, at _: Int) {
        feed.push(terminal: terminal)
    }
    
    func cancel(sourceSubscriptions: [Cancelable]) {
        sourceSubscriptions.forEach { $0.cancel() }
    }

    private let feed: Feed<Never, T>
}

public struct AggregatedError: Error {
    public init(errors: [Error]) {
        self.errors = errors
    }

    public let errors: [Error]
}

public func any<T: Result>(of monitors: [Monitor<Never, T>],
                           errorsTransform: @escaping Transform<[Error], Error> = AggregatedError.init) -> Monitor<Never, Either<T.T, Error>> {
    return mix(monitors, factory: FailableAnyFactory(errorsTransform: errorsTransform))
}

private struct FailableAnyFactory<T: Result>: MonitorHomogeneousMixingFactory {
    typealias Compressor = FailableAnyCompressor<T>

    public init(errorsTransform: @escaping Transform<[Error], Error>) {
        self.errorsTransform = errorsTransform
    }

    func make(count: Int, feed: Feed<Never, Either<T.T, Error>>) -> FailableAnyCompressor<T> {
        return FailableAnyCompressor(errorsTransform: errorsTransform, pendingCount: count, feed: feed)
    }

    private let errorsTransform: Transform<[Error], Error>
}

private final class FailableAnyCompressor<T: Result>: MonitorHomogeneousMixing {
    typealias InputEphemeral = Never
    typealias InputTerminal = T
    typealias OutputEphemeral = Never
    typealias OutputTerminal = Either<T.T, Error>
    
    init(errorsTransform: @escaping Transform<[Error], Error>,
         pendingCount: Int,
         feed: Feed<Never, Either<T.T, Error>>) {
        self.errorsTransform = errorsTransform
        self.pendingCount = pendingCount
        self.feed = feed
    }
    
    func eat(ephemeral: Never, at _: Int) { }
    
    func eat(terminal: T, at _: Int) {
        do {
            feed.push(terminal: .left(try terminal.unwrap()))
        } catch let error {
            errors.append(error)
            if pendingCount == errors.count {
                feed.push(terminal: .right(errorsTransform(errors)))
            }
        }
    }
    
    func cancel(sourceSubscriptions: [Cancelable]) {
        sourceSubscriptions.forEach { $0.cancel() }
    }

    private let errorsTransform: Transform<[Error], Error>
    private var pendingCount: Int
    private var errors = [] as [Error]
    private let feed: Feed<Never, Either<T.T, Error>>
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
