struct TypeGraph {
    // The graph is two trees, represented as dictionaries. Keys are types.
    // In `subtypes`, the key is the supertype and the values are its subtypes.
    // In `supertypes`, the key is the subtype and the values are its supertypes.
    var subtypes: [String: Set<String>] = [:]
    var supertypes: [String: Set<String>] = [:]

    mutating func add(subtype: String, of supertype: String) {
        self.subtypes[supertype, default: []].insert(subtype)
        self.supertypes[subtype, default: []].insert(supertype)
    }

    func subtypes(of type: String, _ path: [String] = []) -> [[String]] {
        var newPath = path
        newPath.append(type)

        let subtypes = self.subtypes[type, default: []]
        if subtypes.isEmpty {
            return [newPath]
        }

        return subtypes.flatMap { self.subtypes(of: $0, newPath) }
    }

    func supertypes(of type: String, _ path: [String] = []) -> [[String]] {
        var newPath = path
        newPath.append(type)

        let subtypes = self.supertypes[type, default: []]
        if subtypes.isEmpty {
            return [newPath]
        }

        return subtypes.flatMap { self.supertypes(of: $0, newPath) }
    }
}
