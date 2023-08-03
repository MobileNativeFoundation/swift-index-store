struct UnusedImportStatement: Codable, Comparable {
    let moduleName: String
    let lineNumber: Int

    static func <(lhs: UnusedImportStatement, rhs: UnusedImportStatement) -> Bool {
        return lhs.moduleName < rhs.moduleName
    }
}
