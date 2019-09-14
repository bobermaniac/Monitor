import Foundation

public struct BackgroundTask<Ephemeral, Terminal> {
    public init(task runTask: @escaping () -> Monitor<Ephemeral, Terminal>, executeOn executeDispatcher: Dispatching) {
        self.runTask = runTask
        self.executeDispatcher = executeDispatcher
    }
    
    public init(task runTask: @escaping Consumer<Feed<Ephemeral, Terminal>>, executeOn executeDispatcher: Dispatching) {
        self.runTask = {
            let (result, feed) = Monitor.make(of: Ephemeral.self, Terminal.self)
            runTask(feed)
            return result
        }
        self.executeDispatcher = executeDispatcher
    }
    
    public func run(resolveDispatcher: Dispatching, mode: TransferMode = .default) -> Monitor<Ephemeral, Terminal> {
        return run(resolveDispatcher: resolveDispatcher,
                   mode: mode,
                   safetyValve: DirectPass(),
                   litteredStrategy: nil as DoNotMerge<Ephemeral>?)
    }
    
    public func run<L: LitteredStrategy>(resolveDispatcher: Dispatching,
                                         mode: TransferMode,
                                         safetyValve: SafetyValve,
                                         litteredStrategy: L?) -> Monitor<Ephemeral, Terminal> where L.Element == Ephemeral {
        resolveDispatcher.assertIsCurrent(flags: [.barrier])
        let (result, feed) = Monitor.make(of: Ephemeral.self, Terminal.self)
        executeDispatcher.async(flags: [.barrier]) {
            self.runTask().forward(from: self.executeDispatcher,
                                   to: resolveDispatcher,
                                   into: feed,
                                   mode: mode,
                                   safetyValve: safetyValve,
                                   litteredStrategy: litteredStrategy)
        }
        return result
    }
    
    private let runTask: () -> Monitor<Ephemeral, Terminal>
    private let executeDispatcher: Dispatching
}

extension BackgroundTask {
    public static func run(task runTask: @escaping () -> Monitor<Ephemeral, Terminal>,
                           executeOn executeDispatcher: Dispatching,
                           resolveOn resolveDispatcher: Dispatching) -> Monitor<Ephemeral, Terminal> {
        return BackgroundTask(task: runTask, executeOn: executeDispatcher).run(resolveDispatcher: resolveDispatcher)
    }
    
    public static func run(task runTask: @escaping Consumer<Feed<Ephemeral, Terminal>>,
                           executeOn executeDispatcher: Dispatching,
                           resolveOn resolveDispatcher: Dispatching) -> Monitor<Ephemeral, Terminal> {
        return BackgroundTask(task: runTask, executeOn: executeDispatcher).run(resolveDispatcher: resolveDispatcher)
    }
}

extension BackgroundTask {
    public init<T>(task runTask: @escaping Transform<T, Monitor<Ephemeral, Terminal>>, param: T, executeOn executeDispatcher: Dispatching) {
        self.init(task: { runTask(param) }, executeOn: executeDispatcher)
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
