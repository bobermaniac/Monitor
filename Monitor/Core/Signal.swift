import Foundation

public struct Signal<Ephemeral, Terminal> {
    public static func make(of _: Ephemeral.Type = Ephemeral.self,
                            _: Terminal.Type = Terminal.self,
                            boundTo dispatcher: Dispatching? = nil) -> (Monitor<Ephemeral, Terminal>, Signal<Ephemeral, Terminal>) {
        dispatcher?.assertIsCurrent(flags: [])
        let (monitor, feed) = Monitor.make(of: Ephemeral.self, Terminal.self)
        if let dispatcher = dispatcher{
            feed.setTargetDispatcher(dispatcher)
        }
        return (monitor, Signal(monitor: monitor, feed: feed))
    }
    
    public var abandoned: Bool {
        return feed.abandoned
    }
    
    private(set) public weak var monitor: Monitor<Ephemeral, Terminal>?

    public func emit(ephemeral: Ephemeral) {
        feed.push(ephemeral: ephemeral)
    }

    public func terminate(with terminal: Terminal) {
        feed.push(terminal: terminal)
    }

    public func canceled(callback: @escaping Action) {
        feed.addCancelationObserver(onCancel: callback)
    }
    
    private init(monitor: Monitor<Ephemeral, Terminal>, feed: Feed<Ephemeral, Terminal>) {
        self.feed = feed
        self.monitor = monitor
    }

    private let feed: Feed<Ephemeral, Terminal>
}

public extension Signal {
    static func make(configure configurationCallback: Consumer<Signal<Ephemeral, Terminal>>, boundTo dispatcher: Dispatching? = nil) -> Monitor<Ephemeral, Terminal> {
        let (monitor, signal) = make(of: Ephemeral.self, Terminal.self, boundTo: dispatcher)
        configurationCallback(signal)
        return monitor
    }
}

public extension Signal {
    static func make<T>(at keypath: ReferenceWritableKeyPath<T, Signal<Ephemeral, Terminal>>,
                        of object: T,
                        boundTo dispatcher: Dispatching? = nil) -> Monitor<Ephemeral, Terminal> {
        return make(configure: { object[keyPath: keypath] = $0 }, boundTo: dispatcher)
    }
    
    static func make<T>(at keypath: ReferenceWritableKeyPath<T, Signal<Ephemeral, Terminal>?>,
                        of object: T,
                        boundTo dispatcher: Dispatching? = nil) -> Monitor<Ephemeral, Terminal> {
        return make(configure: { object[keyPath: keypath] = $0 }, boundTo: dispatcher)
    }
    
    static func make<T>(at keypath: WritableKeyPath<T, Signal<Ephemeral, Terminal>>,
                        of object: inout T,
                        boundTo dispatcher: Dispatching? = nil) -> Monitor<Ephemeral, Terminal> {
        return make(configure: { object[keyPath: keypath] = $0 }, boundTo: dispatcher)
    }
    
    static func make<T>(at keypath: WritableKeyPath<T, Signal<Ephemeral, Terminal>?>,
                        of object: inout T,
                        boundTo dispatcher: Dispatching? = nil) -> Monitor<Ephemeral, Terminal> {
        return make(configure: { object[keyPath: keypath] = $0 }, boundTo: dispatcher)
    }
}

public extension Signal where Ephemeral == Void {
    func emit() {
        emit(ephemeral: ())
    }
}

public extension Signal where Terminal == Void {
    func terminate() {
        terminate(with: ())
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
