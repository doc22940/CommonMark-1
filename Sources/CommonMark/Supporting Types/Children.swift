import cmark

struct Children: Sequence {
    var cmark_node: OpaquePointer

    init(of node: Node) {
        cmark_node = node.cmark_node
    }

    init(of document: Document) {
        cmark_node = document.cmark_node
    }

    func makeIterator() -> AnyIterator<Node> {
        var iterator = CMarkNodeChildIterator(cmark_node)
        return AnyIterator {
            guard let child = iterator.next() else { return nil }
            return Node.create(for: child)
        }
    }
}

struct CMarkNodeChildIterator: IteratorProtocol {
    var current: OpaquePointer!

    init(_ node: OpaquePointer!) {
        current = cmark_node_first_child(node)
    }

    mutating func next() -> OpaquePointer? {
        guard let next = current else { return nil }
        defer { current = cmark_node_next(current) }
        return next
    }
}

// MARK: -

fileprivate func add<Child: Node>(_ child: Child, with operation: () -> Int32) -> Bool {
    let status = operation()
    switch status {
    case 1:
        child.managed = false
        return true
    case 0:
        return false
    default:
        assertionFailure("unexpected status code: \(status)")
        return false
    }

}

// MARK: -

public protocol ContainerOfBlocks: Node {}

extension Document: ContainerOfBlocks {}
extension BlockQuote: ContainerOfBlocks {}
extension List.Item: ContainerOfBlocks {}

extension ContainerOfBlocks {
    public typealias Child = Block & Node

    /// The block's children.
    public var children: [Child] {
        get {
            return Children(of: self).compactMap { $0 as? Child }
        }

        set {
            for child in children {
                remove(child: child)
            }

            for child in newValue {
                append(child: child)
            }
        }
    }

    /**
     Adds a block to the beginning of the block's children.

     - Parameters:
        - child: The block to add.
     - Returns: `true` if successful, otherwise `false`.
     */
    @discardableResult
    public func prepend(child: Child) -> Bool {
        return add(child) { cmark_node_prepend_child(cmark_node, child.cmark_node) }
    }

    /**
     Adds a block to the end of the block's children.

     - Parameters:
        - child: The block to add.
     - Returns: `true` if successful, otherwise `false`.
    */
    @discardableResult
    public func append(child: Child) -> Bool {
        return add(child) { cmark_node_append_child(cmark_node, child.cmark_node) }
    }

    /**
     Inserts a block to the block's children before a specified sibling.

     - Parameters:
        - child: The block to add.
        - sibling: The child before which the block is added
     - Returns: `true` if successful, otherwise `false`.
    */
    @discardableResult
    public func insert(child: Child, before sibling: Child) -> Bool {
        return add(child) { cmark_node_insert_before(child.cmark_node, sibling.cmark_node) }
    }

    /**
     Inserts a block to the block's children after a specified sibling.

     - Parameters:
        - child: The block to add.
        - sibling: The child after which the block is added
     - Returns: `true` if successful, otherwise `false`.
    */
    @discardableResult
    public func insert(child: Child, after sibling: Child) -> Bool {
        return add(child) { cmark_node_insert_after(child.cmark_node, sibling.cmark_node) }
    }

    /**
     Removes a block from the block's children.

     - Parameters:
        - child: The block to remove.
     - Returns: `true` if successful, otherwise `false`.
     */
    @discardableResult
    public func remove(child: Child) -> Bool {
        guard child.parent == self else { return false }
        cmark_node_unlink(child.cmark_node)
        child.managed = true
        return true
    }
}

// MARK: -

public protocol ContainerOfInlineElements: Node {}

extension Heading: ContainerOfInlineElements {}
extension Paragraph: ContainerOfInlineElements {}
extension HTMLBlock: ContainerOfInlineElements {}
extension CodeBlock: ContainerOfInlineElements {}
extension ThematicBreak: ContainerOfInlineElements {}
extension Strong: ContainerOfInlineElements {}
extension Emphasis: ContainerOfInlineElements {}
extension Link: ContainerOfInlineElements {}

extension ContainerOfInlineElements {
    public typealias Child = Inline & Node

