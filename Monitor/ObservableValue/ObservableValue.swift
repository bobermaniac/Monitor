import Foundation

public final class ObservableValue<T> {
    public init(_ value: T) {
        self.payload = Either(result: value)
        (self.observable, self.feed) = Monitor.make()
    }
    
    public init(error: Error) {
        self.payload = Either(error: error)
        self.observable = Monitor(terminal: error)
        self.feed = Feed(monitor: observable,
                         ephemeralFeed: pass,
                         terminalFeed: pass,
                         disposeObserver: pass,
                         setDispatcher: pass)
    }
    
    deinit {
        feed.push(terminal: ObservableValueWasDisposed())
    }
    
    public let observable: Monitor<T, Error>
    
    public func unwrap() throws -> T {
        switch payload {
        case .left(let value):
            return value
        case .right(let error):
            throw error
        }
    }
    
    internal static func make(initialValue: T) -> (ObservableValue<T>, mutate: Consumer<T>, fail: Consumer<Error>) {
        let result = ObservableValue(initialValue)
        return (result, { [weak result] in result?.mutate(with: $0) }, { [weak result] in result?.fail(with: $0) })
    }
    
    internal func addLifetimeObserver(_ observer: @escaping Action) {
        feed.addCancelationObserver(onCancel: observer)
    }
    
    private func mutate(with value: T) {
        guard case .left(_) = payload else { return }
        payload = Either(result: value)
        feed.push(ephemeral: value)
    }
    
    private func fail(with error: Error) {
        guard case .left(_) = payload else { return }
        payload = Either(error: error)
        feed.push(terminal: error)
    }
    
    private var payload: Either<T, Error>
    
    private let feed: Feed<T, Error>
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
