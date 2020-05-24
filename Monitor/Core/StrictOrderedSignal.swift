import Foundation

public final class StrictOrderedSignal<Ephemeral, Terminal> {
    public static func create(
        of _: Ephemeral.Type = Ephemeral.self,
        _: Terminal.Type = Terminal.self
    ) -> (Monitor<Ephemeral, Terminal>, StrictOrderedSignal) {
        let (monitor, feed) = Monitor.make(of: Ephemeral.self, Terminal.self)
        let signal = Self(monitor: monitor, feed: feed)
        return (monitor, signal)
    }

    public private(set) weak var monitor: Monitor<Ephemeral, Terminal>?

    public func emit(ephemeral: Ephemeral) {
        switch pending {
        case .none:
            propagate(ephemeral: ephemeral, pendingEphemerals: Queue())
        case var .ephemeral(pendingEphemerals):
            pendingEphemerals.push(ephemeral)
            pending = .ephemeral(pendingEphemerals)
        case .terminal:
            break
        }
    }

    public func terminate(with terminal: Terminal) {
        switch pending {
        case .none:
            internalTerminate(with: terminal)
        case .ephemeral:
            pending = .terminal(terminal)
        case .terminal:
            break
        }
    }

    public func cancelled(callback: @escaping Action) {
        feed.addCancelationObserver(onCancel: callback)
    }

    private init(
        monitor: Monitor<Ephemeral, Terminal>,
        feed: Feed<Ephemeral, Terminal>
    ) {
        self.feed = feed
        self.monitor = monitor
    }

    private func propagate(ephemeral: Ephemeral, pendingEphemerals: Queue<Ephemeral>) {
        pending = .ephemeral(pendingEphemerals)
        feed.push(ephemeral: ephemeral)
        onPropagationComplete()
    }

    private func internalTerminate(with terminal: Terminal) {
        pending = nil
        feed.push(terminal: terminal)
    }

    private func onPropagationComplete() {
        switch pending {
        case var .ephemeral(pendingEphemerals):
            if let ephemeral = pendingEphemerals.pop() {
                propagate(ephemeral: ephemeral, pendingEphemerals: pendingEphemerals)
            } else {
                pending = nil
            }
        case let .terminal(terminal):
            internalTerminate(with: terminal)
        case .none:
            break
        }
    }

    private enum Pending {
        case ephemeral(Queue<Ephemeral>)
        case terminal(Terminal)
    }

    private var pending: Pending?
    private let feed: Feed<Ephemeral, Terminal>
}
