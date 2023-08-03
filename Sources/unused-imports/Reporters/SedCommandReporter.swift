import Foundation

struct SedCommandReporter: UnusedImportReporter {
    func didFind(sourceFilesWithUnusedImports: [SourceFileWithUnusedImports]) {
        for sourceFile in sourceFilesWithUnusedImports.sorted() {
            let sedCmd = sourceFile.unusedImportStatements.map { unusedImport in "\(unusedImport.lineNumber)d" }.joined(separator: ";")
            print("/usr/bin/sed -i \"\" '\(sedCmd)' '\(sourceFile.path)'")
        }
    }
}
