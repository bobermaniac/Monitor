import Foundation

enum ContextAccessor<Content> {
    init(_ context: FreeContext<Content>) {
        self = .free(context)
    }

    init(_ context: SynchronizedContext<Content>, threadSafety: ThreadSafetyStrategy) {
        self = .synchronized(context, threadSafety)
    }

    case free(FreeContext<Content>)
    case synchronized(SynchronizedContext<Content>, ThreadSafetyStrategy)

    func read<Result>(block: (Content) throws -> Result) rethrows -> Result {
        switch self {
        case .free(let context):
            return try context.read(block: block)
        case .synchronized(let context, let threadSafety):
            return try context.read(using: threadSafety, block: block)
        }
    }

    func readWrite<Result>(block: (inout Content) throws -> Result) rethrows -> Result {
        switch self {
        case .free(let context):
            return try context.readWrite(block: block)
        case .synchronized(let context, let threadSafety):
            return try context.readWrite(using: threadSafety, block: block)
        }
    }

    func weakify() -> WeakContextAccessor<Content> {
        switch self {
        case .free(let context):
            return WeakContextAccessor(context)
        case .synchronized(let context, let threadSafety):
            return WeakContextAccessor(context, threadSafety: threadSafety)
        }
    }
}

enum WeakContextAccessor<Content> {
    init(_ context: FreeContext<Content>) {
        self = .free(Weak(context))
    }

    init(_ context: SynchronizedContext<Content>, threadSafety: ThreadSafetyStrategy) {
        self = .synchronized(Weak(context), threadSafety)
    }

    case free(Weak<FreeContext<Content>>)
    case synchronized(Weak<SynchronizedContext<Content>>, ThreadSafetyStrategy)

    func read<Result>(block: (Content) throws -> Result) rethrows -> Result? {
        switch self {
        case .free(let weakContext):
            return try weakContext.payload?.read(block: block)
        case .synchronized(let weakContext, let threadSafety):
            return try weakContext.payload?.read(using: threadSafety, block: block)
        }
    }

    func readWrite<Result>(block: (inout Content) throws -> Result) rethrows -> Result? {
        switch self {
        case .free(let weakContext):
            return try weakContext.payload?.readWrite(block: block)
        case .synchronized(let weakContext, let threadSafety):
            return try weakContext.payload?.readWrite(using: threadSafety, block: block)
        }
    }

    func strongify() -> ContextAccessor<Content>? {
        switch self {
        case .free(let weakContext):
            guard let context = weakContext.payload else { return nil }
            return ContextAccessor(context)
        case .synchronized(let weakContext, let threadSafety):
            guard let context = weakContext.payload else { return nil }
            return ContextAccessor(context, threadSafety: threadSafety)
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
