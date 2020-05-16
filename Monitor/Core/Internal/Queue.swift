import Foundation

struct Queue<Element> {
    init() {
        input = Stack()
        output = Stack()
    }

    init<U: Sequence>(_ sequence: U) where U.Element == Element {
        input = Stack()
        output = Stack(sequence.reversed())
    }

    /// A Boolean value indicating whether the queue is empty.
    /// - Complexity: O(1)
    var isEmpty: Bool {
        input.isEmpty && output.isEmpty
    }

    /// First element of the queue if it's not empty, otherwise `nil`
    /// - Complexity: O(1) on average
    var peek: Element? {
        let (_, output) = shift(input: input, output: self.output)
        return output.peek
    }

    /// Adds an element to the end of the queue
    ///
    /// - Parameter t: The element to be added to a queue
    /// - Complexity: O(1)
    mutating func push(_ object: Element) {
        input.push(object)
    }

    /// Removes and returns the first element of the queue
    ///
    /// - Returns: First element of the queue if it's not empty, otherwise `nil`
    /// - Complexity: O(1) on average
    mutating func pop() -> Element? {
        prepareOutput()
        return output.pop()
    }

    /// Removes and returns all elements of the queue
    ///
    /// - Returns: Array with queue elements in dequeue order
    /// - Complexity: O(n) where n is an amount of elements in a queue
    mutating func popAll() -> [Element] {
        prepareOutput()
        var result = [Element]()
        while let value = output.pop() {
            result.append(value)
        }
        return result
    }

    /// The number of elements in the queue
    /// - Complexity: O(1)
    var count: Int {
        input.count + output.count
    }

    private mutating func prepareOutput() {
        (input, output) = shift(input: input, output: output)
    }

    private var input: Stack<Element>
    private var output: Stack<Element>
}

extension Array {
    init(_ queue: Queue<Element>) {
        var copy = queue
        self = copy.popAll()
    }
}

private func shift<T>(input: Stack<T>, output: Stack<T>) -> (Stack<T>, Stack<T>) {
    guard output.isEmpty else { return (input, output) }
    var inputResult = input
    var outputResult = output
    while let value = inputResult.pop() {
        outputResult.push(value)
    }
    return (inputResult, outputResult)
}
