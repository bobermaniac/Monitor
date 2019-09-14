import Foundation

public func all<T>(of monitors: [Monitor<Never, T>]) -> Monitor<Never, [T]> {
    return mix(monitors, factory: SameAllFactory(of: T.self))
}

public func all<T1, T2>(_ left: Monitor<Never, T1>, _ right: Monitor<Never, T2>) -> Monitor<Never, (T1, T2)> {
    let mp = Monitor<Never, Void>(terminal: ())
    return mix(left, right, mp, mp, mp, mp, mp, mp, mp, factory: AllFactory())
        .map(ephemeral: identity, terminal: take2)
}

public func all<T1, T2, T3>(_ m1: Monitor<Never, T1>, _ m2: Monitor<Never, T2>, _ m3: Monitor<Never, T3>) -> Monitor<Never, (T1, T2, T3)> {
    let mp = Monitor<Never, Void>(terminal: ())
    return mix(m1, m2, m3, mp, mp, mp, mp, mp, mp, factory: AllFactory())
        .map(ephemeral: identity, terminal: take3)
}

public func all<T1, T2, T3, T4>(_ m1: Monitor<Never, T1>,
                                _ m2: Monitor<Never, T2>,
                                _ m3: Monitor<Never, T3>,
                                _ m4: Monitor<Never, T4>) -> Monitor<Never, (T1, T2, T3, T4)> {
    let mp = Monitor<Never, Void>(terminal: ())
    return mix(m1, m2, m3, m4, mp, mp, mp, mp, mp, factory: AllFactory())
        .map(ephemeral: identity, terminal: take4)
}

public func all<T1, T2, T3, T4, T5>(_ m1: Monitor<Never, T1>,
                                    _ m2: Monitor<Never, T2>,
                                    _ m3: Monitor<Never, T3>,
                                    _ m4: Monitor<Never, T4>,
                                    _ m5: Monitor<Never, T5>) -> Monitor<Never, (T1, T2, T3, T4, T5)> {
    let mp = Monitor<Never, Void>(terminal: ())
    return mix(m1, m2, m3, m4, m5, mp, mp, mp, mp, factory: AllFactory())
        .map(ephemeral: identity, terminal: take5)
}

public func all<T1, T2, T3, T4, T5, T6>(
    _ m1: Monitor<Never, T1>,
    _ m2: Monitor<Never, T2>,
    _ m3: Monitor<Never, T3>,
    _ m4: Monitor<Never, T4>,
    _ m5: Monitor<Never, T5>,
    _ m6: Monitor<Never, T6>) -> Monitor<Never, (T1, T2, T3, T4, T5, T6)> {
    let mp = Monitor<Never, Void>(terminal: ())
    return mix(m1, m2, m3, m4, m5, m6, mp, mp, mp, factory: AllFactory())
        .map(ephemeral: identity, terminal: take6)
}


public func all<T1, T2, T3, T4, T5, T6, T7>(
    _ m1: Monitor<Never, T1>,
    _ m2: Monitor<Never, T2>,
    _ m3: Monitor<Never, T3>,
    _ m4: Monitor<Never, T4>,
    _ m5: Monitor<Never, T5>,
    _ m6: Monitor<Never, T6>,
    _ m7: Monitor<Never, T7>) -> Monitor<Never, (T1, T2, T3, T4, T5, T6, T7)> {
    let mp = Monitor<Never, Void>(terminal: ())
    return mix(m1, m2, m3, m4, m5, m6, m7, mp, mp, factory: AllFactory())
        .map(ephemeral: identity, terminal: take7)
}


public func all<T1, T2, T3, T4, T5, T6, T7, T8>(
    _ m1: Monitor<Never, T1>,
    _ m2: Monitor<Never, T2>,
    _ m3: Monitor<Never, T3>,
    _ m4: Monitor<Never, T4>,
    _ m5: Monitor<Never, T5>,
    _ m6: Monitor<Never, T6>,
    _ m7: Monitor<Never, T7>,
    _ m8: Monitor<Never, T8>) -> Monitor<Never, (T1, T2, T3, T4, T5, T6, T7, T8)> {
    let mp = Monitor<Never, Void>(terminal: ())
    return mix(m1, m2, m3, m4, m5, m6, m7, m8, mp, factory: AllFactory())
        .map(ephemeral: identity, terminal: take8)
}


