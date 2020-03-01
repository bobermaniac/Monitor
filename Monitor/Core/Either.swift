import Foundation

public enum Either<LeftType, RightType> {
    case left(LeftType)
    case right(RightType)
}

public protocol Result {
    associatedtype T
    func unwrap() throws -> T
    func unwrapError() -> Error?
}

extension Either: Result where RightType == Error {
    public init(result: T) {
        self = .left(result)
    }
    
    public init(error: Error) {
        self = .right(error)
    }
    
    public init(_ invocation: () throws -> LeftType) {
        do {
            self = .left(try invocation())
        } catch let error {
            self = .right(error)
        }
    }
    
    public func unwrap() throws -> LeftType {
        switch self {
        case .left(let payload):
            return payload
        case .right(let error):
            throw error
        }
    }
    
    public func unwrapError() -> Error? {
        guard case .right(let error) = self else { return nil }
        return error
    }
    
    public typealias T = LeftType
}

// Copyright (C) 2019 by Victor Bryksin <vbryksin@virtualmind.ru>
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee
// is hereby granted.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
// ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
