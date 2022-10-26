import Foundation
import CSwiftDemangle

public typealias DemangledNodeKind = demangle_node_kind_t

public struct DemangledNode {
    private var rawNode: demangle_node_t

    init(_ rawNode: demangle_node_t) {
        self.rawNode = rawNode
    }

    public var kind: DemangledNodeKind {
        return node_getKind(self.rawNode)
    }

    public var text: String? {
        guard node_hasText(self.rawNode) else {
            return nil
        }

        var count = 0
        let pointer = node_getText(self.rawNode, &count)
        let buffer = UnsafeRawBufferPointer(start: pointer, count: count)
        return String(decoding: buffer, as: UTF8.self)
    }

    public var index: Int? {
        guard node_hasIndex(self.rawNode) else {
            return nil
        }

        return Int(node_getIndex(self.rawNode))
    }

    public var children: [DemangledNode] {
        let count = node_getNumChildren(self.rawNode)
        return (0..<count).map { childIndex in
            DemangledNode(node_getChild(self.rawNode, childIndex))
        }
    }

    /// Linear sequence of the demangled nodes, in breadth first order.
    public func breadthFirstSequence() -> AnySequence<DemangledNode> {
        return AnySequence(sequence(state: [self], next: { queue in
            if queue.isEmpty {
                return nil
            }

            let head = queue.removeFirst()
            queue.append(contentsOf: head.children)
            return head
        }))
    }
}

extension DemangledNodeKind: CustomDebugStringConvertible {
    public var debugDescription: String {
        String(cString: node_getKindName(self))
    }
}
