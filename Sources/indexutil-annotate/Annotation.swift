import IndexStore

struct Annotation {
    let symbol: String
    let usr: String
    let kind: String
    let subkind: String?
    /// Line number of symbol, zero based.
    let line: Int
    /// Column number of symbol, zero based.
    let column: Int

    init(_ symbolOccurrence: SymbolOccurrence) {
        self.symbol = symbolOccurrence.symbol.name
        self.usr = symbolOccurrence.symbol.usr
        self.line = symbolOccurrence.location.line - 1
        self.column = symbolOccurrence.location.column - 1
        self.kind = symbolOccurrence.symbol.kind.description
        let subkind = symbolOccurrence.symbol.subkind
        self.subkind = subkind != .none ? subkind.description : nil
    }
}

extension Annotation: CustomStringConvertible {
    var description: String {
        var kind = self.kind
        if let subkind = self.subkind {
            kind += ".\(subkind)"
        }
        return "\(kind)=\(self.symbol)=\(self.usr)"
    }
}
