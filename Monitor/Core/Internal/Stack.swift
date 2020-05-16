import Foundation

struct Stack<Element> {
    init() {
        array = []
    }

    init<U: Sequence>(_ sequence: U) where U.Element == Element {
        array = Array(sequence)
    }

    /// Adds an element to the top of the stack
    ///
    /// - Parameter t: The element to be added to a stack
    /// - Complexity: O(1)
    mutating func push(_ t: Element) {
        array.append(t)
    }

    /// Removes and returns the top element of the stack
    ///
    /// - Returns: Top element of the stack if it's not empty, otherwise `nil`
    /// - Complexity: O(1)
    mutating func pop() -> Element? {
        array.popLast()
    }

    /// Top element of the stack if it's not empty, otherwise `nil`
    /// - Complexity: O(1)
    var peek: Element? {
        array.last
    }

    /// A Boolean value indicating whether the stack is empty.
    /// - Complexity: O(1)
    var isEmpty: Bool {
        array.isEmpty
    }

    /// The number of elements in the stack
    /// - Complexity: O(1) due to inner array being RandomAccessCollection
    var count: Int {
        array.count
    }

    private var array: [Element]
}
