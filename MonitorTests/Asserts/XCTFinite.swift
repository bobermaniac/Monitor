//
//  XCTFinite.swift
//  MonitorTests
//
//  Created by Виктор Брыксин on 01.03.2020.
//  Copyright © 2020 Yandex LLC. All rights reserved.
//

import Foundation
import XCTest

extension Sequence where Element == ManualDispatcher {
    func XCTFinite(maxNumberOfInvocations: UInt = 1000,
                   file: StaticString = #file,
                   line: UInt = #line) {
        for _ in 0..<maxNumberOfInvocations {
            var hasInvocation = false
            for dispatcher in self {
                hasInvocation = hasInvocation || dispatcher.dispatchNext(timeInterval: 1)
            }
            if !hasInvocation {
                return
            }
        }
        XCTFail("After \(maxNumberOfInvocations) there is still pending blocks",
                file: file,
                line: line)
    }
}