public func all<T1, T2, T3, T4, T5, T6, T7, T8, T9>(
    _ m1: Monitor<Never, T1>,
    _ m2: Monitor<Never, T2>,
    _ m3: Monitor<Never, T3>,
    _ m4: Monitor<Never, T4>,
    _ m5: Monitor<Never, T5>,
    _ m6: Monitor<Never, T6>,
    _ m7: Monitor<Never, T7>,
    _ m8: Monitor<Never, T8>,
    _ m9: Monitor<Never, T9>) -> Monitor<Never, (T1, T2, T3, T4, T5, T6, T7, T8, T9)> {
    return mix(m1, m2, m3, m4, m5, m6, m7, m8, m9, factory: AllFactory())
}

private struct SameAllFactory<T>: MonitorHomogeneousMixingFactory {
    init(of _: T.Type) { }

    func make(count: Int, feed: Feed<Never, [T]>) -> SameAll<T> {
        return SameAll(pendingCount: count, feed: feed)
    }

    typealias Mixer = SameAll<T>
}

private final class SameAll<T>: MonitorHomogeneousMixing {
    typealias InputEphemeral = Never
    typealias InputTerminal = T
    typealias OutputEphemeral = Never
    typealias OutputTerminal = [T]

    init(pendingCount: Int, feed: Feed<Never, [T]>) {
        slots = .init(repeating: nil, count: pendingCount)
        self.feed = feed
    }

    func eat(ephemeral: Never, at index: Int) { }

    func eat(terminal: T, at index: Int) {
        slots[index] = terminal

        let candiate = slots.compactMap(identity)
        if candiate.count == slots.count {
            feed.push(terminal: candiate)
        }
    }

    func cancel(sourceSubscriptions: [Cancelable]) {
        sourceSubscriptions.forEach { $0.cancel() }
    }

    private let feed: Feed<Never, [T]>

    private var slots: [T?]
}

private struct AllFactory<T1, T2, T3, T4, T5, T6, T7, T8, T9>: MonitorHetorogeneusMixingFactory {
    typealias Mixer = All<T1, T2, T3, T4, T5, T6, T7, T8, T9>
    
    func make(feed: Feed<Never, (T1, T2, T3, T4, T5, T6, T7, T8, T9)>) -> Mixer {
        return Mixer(feed: feed)
    }
}

private final class All<T1, T2, T3, T4, T5, T6, T7, T8, T9>: MonitorHetorogeneusMixing {
    func eat1(ephemeral: Never) { }
    
    func eat1(terminal: T1) {
        p1 = terminal
        forwardIfNeeded()
    }
    
    func eat2(ephemeral: Never) { }
    
    func eat2(terminal: T2) {
        p2 = terminal
        forwardIfNeeded()
    }
    
    func eat3(ephemeral: Never) { }
    
    func eat3(terminal: T3) {
        p3 = terminal
        forwardIfNeeded()
    }
    
    func eat4(ephemeral: Never) { }
    
    func eat4(terminal: T4) {
        p4 = terminal
        forwardIfNeeded()
    }
    
    func eat5(ephemeral: Never) { }
    
    func eat5(terminal: T5) {
        p5 = terminal
        forwardIfNeeded()
    }
    
    func eat6(ephemeral: Never) { }
    
    func eat6(terminal: T6) {
        p6 = terminal
        forwardIfNeeded()
    }
    
    func eat7(ephemeral: Never) { }
    
    func eat7(terminal: T7) {
        p7 = terminal
        forwardIfNeeded()
    }
    
    func eat8(ephemeral: Never) { }
    
    func eat8(terminal: T8) {
        p8 = terminal
        forwardIfNeeded()
    }
    
    func eat9(ephemeral: Never) { }
    
    func eat9(terminal: T9) {
        p9 = terminal
        forwardIfNeeded()
    }
    
