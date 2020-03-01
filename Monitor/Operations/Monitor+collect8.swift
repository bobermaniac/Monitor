import Foundation

public enum OneOf9<T1, T2, T3, T4, T5, T6, T7, T8, T9> {
    case e1(T1)
    case e2(T2)
    case e3(T3)
    case e4(T4)
    case e5(T5)
    case e6(T6)
    case e7(T7)
    case e8(T8)
    case e9(T9)
}

public func all<E, T1, T2, T3, T4, T5, T6, T7, T8, T9>(
    _ m1: Monitor<E, T1>,
    _ m2: Monitor<E, T2>,
    _ m3: Monitor<E, T3>,
    _ m4: Monitor<E, T4>,
    _ m5: Monitor<E, T5>,
    _ m6: Monitor<E, T6>,
    _ m7: Monitor<E, T7>,
    _ m8: Monitor<E, T8>,
    _ m9: Monitor<E, T9>) -> Monitor<E, (T1, T2, T3, T4, T5, T6, T7, T8, T9)> {
    typealias AT = (T1?, T2?, T3?, T4?, T5?, T6?, T7?, T8?, T9?)
    let accumulator = (nil, nil, nil, nil, nil, nil, nil, nil, nil) as AT
    let factory = CollectorFactory<E, E, T1, T2, T3, T4, T5, T6, T7, T8, T9, AT>(
        ephemeralMapper: unwrap(from:),
        accumulator: accumulator,
        terminalReducer: set)
    return mix(m1, m2, m3, m4, m5, m6, m7, m8, m9, factory: factory)
        .map(ephemeral: identity, terminal: unwrap)
}

public func all<E, T1: Result, T2: Result, T3: Result, T4: Result, T5: Result, T6: Result, T7: Result, T8: Result, T9: Result>(
    _ m1: Monitor<E, T1>,
    _ m2: Monitor<E, T2>,
    _ m3: Monitor<E, T3>,
    _ m4: Monitor<E, T4>,
    _ m5: Monitor<E, T5>,
    _ m6: Monitor<E, T6>,
    _ m7: Monitor<E, T7>,
    _ m8: Monitor<E, T8>,
    _ m9: Monitor<E, T9>) -> Monitor<E, Either<(T1.T, T2.T, T3.T, T4.T, T5.T, T6.T, T7.T, T8.T, T9.T), Error>> {
    typealias AT = Either<(T1.T?, T2.T?, T3.T?, T4.T?, T5.T?, T6.T?, T7.T?, T8.T?, T9.T?), Error>
    let accumulator = AT.left((nil, nil, nil, nil, nil, nil, nil, nil, nil))
    let factory = CollectorFactory<E, E, T1, T2, T3, T4, T5, T6, T7, T8, T9, AT>(
        ephemeralMapper: unwrap(from:),
        accumulator: accumulator,
        terminalReducer: set)
    return mix(m1, m2, m3, m4, m5, m6, m7, m8, m9, factory: factory)
        .map(ephemeral: identity, terminal: unwrap)
}

public func collect<E, ET, T1, T2, T3, T4, T5, T6, T7, T8, T9, AT>(
    monitors m1: Monitor<E, T1>,
    _ m2: Monitor<E, T2>,
    _ m3: Monitor<E, T3>,
    _ m4: Monitor<E, T4>,
    _ m5: Monitor<E, T5>,
    _ m6: Monitor<E, T6>,
    _ m7: Monitor<E, T7>,
    _ m8: Monitor<E, T8>,
    _ m9: Monitor<E, T9>,
    ephemeralMapper: @escaping (OneOf9<E, E, E, E, E, E, E, E, E>) -> ET,
    accumulator: AT,
    terminalReducer: @escaping (inout AT, OneOf9<T1, T2, T3, T4, T5, T6, T7, T8, T9>) -> Bool) -> Monitor<ET, AT> {
    let factory = CollectorFactory(ephemeralMapper: ephemeralMapper,
                                   accumulator: accumulator,
                                   terminalReducer: terminalReducer)
    return mix(m1, m2, m3, m4, m5, m6, m7, m8, m9, factory: factory)
}

