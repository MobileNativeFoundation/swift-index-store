import Foundation

struct JSONReporter: UnusedImportReporter {
    func didFind(sourceFilesWithUnusedImports: [SourceFileWithUnusedImports]) {
        let jsonEncoder = JSONEncoder()
        let removableImportsJSONData = try! jsonEncoder.encode(sourceFilesWithUnusedImports)
        let removableImportsJSONString = String(data: removableImportsJSONData, encoding: String.Encoding.utf8)!
        
        print(removableImportsJSONString)
    }
}