    func cancel(subscriptions: [Cancelable]) {
        subscriptions.forEach { $0.cancel() }
    }
    
    typealias Types = SignalTypeSet<
        SignalType<Never, T1>,
        SignalType<Never, T2>,
        SignalType<Never, T3>,
        SignalType<Never, T4>,
        SignalType<Never, T5>,
        SignalType<Never, T6>,
        SignalType<Never, T7>,
        SignalType<Never, T8>,
        SignalType<Never, T9>,
        SignalType<Never, (T1, T2, T3, T4, T5, T6, T7, T8, T9)>
    >
    init(feed: Feed<Never, (T1, T2, T3, T4, T5, T6, T7, T8, T9)>) {
        self.feed = feed
    }
    
    private func forwardIfNeeded() {
        guard let p1 = self.p1,
            let p2 = self.p2,
            let p3 = self.p3,
            let p4 = self.p4,
            let p5 = self.p5,
            let p6 = self.p6,
            let p7 = self.p7,
            let p8 = self.p8,
            let p9 = self.p9 else { return }
        feed.push(terminal: (p1, p2, p3, p4, p5, p6, p7, p8, p9))
    }
    
    private var p1: T1?
    private var p2: T2?
    private var p3: T3?
    private var p4: T4?
    private var p5: T5?
    private var p6: T6?
    private var p7: T7?
    private var p8: T8?
    private var p9: T9?
    private let feed: Feed<Never, (T1, T2, T3, T4, T5, T6, T7, T8, T9)>
}

public func all<P1: Result, P2: Result>(_ left: Monitor<Never, P1>, _ right: Monitor<Never, P2>) -> Monitor<Never, Either<(P1.T, P2.T), Error>> {
    let mp = Monitor<Never, Either<Void, Error>>(terminal: .left(()))
    return mix(left, right, mp, mp, mp, mp, mp, mp, mp, factory: FailableAllFactory())
        .map(ephemeral: identity, terminal: { t in Either { take2(try t.unwrap()) } })
}

public func all<P1: Result, P2: Result, P3: Result>(_ m1: Monitor<Never, P1>,
                                                    _ m2: Monitor<Never, P2>,
                                                    _ m3: Monitor<Never, P3>) -> Monitor<Never, Either<(P1.T, P2.T, P3.T), Error>> {
    let mp = Monitor<Never, Either<Void, Error>>(terminal: .left(()))
    return mix(m1, m2, m3, mp, mp, mp, mp, mp, mp, factory: FailableAllFactory())
        .map(ephemeral: identity, terminal: { t in Either { take3(try t.unwrap()) } })
}

public func all<P1: Result, P2: Result, P3: Result, P4: Result>(_ m1: Monitor<Never, P1>,
                                                                _ m2: Monitor<Never, P2>,
                                                                _ m3: Monitor<Never, P3>,
                                                                _ m4: Monitor<Never, P4>) -> Monitor<Never, Either<(P1.T, P2.T, P3.T, P4.T), Error>> {
    let mp = Monitor<Never, Either<Void, Error>>(terminal: .left(()))
    return mix(m1, m2, m3, m4, mp, mp, mp, mp, mp, factory: FailableAllFactory())
        .map(ephemeral: identity, terminal: { t in Either { take4(try t.unwrap()) } })
}

public func all<P1: Result, P2: Result, P3: Result, P4: Result, P5: Result>(
    _ m1: Monitor<Never, P1>,
    _ m2: Monitor<Never, P2>,
    _ m3: Monitor<Never, P3>,
    _ m4: Monitor<Never, P4>,
    _ m5: Monitor<Never, P5>
) -> Monitor<Never, Either<(P1.T, P2.T, P3.T, P4.T, P5.T), Error>> {
    let mp = Monitor<Never, Either<Void, Error>>(terminal: .left(()))
    return mix(m1, m2, m3, m4, m5, mp, mp, mp, mp, factory: FailableAllFactory())
        .map(ephemeral: identity, terminal: { t in Either { take5(try t.unwrap()) } })
}

