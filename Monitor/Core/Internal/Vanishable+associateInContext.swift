import Foundation

extension Vanishable {
    func associate<Content>(with keyPath: WritableKeyPath<Content, Optional<Vanishable>>,
                            in context: ContextAccessor<Content>) {
        context.readWrite { (content: inout Content) in
            content[keyPath: keyPath] = self
        }
        let weakContext = context.weakify()
        vanished.execute { _ in
            weakContext.readWrite { (content: inout Content) in
                content[keyPath: keyPath] = nil
            }
        }
    }

    func associate<Content, Collection: RangeReplaceableCollection>(
        with keyPath: WritableKeyPath<Content, Collection>,
        in context: ContextAccessor<Content>
    ) where Collection.Element == Vanishable {
        context.readWrite { (content: inout Content) in
            content[keyPath: keyPath].append(self)
        }
        let weakContext = context.weakify()
        vanished.execute { vanishable in
            weakContext.readWrite { (content: inout Content) in
                content[keyPath: keyPath].removeAll(where: { $0.same(as: vanishable) })
            }
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
