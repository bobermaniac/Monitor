import Foundation

struct OnDemand<Resource, Arg1> {
    init(factory: @escaping (Arg1) -> Resource) {
        self.factory = factory
    }

    func runIfRequested(_ task: (Resource) throws -> Void) rethrows -> Void {
        guard let resource = self.resource else { return }
        try task(resource)
    }

    mutating func requestResource(_ arg1: Arg1) -> Resource {
        if let resource = self.resource {
            return resource
        }
        let resource = factory(arg1)
        self.resource = resource
        return resource
    }

    private let factory: (Arg1) -> Resource
    private var resource: Resource?
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
