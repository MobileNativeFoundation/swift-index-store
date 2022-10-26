import Foundation
import CSwiftDemangle

public final class Demangler {
    private let context: demangle_context_t

    public init() {
        self.context = demangle_createContext()
    }

    deinit {
        demangle_destroyContext(context)
    }

    public func demangle(symbol: String) -> DemangledNode? {
        demangle_symbolAsNode(self.context, symbol).map(DemangledNode.init)
    }

    public func clear() {
        demangle_clearContext(self.context)
    }
}
