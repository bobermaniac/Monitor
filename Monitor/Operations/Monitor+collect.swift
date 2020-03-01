import Foundation

public func all<E, T>(of monitors: [Monitor<E, T>]) -> Monitor<E, [T]> {
    let accumulator = [T?](repeatElement(nil, count: monitors.count))
    let factory = SameAllFactory(ephemeralMapper: first,
                                 accumulator: accumulator,
                                 reducer: emplace) as SameAllFactory<E, E, T, [T?]>
    return mix(monitors, factory: factory).map(ephemeral: identity, terminal: unopt(array:))
}

public func all<E, R: Result>(of monitors: [Monitor<E, R>]) -> Monitor<E, Either<[R.T], Error>> {
    let accumulator = [R.T?](repeatElement(nil, count: monitors.count))
    let factory = SameAllFactory<E, E, R, Either<[R.T?], Error>>(ephemeralMapper: first,
                                                                 accumulator: Either.left(accumulator),
                                                                 reducer: failableEmplace)
    return mix(monitors, factory: factory).map(ephemeral: identity, terminal: unopt(object:))
}

public func collect<E, ET, T, AT>(monitors: [Monitor<E, T>],
                                  ephemeralMapper: @escaping (E, Int) -> ET,
                                  accumulator: AT,
                                  terminalReducer: @escaping (inout AT, T, Int) -> Bool) -> Monitor<ET, AT> {
    let factory = SameAllFactory(ephemeralMapper: ephemeralMapper,
                                 accumulator: accumulator,
                                 reducer: terminalReducer)
    return mix(monitors, factory: factory)
}

private struct SameAllFactory<E, ET, T, AT>: MonitorHomogeneousMixingFactory {
    init(ephemeralMapper: @escaping (E, Int) -> ET,
         accumulator: AT,
         reducer: @escaping (inout AT, T, Int) -> Bool) {
        self.mapEphemeral = ephemeralMapper
        self.accumulator = accumulator
        self.reduceTerminal = reducer
    }
        
    func make(count: Int, feed: Feed<ET, AT>) -> Mixer {
        return SameAll(pendingCount: count,
                       ephemeralMapper: mapEphemeral,
                       accumulator: accumulator,
                       reducer: reduceTerminal,
                       feed: feed)
    }

    typealias Mixer = SameAll<E, ET, T, AT>
    
    private let mapEphemeral: (E, Int) -> ET
    private var accumulator: AT
    private let reduceTerminal: (inout AT, T, Int) -> Bool
}

private final class SameAll<E, ET, T, AT>: MonitorHomogeneousMixing {
    typealias InputEphemeral = E
    typealias InputTerminal = T
    typealias OutputEphemeral = ET
    typealias OutputTerminal = AT

    init(pendingCount: Int,
         ephemeralMapper: @escaping (E, Int) -> ET,
         accumulator: AT,
         reducer: @escaping (inout AT, T, Int) -> Bool,
         feed: Feed<ET, AT>) {
        self.pendingCount = pendingCount
        self.mapEphemeral = ephemeralMapper
        self.accumulator = accumulator
        self.reduceTerminal = reducer
        self.feed = feed
    }

    func eat(ephemeral: E, at index: Int) {
        feed.push(ephemeral: mapEphemeral(ephemeral, index))
    }

    func eat(terminal: T, at index: Int) {
        if reduceTerminal(&accumulator, terminal, index) {
            feed.push(terminal: accumulator)
            return
        }
        pendingCount -= 1
        if pendingCount == 0 {
            feed.push(terminal: accumulator)
        }
    }

    func cancel(sourceSubscriptions: [Cancelable]) {
        sourceSubscriptions.forEach { $0.cancel() }
    }

    private var pendingCount: Int
    private let mapEphemeral: (E, Int) -> ET
    private var accumulator: AT
    private let reduceTerminal: (inout AT, T, Int) -> Bool
    private let feed: Feed<ET, AT>
}

private func emplace<T>(into array: inout [T?], object: T, at index: Int) -> Bool {
    array[index] = object
    return false
}

private func failableEmplace<T: Result>(into failableArray: inout Either<[T.T?], Error>, object: T, at index: Int) -> Bool {
    switch failableArray {
    case .left(var array):
        do {
            array[index] = try object.unwrap()
            failableArray = .left(array)
            return false
        } catch let error {
            failableArray = .right(error)
            return true
        }
    case .right:
        return true
    }
}

private func unopt<T>(array: [T?]) -> [T] {
    return array.compactMap(identity)
}

private func unopt<T>(object: Either<[T?], Error>) -> Either<[T], Error> {
    switch object {
    case .left(let payload):
        return .left(unopt(array: payload))
    case .right(let error):
        return .right(error)
    }
}

// Copyright (C) 2020 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