private struct CollectorFactory<E, ET, T1, T2, T3, T4, T5, T6, T7, T8, T9, AT>: MonitorHetorogeneusMixingFactory {
    init(ephemeralMapper: @escaping (OneOf9<E, E, E, E, E, E, E, E, E>) -> ET,
         accumulator: AT,
         terminalReducer: @escaping (inout AT, OneOf9<T1, T2, T3, T4, T5, T6, T7, T8, T9>) -> Bool) {
        self.mapEphemeral = ephemeralMapper
        self.accumulator = accumulator
        self.reduceTerminal = terminalReducer
    }
    
    func make(feed: Feed<ET, AT>) -> Collector<E, ET, T1, T2, T3, T4, T5, T6, T7, T8, T9, AT> {
        return Collector(ephemeralMapper: mapEphemeral,
                         accumulator: accumulator,
                         terminalReducer: reduceTerminal,
                         feed: feed)
    }
    
    typealias Mixer = Collector<E, ET, T1, T2, T3, T4, T5, T6, T7, T8, T9, AT>
    
    let mapEphemeral: (OneOf9<E, E, E, E, E, E, E, E, E>) -> ET
    let accumulator: AT
    let reduceTerminal: (inout AT, OneOf9<T1, T2, T3, T4, T5, T6, T7, T8, T9>) -> Bool
}

private final class Collector<E, ET, T1, T2, T3, T4, T5, T6, T7, T8, T9, AT>: MonitorHetorogeneusMixing {
    typealias Types = SignalTypeSet<SignalType<E, T1>,
                                    SignalType<E, T2>,
                                    SignalType<E, T3>,
                                    SignalType<E, T4>,
                                    SignalType<E, T5>,
                                    SignalType<E, T6>,
                                    SignalType<E, T7>,
                                    SignalType<E, T8>,
                                    SignalType<E, T9>,
                                    SignalType<ET, AT>>
    init(ephemeralMapper: @escaping (OneOf9<E, E, E, E, E, E, E, E, E>) -> ET,
         accumulator: AT,
         terminalReducer: @escaping (inout AT, OneOf9<T1, T2, T3, T4, T5, T6, T7, T8, T9>) -> Bool,
         feed: Feed<ET, AT>) {
        self.mapEphemeral = ephemeralMapper
        self.accumulator = accumulator
        self.reduceTerminal = terminalReducer
        self.feed = feed
    }
    
    func eat1(ephemeral: E) {
        feed.push(ephemeral: mapEphemeral(.e1(ephemeral)))
    }
    
    func eat1(terminal: T1) {
        process(.e1(terminal))
    }
    
    func eat2(ephemeral: E) {
        feed.push(ephemeral: mapEphemeral(.e2(ephemeral)))
    }
    
    func eat2(terminal: T2) {
        process(.e2(terminal))
    }
    
    func eat3(ephemeral: E) {
        feed.push(ephemeral: mapEphemeral(.e3(ephemeral)))
    }
    
    func eat3(terminal: T3) {
        process(.e3(terminal))
    }
    
    func eat4(ephemeral: E) {
        feed.push(ephemeral: mapEphemeral(.e4(ephemeral)))
    }
    
    func eat4(terminal: T4) {
        process(.e4(terminal))
    }
    
    func eat5(ephemeral: E) {
        feed.push(ephemeral: mapEphemeral(.e5(ephemeral)))
    }
    
    func eat5(terminal: T5) {
        process(.e5(terminal))
    }
    
    func eat6(ephemeral: E) {
        feed.push(ephemeral: mapEphemeral(.e6(ephemeral)))
    }
    
    func eat6(terminal: T6) {
        process(.e6(terminal))
    }
    
    func eat7(ephemeral: E) {
        feed.push(ephemeral: mapEphemeral(.e7(ephemeral)))
    }
    
    func eat7(terminal: T7) {
        process(.e7(terminal))
    }
    
    func eat8(ephemeral: E) {
        feed.push(ephemeral: mapEphemeral(.e8(ephemeral)))
    }
    
    func eat8(terminal: T8) {
        process(.e8(terminal))
    }
    
