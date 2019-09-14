import Foundation

public struct Promise<T> {
    public init(of _: T.Type = T.self) {
        (future, feed) = Monitor.make()
    }

    public let future: Future<T>

    public func resolve(with payload: T) {
        feed.push(terminal: payload)
    }

    public func canceled(callback: @escaping Action) {
        feed.addCancelationObserver(onCancel: callback)
    }

    private let feed: Feed<Never, T>
}

public typealias Future<T> = Monitor<Never, T>

public struct FailablePromise<T> {
    public init(of _: T.Type = T.self) {
        (future, feed) = Monitor.make()
    }

    public let future: FailableFuture<T>

    public func resolve(with payload: T) {
        feed.push(terminal: .left(payload))
    }

    public func reject(with error: Error) {
        feed.push(terminal: .right(error))
    }

    public func canceled(callback: @escaping Action) {
        feed.addCancelationObserver(onCancel: callback)
    }

    private let feed: Feed<Never, Either<T, Error>>
}

public typealias FailableFuture<T> = Monitor<Never, Either<T, Error>>

public extension Monitor where Ephemeral == Never {
    func resolved(handler: @escaping Consumer<Terminal>) -> Vanishable {
        return observe(ephemeral: pass, terminal: handler)
    }
    
    func then<U>(transform: @escaping Transform<Terminal, U>) -> Future<U> {
        return map(ephemeral: identity, terminal: transform)
    }
    
    func then<U>(transform: @escaping Transform<Terminal, Future<U>>) -> Future<U> {
        return extend(using: transform)
    }
}

public extension Monitor where Ephemeral == Never, Terminal: Result {
    func resolved(handler: @escaping Consumer<Terminal.T>) -> Vanishable {
        return observe(ephemeral: pass) { terminal in
            if let payload = try? terminal.unwrap() {
                handler(payload)
            }
        }
    }
    
    func rejected(handler: @escaping Consumer<Error>) -> Vanishable {
        return observe(ephemeral: pass) { terminal in
            do {
                _ = try terminal.unwrap()
            }
            catch let error {
                handler(error)
            }
        }
    }
    
    func fulfilled(resolved resolveHandler: @escaping Consumer<Terminal.T>,
                   rejected rejectedHandler: @escaping Consumer<Error>) -> Vanishable {
        return observe(ephemeral: pass) { terminal in
            do {
                resolveHandler(try terminal.unwrap())
            } catch let error {
                rejectedHandler(error)
            }
        }
    }
    
    func then<U>(transform: @escaping (Terminal.T) throws -> U) -> FailableFuture<U> {
        return map(ephemeral: identity) { terminal in
            return Either { try transform(try terminal.unwrap()) }
        }
    }
    
    func then<U>(transform: @escaping (Terminal.T) throws -> FailableFuture<U>) -> FailableFuture<U> {
        return extend { terminal in
            do {
                return try transform(try terminal.unwrap())
            } catch let error {
                return FailableFuture(terminal: Either(error: error))
            }
        }
    }
    
    func handle(transform: @escaping Transform<Error, Terminal.T>) -> Future<Terminal.T> {
        return map(ephemeral: identity) { terminal in
            do {
                return try terminal.unwrap()
            } catch let error {
                return transform(error)
            }
        }
    }
    
    func handle(transform: @escaping Transform<Error, Future<Terminal.T>>) -> Future<Terminal.T> {
        return extend { terminal in
            do {
                return Future(terminal: try terminal.unwrap())
            } catch let error {
                return transform(error)
            }
        }
    }
    
    func handle(transform: @escaping (Error) throws -> Terminal.T) -> FailableFuture<Terminal.T> {
        return map(ephemeral: identity) { terminal in
            do {
                return Either(result: try terminal.unwrap())
            } catch let error {
                return Either { try transform(error) }
            }
        }
    }
    
    func handle(transform: @escaping (Error) throws -> FailableFuture<Terminal.T>) -> FailableFuture<Terminal.T> {
        return extend { terminal in
            do {
                return FailableFuture(terminal: Either(result: try terminal.unwrap()))
            } catch let error {
                do {
                    return try transform(error)
                } catch let finalError {
                    return FailableFuture(terminal: Either(error: finalError))
                }
            }
        }
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
