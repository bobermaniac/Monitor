import Foundation

public extension Vanishable {
    func associate<Target: AnyObject>(with keyPath: ReferenceWritableKeyPath<Target, Optional<Vanishable>>,
                                      of object: Target,
                                      threadSafety: ThreadSafetyStrategy = CalleeSyncGuaranteed()) {
        threadSafety.interlockedWrite {
            object[keyPath: keyPath] = self
        }
        vanished.execute { [weak object] vanishable in
            threadSafety.interlockedWrite { object?[keyPath: keyPath] = nil }
        }
    }

    func associate<Target: AnyObject, Collection: RangeReplaceableCollection>(
        with keyPath: ReferenceWritableKeyPath<Target, Collection>,
        of object: Target,
        threadSafety: ThreadSafetyStrategy = CalleeSyncGuaranteed()
    ) where Collection.Element == Vanishable {
        threadSafety.interlockedWrite { object[keyPath: keyPath].append(self) }
        vanished.execute { [weak object] disposable in
            threadSafety.interlockedWrite { object?[keyPath: keyPath].removeAll(where: { $0.same(as: disposable)} ) }
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