public func all<P1: Result, P2: Result, P3: Result, P4: Result, P5: Result, P6: Result>(
    _ m1: Monitor<Never, P1>,
    _ m2: Monitor<Never, P2>,
    _ m3: Monitor<Never, P3>,
    _ m4: Monitor<Never, P4>,
    _ m5: Monitor<Never, P5>,
    _ m6: Monitor<Never, P6>
    ) -> Monitor<Never, Either<(P1.T, P2.T, P3.T, P4.T, P5.T, P6.T), Error>> {
    let mp = Monitor<Never, Either<Void, Error>>(terminal: .left(()))
    return mix(m1, m2, m3, m4, m5, m6, mp, mp, mp, factory: FailableAllFactory())
        .map(ephemeral: identity, terminal: { t in Either { take6(try t.unwrap()) } })
}

public func all<P1: Result, P2: Result, P3: Result, P4: Result, P5: Result, P6: Result, P7: Result>(
    _ m1: Monitor<Never, P1>,
    _ m2: Monitor<Never, P2>,
    _ m3: Monitor<Never, P3>,
    _ m4: Monitor<Never, P4>,
    _ m5: Monitor<Never, P5>,
    _ m6: Monitor<Never, P6>,
    _ m7: Monitor<Never, P7>
    ) -> Monitor<Never, Either<(P1.T, P2.T, P3.T, P4.T, P5.T, P6.T, P7.T), Error>> {
    let mp = Monitor<Never, Either<Void, Error>>(terminal: .left(()))
    return mix(m1, m2, m3, m4, m5, m6, m7, mp, mp, factory: FailableAllFactory())
        .map(ephemeral: identity, terminal: { t in Either { take7(try t.unwrap()) } })
}

public func all<P1: Result, P2: Result, P3: Result, P4: Result, P5: Result, P6: Result, P7: Result, P8: Result>(
    _ m1: Monitor<Never, P1>,
    _ m2: Monitor<Never, P2>,
    _ m3: Monitor<Never, P3>,
    _ m4: Monitor<Never, P4>,
    _ m5: Monitor<Never, P5>,
    _ m6: Monitor<Never, P6>,
    _ m7: Monitor<Never, P7>,
    _ m8: Monitor<Never, P8>
    ) -> Monitor<Never, Either<(P1.T, P2.T, P3.T, P4.T, P5.T, P6.T, P7.T, P8.T), Error>> {
    let mp = Monitor<Never, Either<Void, Error>>(terminal: .left(()))
    return mix(m1, m2, m3, m4, m5, m6, m7, m8, mp, factory: FailableAllFactory())
        .map(ephemeral: identity, terminal: { t in Either { take8(try t.unwrap()) } })
}

public func all<P1: Result, P2: Result, P3: Result, P4: Result, P5: Result, P6: Result, P7: Result, P8: Result, P9: Result>(
    _ m1: Monitor<Never, P1>,
    _ m2: Monitor<Never, P2>,
    _ m3: Monitor<Never, P3>,
    _ m4: Monitor<Never, P4>,
    _ m5: Monitor<Never, P5>,
    _ m6: Monitor<Never, P6>,
    _ m7: Monitor<Never, P7>,
    _ m8: Monitor<Never, P8>,
    _ m9: Monitor<Never, P9>
    ) -> Monitor<Never, Either<(P1.T, P2.T, P3.T, P4.T, P5.T, P6.T, P7.T, P8.T, P9.T), Error>> {
    return mix(m1, m2, m3, m4, m5, m6, m7, m8, m9, factory: FailableAllFactory())
}

public func all<P: Result>(of monitors: [Monitor<Never, P>]) -> Monitor<Never, Either<[P.T], Error>> {
    return mix(monitors, factory: FailableSameAllFactory())
}

private struct FailableSameAllFactory<P: Result>: MonitorHomogeneousMixingFactory {
    func make(count: Int, feed: Feed<Never, Either<[P.T], Error>>) -> FailableSameAll<P> {
        return FailableSameAll(pendingCount: count, feed: feed)
    }
}

private final class FailableSameAll<P: Result>: MonitorHomogeneousMixing {
    init(pendingCount: Int, feed: Feed<Never, Either<[P.T], Error>>) {
        slots = .init(repeating: nil, count: pendingCount)
        self.feed = feed
    }