    /// The block's children.
    public var children: [Child] {
        get {
            return Children(of: self).compactMap { $0 as? Child }
        }

        set {
            for child in children {
                remove(child: child)
            }

            for child in newValue {
                append(child: child)
            }
        }
    }

    /**
     Adds an inline element to the beginning of the block's children.

     - Parameters:
        - child: The inline element to add.
     - Returns: `true` if successful, otherwise `false`.
     */
    @discardableResult
    public func prepend(child: Child) -> Bool {
        return add(child) { cmark_node_prepend_child(cmark_node, child.cmark_node) }
    }

    /**
     Adds an inline element to the end of the block's children.

     - Parameters:
        - child: The inline element to add.
     - Returns: `true` if successful, otherwise `false`.
    */
    @discardableResult
    public func append(child: Child) -> Bool {
        return add(child) { cmark_node_append_child(cmark_node, child.cmark_node) }
    }

    /**
     Inserts an inline element to the block's children before a specified sibling.

     - Parameters:
        - child: The inline element to add.
        - sibling: The child before which the inline element is added
     - Returns: `true` if successful, otherwise `false`.
    */
    @discardableResult
    public func insert(child: Child, before sibling: Child) -> Bool {
        return add(child) { cmark_node_insert_before(child.cmark_node, sibling.cmark_node) }
    }

    /**
     Inserts an inline element to the block's children after a specified sibling.

     - Parameters:
        - child: The inline element to add.
        - sibling: The child after which the inline element is added
     - Returns: `true` if successful, otherwise `false`.
    */
    @discardableResult
    public func insert(child: Child, after sibling: Child) -> Bool {
        return add(child) { cmark_node_insert_after(child.cmark_node, sibling.cmark_node) }
    }

    /**
     Removes an inline element from the block's children.

     - Parameters:
        - child: The inline element to remove.
     - Returns: `true` if successful, otherwise `false`.
     */
    @discardableResult
    public func remove(child: Child) -> Bool {
        guard child.parent == self else { return false }
        cmark_node_unlink(child.cmark_node)
        child.managed = true
        return true
    }
}

// MARK: -

extension List {
    /// The block's children.
    public var children: [Item] {
        get {
            return Children(of: self).compactMap { $0 as? Item }
        }

        set {
            for child in children {
                remove(child: child)
            }

            for child in newValue {
                append(child: child)
            }
        }
    }

    /**
     Adds a block to the beginning of the block's children.

     - Parameters:
        - child: The block to add.
     - Returns: `true` if successful, otherwise `false`.
     */
    @discardableResult
    public func prepend(child: Item) -> Bool {
        return add(child) { cmark_node_prepend_child(cmark_node, child.cmark_node) }
    }

    /**
     Adds a block to the end of the block's children.

     - Parameters:
        - child: The block to add.
     - Returns: `true` if successful, otherwise `false`.
    */
    @discardableResult
    public func append(child: Item) -> Bool {
        return add(child) { cmark_node_append_child(cmark_node, child.cmark_node) }
    }

    /**
     Inserts a block to the block's children before a specified sibling.

     - Parameters:
        - child: The block to add.
        - sibling: The child before which the block is added
     - Returns: `true` if successful, otherwise `false`.
    */
    @discardableResult
    public func insert(child: Item, before sibling: Item) -> Bool {
        return add(child) { cmark_node_insert_before(child.cmark_node, sibling.cmark_node) }
    }

    /**
     Inserts a block to the block's children after a specified sibling.

     - Parameters:
        - child: The block to add.
        - sibling: The child after which the block is added
     - Returns: `true` if successful, otherwise `false`.
    */
    @discardableResult
    public func insert(child: Item, after sibling: Item) -> Bool {
        return add(child) { cmark_node_insert_after(child.cmark_node, sibling.cmark_node) }
    }

    /**
     Removes a block from the block's children.

     - Parameters:
        - child: The block to remove.
     - Returns: `true` if successful, otherwise `false`.
     */
    @discardableResult
    public func remove(child: Item) -> Bool {
         guard child.parent == self else { return false }
         cmark_node_unlink(child.cmark_node)
         child.managed = true
         return true
    }
}