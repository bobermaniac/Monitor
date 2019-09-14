import Foundation

public protocol SignalKind {
    associatedtype Ephemeral
    associatedtype Terminal
}

public enum SignalType<E, T>: SignalKind {
    public typealias Ephemeral = E
    public typealias Terminal = T
}

public protocol SignalTypeSetKind {
    associatedtype Type1: SignalKind
    associatedtype Type2: SignalKind
    associatedtype Type3: SignalKind
    associatedtype Type4: SignalKind
    associatedtype Type5: SignalKind
    associatedtype Type6: SignalKind
    associatedtype Type7: SignalKind
    associatedtype Type8: SignalKind
    associatedtype Type9: SignalKind
    associatedtype ResultType: SignalKind
}

public enum SignalTypeSet<T1: SignalKind,
                          T2: SignalKind,
                          T3: SignalKind,
                          T4: SignalKind,
                          T5: SignalKind,
                          T6: SignalKind,
                          T7: SignalKind,
                          T8: SignalKind,
                          T9: SignalKind,
                          TR: SignalKind>: SignalTypeSetKind {
    public typealias Type1 = T1
    public typealias Type2 = T2
    public typealias Type3 = T3
    public typealias Type4 = T4
    public typealias Type5 = T5
    public typealias Type6 = T6
    public typealias Type7 = T7
    public typealias Type8 = T8
    public typealias Type9 = T9
    public typealias ResultType = TR
}

public protocol MonitorHetorogeneusMixingFactory {
    associatedtype Mixer: MonitorHetorogeneusMixing
    typealias Types = Mixer.Types
    typealias M1 = Monitor<Types.Type1.Ephemeral, Types.Type1.Terminal>
    typealias M2 = Monitor<Types.Type2.Ephemeral, Types.Type2.Terminal>
    typealias M3 = Monitor<Types.Type3.Ephemeral, Types.Type3.Terminal>
    typealias M4 = Monitor<Types.Type4.Ephemeral, Types.Type4.Terminal>
    typealias M5 = Monitor<Types.Type5.Ephemeral, Types.Type5.Terminal>
    typealias M6 = Monitor<Types.Type6.Ephemeral, Types.Type6.Terminal>
    typealias M7 = Monitor<Types.Type7.Ephemeral, Types.Type7.Terminal>
    typealias M8 = Monitor<Types.Type8.Ephemeral, Types.Type8.Terminal>
    typealias M9 = Monitor<Types.Type9.Ephemeral, Types.Type9.Terminal>
    typealias MR = Monitor<Types.ResultType.Ephemeral, Types.ResultType.Terminal>
    func make(feed: Feed<Types.ResultType.Ephemeral, Types.ResultType.Terminal>) -> Mixer
}

public protocol MonitorHetorogeneusMixing {
    associatedtype Types: SignalTypeSetKind
    func eat1(ephemeral: Types.Type1.Ephemeral)
    func eat1(terminal: Types.Type1.Terminal)
    func eat2(ephemeral: Types.Type2.Ephemeral)
    func eat2(terminal: Types.Type2.Terminal)
    func eat3(ephemeral: Types.Type3.Ephemeral)
    func eat3(terminal: Types.Type3.Terminal)
    func eat4(ephemeral: Types.Type4.Ephemeral)
    func eat4(terminal: Types.Type4.Terminal)
    func eat5(ephemeral: Types.Type5.Ephemeral)
    func eat5(terminal: Types.Type5.Terminal)
    func eat6(ephemeral: Types.Type6.Ephemeral)
    func eat6(terminal: Types.Type6.Terminal)
    func eat7(ephemeral: Types.Type7.Ephemeral)
    func eat7(terminal: Types.Type7.Terminal)
    func eat8(ephemeral: Types.Type8.Ephemeral)
    func eat8(terminal: Types.Type8.Terminal)
    func eat9(ephemeral: Types.Type9.Ephemeral)
    func eat9(terminal: Types.Type9.Terminal)

    func cancel(subscriptions: [Cancelable])
}

public func mix<F: MonitorHetorogeneusMixingFactory>(_ m1: F.M1,
                                                     _ m2: F.M2,
                                                     _ m3: F.M3,
                                                     _ m4: F.M4,
                                                     _ m5: F.M5,
                                                     _ m6: F.M6,
                                                     _ m7: F.M7,
                                                     _ m8: F.M8,
                                                     _ m9: F.M9,
                                                     factory: F) -> F.MR {
    let interceptor = TerminalInterceptor()
    let (result, rawFeed) = F.MR.make()
    let feed = Feed(feed: rawFeed, terminalInterceptor: interceptor.terminalReceived)!
    
    let mixer = factory.make(feed: feed)
    let subsctiptions = [
        m1.observe(ephemeral: mixer.eat1, terminal: mixer.eat1),
        m2.observe(ephemeral: mixer.eat2, terminal: mixer.eat2),
        m3.observe(ephemeral: mixer.eat3, terminal: mixer.eat3),
        m4.observe(ephemeral: mixer.eat4, terminal: mixer.eat4),
        m5.observe(ephemeral: mixer.eat5, terminal: mixer.eat5),
        m6.observe(ephemeral: mixer.eat6, terminal: mixer.eat6),
        m7.observe(ephemeral: mixer.eat7, terminal: mixer.eat7),
        m8.observe(ephemeral: mixer.eat8, terminal: mixer.eat8),
        m9.observe(ephemeral: mixer.eat9, terminal: mixer.eat9)
    ]
    interceptor.cancelables = subsctiptions
    
    let storage = MixerStorage(subscriptions: subsctiptions, mixer: mixer)
    feed.addCancelationObserver(onCancel: storage.cancel)
    return result
}

private final class MixerStorage<Mixer: MonitorHetorogeneusMixing> {
    init(subscriptions: [Cancelable], mixer: Mixer) {
        self.subscriptions = subscriptions
        self.mixer = mixer
    }
    
    func cancel() {
        mixer.cancel(subscriptions: subscriptions)
    }
    
    private let subscriptions: [Cancelable]
    private let mixer: Mixer
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