    func eat(ephemeral: Never, at index: Int) { }

    func eat(terminal: P, at index: Int) {
        do {
            slots[index] = try terminal.unwrap()
            let candiate = slots.compactMap(identity)
            if candiate.count == slots.count {
                feed.push(terminal: .init(result: candiate))
            }
        } catch let error {
            feed.push(terminal: .init(error: error))
        }
    }

    func cancel(sourceSubscriptions: [Cancelable]) {
        sourceSubscriptions.forEach { $0.cancel() }
    }

    typealias InputEphemeral = Never
    typealias InputTerminal = P
    typealias OutputEphemeral = Never
    typealias OutputTerminal = Either<[P.T], Error>

    private let feed: Feed<Never, Either<[P.T], Error>>
    private var slots: [P.T?]
}

private struct FailableAllFactory<T1: Result,
                                  T2: Result,
                                  T3: Result,
                                  T4: Result,
                                  T5: Result,
                                  T6: Result,
                                  T7: Result,
                                  T8: Result,
                                  T9: Result>: MonitorHetorogeneusMixingFactory {
    typealias Mixer = FailableAll<T1, T2, T3, T4, T5, T6, T7, T8, T9>
    
    func make(feed: Feed<Never, Either<(T1.T, T2.T, T3.T, T4.T, T5.T, T6.T, T7.T, T8.T, T9.T), Error>>) -> Mixer {
        return FailableAll(feed: feed)
    }
}

private final class FailableAll<T1: Result,
                                T2: Result,
                                T3: Result,
                                T4: Result,
                                T5: Result,
                                T6: Result,
                                T7: Result,
                                T8: Result,
                                T9: Result>: MonitorHetorogeneusMixing {
    typealias Types = SignalTypeSet<
        SignalType<Never, T1>,
        SignalType<Never, T2>,
        SignalType<Never, T3>,
        SignalType<Never, T4>,
        SignalType<Never, T5>,
        SignalType<Never, T6>,
        SignalType<Never, T7>,
        SignalType<Never, T8>,
        SignalType<Never, T9>,
        SignalType<Never, Either<(T1.T, T2.T, T3.T, T4.T, T5.T, T6.T, T7.T, T8.T, T9.T), Error>>
    >
    
    init(feed: Feed<Never, Either<(T1.T, T2.T, T3.T, T4.T, T5.T, T6.T, T7.T, T8.T, T9.T), Error>>) {
        self.feed = feed
    }
    
    func eat1(ephemeral: Never) { }
    
    func eat1(terminal: T1) {
        do {
            p1 = try terminal.unwrap()
            forwardIfNeeded()
        } catch let error {
            feed.push(terminal: .right(error))
        }
    }
    
    func eat2(ephemeral: Never) { }
    
    func eat2(terminal: T2) {
        do {
            p2 = try terminal.unwrap()
            forwardIfNeeded()
        } catch let error {
            feed.push(terminal: .right(error))
        }
    }

    func eat3(ephemeral: Never) { }
    
    func eat3(terminal: T3) {
        do {
            p3 = try terminal.unwrap()
            forwardIfNeeded()
        } catch let error {
            feed.push(terminal: .right(error))
        }
    }
    
    func eat4(ephemeral: Never) { }
    
    func eat4(terminal: T4) {
        do {
            p4 = try terminal.unwrap()
            forwardIfNeeded()
        } catch let error {
            feed.push(terminal: .right(error))
        }
    }
    
    func eat5(ephemeral: Never) { }
    
    func eat5(terminal: T5) {
        do {
            p5 = try terminal.unwrap()
            forwardIfNeeded()
        } catch let error {
            feed.push(terminal: .right(error))
        }
    }
    
    func eat6(ephemeral: Never) { }
    
    func eat6(terminal: T6) {
        do {
            p6 = try terminal.unwrap()
            forwardIfNeeded()
        } catch let error {
            feed.push(terminal: .right(error))
        }
    }
    
    func eat7(ephemeral: Never) { }
    
    func eat7(terminal: T7) {
        do {
            p7 = try terminal.unwrap()
            forwardIfNeeded()
        } catch let error {
            feed.push(terminal: .right(error))
        }
    }
    
    func eat8(ephemeral: Never) { }
    
    func eat8(terminal: T8) {
        do {
            p8 = try terminal.unwrap()
            forwardIfNeeded()
        } catch let error {
            feed.push(terminal: .right(error))
        }
    }
    
    func eat9(ephemeral: Never) { }
    
    func eat9(terminal: T9) {
        do {
            p9 = try terminal.unwrap()
            forwardIfNeeded()
        } catch let error {
            feed.push(terminal: .right(error))
        }
    }
    
    func cancel(subscriptions: [Cancelable]) {
        subscriptions.forEach { $0.cancel() }
    }

    private var p1: T1.T?
    private var p2: T2.T?
    private var p3: T3.T?
    private var p4: T4.T?
    private var p5: T5.T?
    private var p6: T6.T?
    private var p7: T7.T?
    private var p8: T8.T?
    private var p9: T9.T?
    private var feed: Feed<Never, Either<(T1.T, T2.T, T3.T, T4.T, T5.T, T6.T, T7.T, T8.T, T9.T), Error>>
    
    private func forwardIfNeeded() {
        guard let p1 = self.p1,
            let p2 = self.p2,
            let p3 = self.p3,
            let p4 = self.p4,
            let p5 = self.p5,
            let p6 = self.p6,
            let p7 = self.p7,
            let p8 = self.p8,
            let p9 = self.p9 else { return }
        feed.push(terminal: .left((p1, p2, p3, p4, p5, p6, p7, p8, p9)))
    }
}

