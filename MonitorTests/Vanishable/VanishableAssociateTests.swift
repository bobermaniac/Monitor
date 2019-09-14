import Foundation
import Monitor
import XCTest

final class VanishableAssociateTests: XCTestCase {
    func testSetsSelfToProprtyOnAssociation() {
        let probe = ProbeA()
        let vanisher = Vanisher()

        vanisher.associate(with: \.token, of: probe)

        XCTAssertTrue(probe.token?.same(as: vanisher) ?? false)
    }

    func testRemovesSelfFromProprtyOnAssociation() {
        let probe = ProbeA()
        let vanisher = Vanisher()

        vanisher.associate(with: \.token, of: probe)
        vanisher.cancel()

        XCTAssertNil(probe.token)
    }

    func testVanisherDoesNotOwnProbe() {
        weak var probe: ProbeA?
        var vanisher: Vanisher?

        repeat {
            let strongProbe = ProbeA()
            vanisher = Vanisher()
            vanisher?.associate(with: \.token, of: strongProbe)

            probe = strongProbe
            XCTAssertNotNil(probe)
        } while false

        XCTAssertNil(probe)
    }

    func testInsertsSelfToCollectionProprtyOnAssociation() {
        let probe = ProbeB()
        let vanisher1 = Vanisher()
        let vanisher2 = Vanisher()

        vanisher1.associate(with: \.tokens, of: probe)
        vanisher2.associate(with: \.tokens, of: probe)

        XCTAssertEqual(probe.tokens.count, 2)
        XCTAssertTrue(probe.tokens[0].same(as: vanisher1))
        XCTAssertTrue(probe.tokens[1].same(as: vanisher2))
    }

    func testRemovesSelfFromColelctionProprtyOnAssociation() {
        let probe = ProbeB()
        let vanisher1 = Vanisher()
        let vanisher2 = Vanisher()

        vanisher1.associate(with: \.tokens, of: probe)
        vanisher2.associate(with: \.tokens, of: probe)

        vanisher1.cancel()
        XCTAssertEqual(probe.tokens.count, 1)
        XCTAssertTrue(probe.tokens[0].same(as: vanisher2))

        vanisher2.cancel()
        XCTAssertEqual(probe.tokens.count, 0)
    }

    func testVanishersDoesNotOwnProbe() {
        weak var probe: ProbeB?
        var vanisher1: Vanisher?
        var vanisher2: Vanisher?

        repeat {
            let strongProbe = ProbeB()
            vanisher1 = Vanisher()
            vanisher1?.associate(with: \.tokens, of: strongProbe)
            vanisher2 = Vanisher()
            vanisher2?.associate(with: \.tokens, of: strongProbe)

            probe = strongProbe
            XCTAssertNotNil(probe)
        } while false

        XCTAssertNil(probe)
    }
}

private final class ProbeA {
    var token: Vanishable?
}

private final class ProbeB {
    var tokens = [] as [Vanishable]
}

private final class Vanisher: Vanishable {
    var vanished: VanishEventObservable {
        return vanishEvents
    }

    func same(as vanishable: Vanishable) -> Bool {
        return (vanishable as? Vanisher) === self
    }

    func cancel() {
        canceled = true
        vanishEvents.runCallbacks(wtih: self)
    }

    private var canceled = false
    private lazy var vanishEvents = VanishEvents(parent: self)

    private final class VanishEvents: VanishEventObservable {
        init(parent: Vanisher) {
            self.vanisher = parent
        }

        func execute(callback: @escaping Consumer<Vanishable>) {
            guard let vanisher = self.vanisher else { fatalError() }

            if vanisher.canceled {
                callback(vanisher)
            } else  {
                callbacks.append(callback)
            }
        }

        func runCallbacks(wtih vanisher: Vanisher) {
            let newCallbacks = callbacks
            callbacks.removeAll()
            newCallbacks.forEach { $0(vanisher) }
        }

        var callbacks = [] as [Consumer<Vanishable>]
        private weak var vanisher: Vanisher?
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
