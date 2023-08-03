struct SourceFileWithUnusedImports: Codable, Comparable {
    let path: String
    let unusedImportStatements: [UnusedImportStatement]

    static func <(lhs: SourceFileWithUnusedImports, rhs: SourceFileWithUnusedImports) -> Bool {
        return lhs.path < rhs.path
    }
}