private func take2<T1, T2, T3, T4, T5, T6, T7, T8, T9>(_ input: (T1, T2, T3, T4, T5, T6, T7, T8, T9)) -> (T1, T2) {
    let (p1, p2, _, _, _, _, _, _, _) = input
    return (p1, p2)
}

private func take3<T1, T2, T3, T4, T5, T6, T7, T8, T9>(_ input: (T1, T2, T3, T4, T5, T6, T7, T8, T9)) -> (T1, T2, T3) {
    let (p1, p2, p3, _, _, _, _, _, _) = input
    return (p1, p2, p3)
}

private func take4<T1, T2, T3, T4, T5, T6, T7, T8, T9>(_ input: (T1, T2, T3, T4, T5, T6, T7, T8, T9)) -> (T1, T2, T3, T4) {
    let (p1, p2, p3, p4, _, _, _, _, _) = input
    return (p1, p2, p3, p4)
}

private func take5<T1, T2, T3, T4, T5, T6, T7, T8, T9>(_ input: (T1, T2, T3, T4, T5, T6, T7, T8, T9)) -> (T1, T2, T3, T4, T5) {
    let (p1, p2, p3, p4, p5, _, _, _, _) = input
    return (p1, p2, p3, p4, p5)
}

private func take6<T1, T2, T3, T4, T5, T6, T7, T8, T9>(_ input: (T1, T2, T3, T4, T5, T6, T7, T8, T9)) -> (T1, T2, T3, T4, T5, T6) {
    let (p1, p2, p3, p4, p5, p6, _, _, _) = input
    return (p1, p2, p3, p4, p5, p6)
}

private func take7<T1, T2, T3, T4, T5, T6, T7, T8, T9>(_ input: (T1, T2, T3, T4, T5, T6, T7, T8, T9)) -> (T1, T2, T3, T4, T5, T6, T7) {
    let (p1, p2, p3, p4, p5, p6, p7, _, _) = input
    return (p1, p2, p3, p4, p5, p6, p7)
}

private func take8<T1, T2, T3, T4, T5, T6, T7, T8, T9>(_ input: (T1, T2, T3, T4, T5, T6, T7, T8, T9)) -> (T1, T2, T3, T4, T5, T6, T7, T8) {
    let (p1, p2, p3, p4, p5, p6, p7, p8, _) = input
    return (p1, p2, p3, p4, p5, p6, p7, p8)
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