    func eat9(ephemeral: E) {
        feed.push(ephemeral: mapEphemeral(.e9(ephemeral)))
    }
    
    func eat9(terminal: T9) {
        process(.e9(terminal))
    }
    
    private func process(_ terminal: OneOf9<T1, T2, T3, T4, T5, T6, T7, T8, T9>) {
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
    
    let mapEphemeral: (OneOf9<E, E, E, E, E, E, E, E, E>) -> ET
    var accumulator: AT
    var remainingCount = 9
    let reduceTerminal: (inout AT, OneOf9<T1, T2, T3, T4, T5, T6, T7, T8, T9>) -> Bool
    let feed: Feed<ET, AT>
}

private func unwrap<T>(from value: OneOf9<T, T, T, T, T, T, T, T, T>) -> T {
    switch value {
    case .e1(let result):
        return result
    case .e2(let result):
        return result
    case .e3(let result):
        return result
    case .e4(let result):
        return result
    case .e5(let result):
        return result
    case .e6(let result):
        return result
    case .e7(let result):
        return result
    case .e8(let result):
        return result
    case .e9(let result):
        return result
    }
}

private func set<T1, T2, T3, T4, T5, T6, T7, T8, T9>(
    to tuple: inout (T1?, T2?, T3?, T4?, T5?, T6?, T7?, T8?, T9?),
    value: OneOf9<T1, T2, T3, T4, T5, T6, T7, T8, T9>) -> Bool {
    switch value {
    case .e1(let e1):
        tuple.0 = e1
    case .e2(let e2):
        tuple.1 = e2
    case .e3(let e3):
        tuple.2 = e3
    case .e4(let e4):
        tuple.3 = e4
    case .e5(let e5):
        tuple.4 = e5
    case .e6(let e6):
        tuple.5 = e6
    case .e7(let e7):
        tuple.6 = e7
    case .e8(let e8):
        tuple.7 = e8
    case .e9(let e9):
        tuple.8 = e9
    }
    return false
}

private func set<T1: Result,
                 T2: Result,
                 T3: Result,
                 T4: Result,
                 T5: Result,
                 T6: Result,
                 T7: Result,
                 T8: Result,
                 T9: Result>(
    to tuple: inout Either<(T1.T?, T2.T?, T3.T?, T4.T?, T5.T?, T6.T?, T7.T?, T8.T?, T9.T?), Error>,
    value: OneOf9<T1, T2, T3, T4, T5, T6, T7, T8, T9>) -> Bool {
    do {
        switch tuple {
        case .left(var accumulator):
            switch value {
            case .e1(let candidate):
                accumulator.0 = try candidate.unwrap()
            case .e2(let candidate):
                accumulator.1 = try candidate.unwrap()
            case .e3(let candidate):
                accumulator.2 = try candidate.unwrap()
            case .e4(let candidate):
                accumulator.3 = try candidate.unwrap()
            case .e5(let candidate):
                accumulator.4 = try candidate.unwrap()
            case .e6(let candidate):
                accumulator.5 = try candidate.unwrap()
            case .e7(let candidate):
                accumulator.6 = try candidate.unwrap()
            case .e8(let candidate):
                accumulator.7 = try candidate.unwrap()
            case .e9(let candidate):
                accumulator.8 = try candidate.unwrap()
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

private func unwrap<T1, T2, T3, T4, T5, T6, T7, T8, T9>(
    tuple: (T1?, T2?, T3?, T4?, T5?, T6?, T7?, T8?, T9?)) -> (T1, T2, T3, T4, T5, T6, T7, T8, T9) {
    return (tuple.0!, tuple.1!, tuple.2!, tuple.3!, tuple.4!, tuple.5!, tuple.6!, tuple.7!, tuple.8!)
}

private func unwrap<T1, T2, T3, T4, T5, T6, T7, T8, T9>(
    tuple: Either<(T1?, T2?, T3?, T4?, T5?, T6?, T7?, T8?, T9?), Error>) -> Either<(T1, T2, T3, T4, T5, T6, T7, T8, T9), Error> {
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
