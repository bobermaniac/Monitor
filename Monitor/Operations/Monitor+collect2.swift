import Foundation

public func all<E, T1, T2>(_ m1: Monitor<E, T1>, _ m2: Monitor<E, T2>) -> Monitor<E, (T1, T2)> {
    let accumulator = (nil, nil) as (T1?, T2?)
    let factory = CollectorFactory<E, E, T1, T2, (T1?, T2?)>(ephemeralMapper: unwrap(from:),
                                                             accumulator: accumulator,
                                                             terminalReducer: set)
    let void = Monitor(terminal: (), ephemeralType: Never.self)
    return mix(m1, m2, void, void, void, void, void, void, void, factory: factory)
        .map(ephemeral: identity, terminal: unwrap)
}

public func all<E, T1: Result, T2: Result>(_ m1: Monitor<E, T1>,
                                           _ m2: Monitor<E, T2>) -> Monitor<E, Either<(T1.T, T2.T), Error>> {
    let accumulator = Either<(T1.T?, T2.T?), Error>.left((nil, nil))
    let factory = CollectorFactory<E, E, T1, T2, Either<(T1.T?, T2.T?), Error>>(ephemeralMapper: unwrap(from:),
                                                                                accumulator: accumulator,
                                                                                terminalReducer: set)
    let void = Monitor(terminal: (), ephemeralType: Never.self)
    return mix(m1, m2, void, void, void, void, void, void, void, factory: factory)
        .map(ephemeral: identity, terminal: unwrap)
}

public func collect<E, ET, T1, T2, AT>(monitors m1: Monitor<E, T1>,
                                       _ m2: Monitor<E, T2>,
                                       ephemeralMapper: @escaping (Either<E, E>) -> ET,
                                       accumulator: AT,
                                       terminalReducer: @escaping (inout AT, Either<T1, T2>) -> Bool) -> Monitor<ET, AT> {
    let factory = CollectorFactory(ephemeralMapper: ephemeralMapper,
                                   accumulator: accumulator,
                                   terminalReducer: terminalReducer)
    let void = Monitor(terminal: (), ephemeralType: Never.self)
    return mix(m1, m2, void, void, void, void, void, void, void, factory: factory)
}

private struct CollectorFactory<E, ET, T1, T2, AT>: MonitorHetorogeneusMixingFactory {
    init(ephemeralMapper: @escaping (Either<E, E>) -> ET,
         accumulator: AT,
         terminalReducer: @escaping (inout AT, Either<T1, T2>) -> Bool) {
        self.mapEphemeral = ephemeralMapper
        self.accumulator = accumulator
        self.reduceTerminal = terminalReducer
    }
    
    func make(feed: Feed<ET, AT>) -> Collector<E, ET, T1, T2, AT> {
        return Collector(ephemeralMapper: mapEphemeral,
                         accumulator: accumulator,
                         terminalReducer: reduceTerminal,
                         feed: feed)
    }
    
    typealias Mixer = Collector<E, ET, T1, T2, AT>
    
    let mapEphemeral: (Either<E, E>) -> ET
    let accumulator: AT
    let reduceTerminal: (inout AT, Either<T1, T2>) -> Bool
}

private final class Collector<E, ET, T1, T2, AT>: MonitorHetorogeneusMixing {
    typealias Types = SignalTypeSet<SignalType<E, T1>,
                                    SignalType<E, T2>,
                                    SignalType<Never, Void>,
                                    SignalType<Never, Void>,
                                    SignalType<Never, Void>,
                                    SignalType<Never, Void>,
                                    SignalType<Never, Void>,
                                    SignalType<Never, Void>,
                                    SignalType<Never, Void>,
                                    SignalType<ET, AT>>
    init(ephemeralMapper: @escaping (Either<E, E>) -> ET,
         accumulator: AT,
         terminalReducer: @escaping (inout AT, Either<T1, T2>) -> Bool,
         feed: Feed<ET, AT>) {
        self.mapEphemeral = ephemeralMapper
        self.accumulator = accumulator
        self.reduceTerminal = terminalReducer
        self.feed = feed
    }
    
    func eat1(ephemeral: E) {
        feed.push(ephemeral: mapEphemeral(.left(ephemeral)))
    }
    
    func eat1(terminal: T1) {
        process(.left(terminal))
    }
    
    func eat2(ephemeral: E) {
        feed.push(ephemeral: mapEphemeral(.right(ephemeral)))
    }
    
    func eat2(terminal: T2) {
        process(.right(terminal))
    }
    
    func eat3(ephemeral: Never) { }
    
    func eat3(terminal: ()) { }
    
    func eat4(ephemeral: Never) { }
    
    func eat4(terminal: ()) { }
    
    func eat5(ephemeral: Never) { }
    
    func eat5(terminal: ()) { }
    
    func eat6(ephemeral: Never) { }
    
    func eat6(terminal: ()) { }
    
    func eat7(ephemeral: Never) { }
    
    func eat7(terminal: ()) { }
    
    func eat8(ephemeral: Never) { }
    
    func eat8(terminal: ()) { }
    
    func eat9(ephemeral: Never) { }
    
    func eat9(terminal: ()) { }
    
    private func process(_ terminal: Either<T1, T2>) {
        if reduceTerminal(&accumulator, terminal) {
            feed.push(terminal: accumulator)
        }
        remainingCount -= 1
        if remainingCount == 0 {
            feed.push(terminal: accumulator)
        }
    }
    
    func cancel(subscriptions: [Cancelable]) {
        subscriptions.forEach { $0.cancel() }
    }
    
    let mapEphemeral: (Either<E, E>) -> ET
    var accumulator: AT
    var remainingCount = 2
    let reduceTerminal: (inout AT, Either<T1, T2>) -> Bool
    let feed: Feed<ET, AT>
}

private func unwrap<T>(from value: Either<T, T>) -> T {
    switch value {
    case .left(let result):
        return result
    case .right(let result):
        return result
    }
}

private func set<T1, T2>(to tuple: inout (T1?, T2?), value: Either<T1, T2>) -> Bool {
    switch value {
    case .left(let e1):
        tuple.0 = e1
    case .right(let e2):
        tuple.1 = e2
    }
    return false
}

private func set<T1: Result, T2: Result>(to tuple: inout Either<(T1.T?, T2.T?), Error>,
                                         value: Either<T1, T2>) -> Bool {
    do {
        switch tuple {
        case .left(var accumulator):
            switch value {
            case .left(let candidate):
                accumulator.0 = try candidate.unwrap()
            case .right(let candidate):
                accumulator.1 = try candidate.unwrap()
            }
            tuple = .left(accumulator)
            return false
        case .right:
            return true
        }
    } catch let error {
        tuple = .right(error)
        return true
    }
}

private func unwrap<T1, T2>(tuple: (T1?, T2?)) -> (T1, T2) {
    return (tuple.0!, tuple.1!)
}

private func unwrap<T1, T2>(tuple: Either<(T1?, T2?), Error>) -> Either<(T1, T2), Error> {
    switch tuple {
    case .left(let payload):
        return .left(unwrap(tuple: payload))
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
