import Foundation
import Monitor
import XCTest

final class Example5: XCTestCase {
    func test() {
        let ifConfig = IFConfig()
        let stunServer = STUNServer()
        let candidatedCollector = ICECandidatesCollector()
        let verifier = ICECandidatesVerifier()

        let ips = start(tasks: [ifConfig.acquireLocalIPAddress, stunServer.acquireRemoteIPAddress])
        let iceCandidates = ips.flatMap(ephemeral: candidatedCollector.acquireICECandidates(for:))
        let okCandidate = iceCandidates.first(where: verifier.connect(to:))

        let token = okCandidate.resolved(handler: { print($0) })

        while dispatcher.dispatchNext(timeInterval: 0.1) { }
        XCTAssertNotNil(token)
    }
}

private typealias IP = (UInt8, UInt8, UInt8, UInt8)

private final class IFConfig {
    func acquireLocalIPAddress() -> Future<IP> {
        let acquiringIp = Promise(of: IP.self)
        dispatcher.async(after: 2, flags: .barrier) {
            acquiringIp.resolve(with: (192, 168, 0, 150))
        }
        return acquiringIp.future
    }
}

private final class STUNServer {
    func acquireRemoteIPAddress() -> Future<IP> {
        let acquiringIp = Promise(of: IP.self)
        dispatcher.async(after: 5, flags: .barrier) {
            acquiringIp.resolve(with: (221, 55, 85, 61))
        }
        return acquiringIp.future
    }
}

private final class ICECandidatesCollector {
    func acquireICECandidates(for ip: IP) -> Observable<IP> {
        let source = EventSource(of: IP.self)
        for i in 1..<7 {
            dispatcher.async(after: Double(i), flags: []) {
                source.next(event: (ip.0, ip.1, 0, UInt8(i)))
            }
        }
        dispatcher.async(after: 8, flags: .barrier) {
            source.complete()
        }
        return source.observable
    }
}

private final class ICECandidatesVerifier {
    func connect(to ip: IP) -> Future<Bool> {
        let result = Promise(of: Bool.self)
        dispatcher.async(after: 2, flags: .barrier) {
            result.resolve(with: ip == (221, 55, 0, 4))
        }
        return result.future
    }
}

private func start<T>(tasks: [() -> Future<T>]) -> Observable<T> {
    let result = EventSource(of: T.self)

    let pendingResults = tasks.map { $0() }
    for pendingResult in pendingResults {
        let token = pendingResult.resolved(handler: result.next(event:))
        result.canceled(callback: token.cancel)
    }
    let completionToken = all(of: pendingResults).resolved(handler: { _ in result.complete() })
    result.canceled(callback: completionToken.cancel)

    return result.observable
}

private extension Monitor {
    func first(where asyncPredicate: @escaping Transform<Ephemeral, Future<Bool>>) -> Future<Ephemeral> {
        let result = Promise(of: Ephemeral.self)
        let token = observe(ephemeral: { e in
            let innerToken = asyncPredicate(e).resolved(handler: { success in
                if success {
                    result.resolve(with: e)
                }
            })
            result.canceled(callback: innerToken.cancel)
        }, terminal: { _ in })
        result.canceled(callback: token.cancel)
        return result.future
    }
}

private let dispatcher = ManualDispatcher(name: "main", simultaneousOperationCount: 1)

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
