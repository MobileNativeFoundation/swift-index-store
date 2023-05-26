import IndexStore
import Foundation

private let kProtocolChildrenTypes: [SymbolKind] = [
    .instanceMethod, .classMethod, .staticMethod,
    .instanceProperty, .classProperty, .staticProperty,
]
private let testableRegex = try NSRegularExpression(
    pattern: "^\\@testable import ([^ .]+)$", options: [.anchorsMatchLines])

private func getTestableImports(path: String) -> Set<String> {
    guard let searchText = try? String(contentsOfFile: path) else {
        fatalError("failed to read '\(path)'")
    }

    let matches = testableRegex.matches(
        in: searchText, range: NSRange(searchText.startIndex..<searchText.endIndex, in: searchText))

    return Set(matches.map { match in
        guard let range = Range(match.range(at: 1), in: searchText) else {
            fatalError("error: failed to get regex match: \(path)")
        }

        return String(searchText[range])
    })
}

private func getReferenceUSRs(unitReader: UnitReader, unitToRecord: [String: RecordReader]) -> Set<String> {
    // Empty source files have units but no records
    guard let recordReader = unitToRecord[unitReader.mainFile] else {
        return []
    }

    var usrs = Set<String>()
    recordReader.forEach { (occurrence: SymbolOccurrence) in
        if occurrence.roles.contains(.reference) {
            usrs.insert(occurrence.symbol.usr)
        }
    }

    return usrs
}

// TODO: Improve this. Issues:
// - This doesn't correctly handle members of a 'public extension' which are implicitly public. We lint away
//   this use case
// - This doesn't handle 'public func' in an internal type definition. Swift allows this but we lint this away
//   with SwiftLint's 'lower_acl_than_parent' rule
// - This incorrectly handles enum cases, assuming they're all public and that the file will also reference
//   the enum definition itself, which will be resolved correctly. We didn't have any cases that violated this
//   but it might be possible if we check against a function that is public and returns an internal enum case
//   that we compare against
// - This incorrectly handles internal(set) such that even if we only call the getter of something we will
//   assume the testable is required
// - This doesn't handle functions in the body of a public protocol since that line is not marked public only
//   the protocol itself is
// - This doesn't differentiate between `public` and `public final`, so if you subclass the class you need
//   the testable import in the `public` case
private func isPublic(file: String, occurrence: SymbolOccurrence) -> Bool {
    // Assume implicit declarations (generated memberwise initializers) require testable
    if occurrence.roles.contains(.implicit) && !occurrence.roles.contains(.accessorOf) {
        return false
    }

    let contents = try! String(contentsOfFile: file)
    let text = contents.components(separatedBy: .newlines)[occurrence.location.line - 1]

    // enum cases aren't explicitly marked public but inherit their ACL from their type definition. This is
    // overly permissive since the enum could be internal, but it's very likely the file also contains a
    // reference to the actual enum in that case, which will correctly bet determined to be public/internal,
    // so it should still resolve the testable import correctly.
    if text.contains("case ") {
        return true
    }

    let isPublic = text.contains("public ") || text.contains("open ")
    // Handle public members that explicitly set 'internal(set)' for allowing setting from tests
    return isPublic && !text.contains(" internal(")
}

/// Determine whether a SymbolOccurrence is a child if a protocol or not. If this symbol is a child of a
/// protocol it can be ignored because the protocol reference will be used instead to determine if testable is
/// required since it will have an ACL on the same line as the definition where the protocol function
/// definition will not.
private func isChildOfProtocol(occurrence: SymbolOccurrence) -> Bool {
    if !kProtocolChildrenTypes.contains(occurrence.symbol.kind) {
        return false
    }

    var isChildOfProtocol = false
    occurrence.forEach { (symbol: Symbol, roles: SymbolRoles) in
        if roles.contains(.childOf) && symbol.kind == .protocol {
            isChildOfProtocol = true
        }
    }

    return isChildOfProtocol
}

// In the case you have a type like:
//
// protocol Foo { var bar: String { get } }
//
// or:
//
// struct Foo { var bar: String { get { "" } } }
//
// The references in the index from callers of 'bar' reference both the 'bar' definition as well as the
// 'instance method' definition defined at the location of 'get'. In this case for protocols we want to
// inherit the ACL of the protocol itself, which is handled by isChildOfProtocol, and otherwise produces a
// false negative because the parent of 'get' is 'bar' which is considered internal on prtocols. This function
// allows us to ignore the duplicate reference of the 'get' and only use the 'bar' reference to determine if
// testable is required.
private func isGetterOrSetterFunction(occurrence: SymbolOccurrence) -> Bool {
    let functionTypes: [SymbolKind] = [.classMethod, .instanceMethod,  .staticMethod]
    if !functionTypes.contains(occurrence.symbol.kind) {
        return false
    }

    return occurrence.roles.contains(.accessorOf)
}

private func collectUnitsAndRecords(indexStorePath: String) -> ([UnitReader], [String: RecordReader]) {
    let store: IndexStore
    do {
        store = try IndexStore(path: indexStorePath)
    } catch {
        fatalError("error: failed to open index store: \(error)")
    }

    var units: [UnitReader] = []
    var unitToRecord: [String: RecordReader] = [:]

    for unitReader in store.units {
        if unitReader.mainFile.isEmpty {
            continue
        }

        units.append(unitReader)
        if let recordName = unitReader.recordName {
            let recordReader: RecordReader
            do {
                recordReader = try RecordReader(indexStore: store, recordName: recordName)
            } catch {
                fatalError("error: failed to load record: \(recordName) \(error)")
            }

            if unitToRecord[unitReader.mainFile] != nil {
                fatalError("error: found duplicate record for \(unitReader.mainFile)")
            }

            unitToRecord[unitReader.mainFile] = recordReader
        }
    }

    if units.isEmpty {
        fatalError("error: failed to load units from \(indexStorePath)")
    }

    return (units, unitToRecord)
}

private func isGeneratedFile(_ path: String) -> Bool {
    return path.hasSuffix(".generated.swift")
}

func main(indexStorePath: String) {
    if let directory = ProcessInfo.processInfo.environment["BUILD_WORKSPACE_DIRECTORY"] {
        FileManager.default.changeCurrentDirectoryPath(directory)
    }

    let (units, unitToRecord) = collectUnitsAndRecords(indexStorePath: indexStorePath)
    for unitReader in units {
        if isGeneratedFile(unitReader.mainFile) {
            continue
        }

        let testableImports = getTestableImports(path: unitReader.mainFile)
        if testableImports.isEmpty {
            continue
        }

        let referencedUSRs = getReferenceUSRs(unitReader: unitReader, unitToRecord: unitToRecord)
        var seenModules = Set<String>()
        var requiredTestableImports = Set<String>()
        for dependentUnit in units {
            guard let recordReader = unitToRecord[dependentUnit.mainFile] else {
                continue
            }

            let moduleName = dependentUnit.moduleName.replacingOccurrences(of: "Tests", with: "")
            guard testableImports.contains(moduleName) else {
                continue
            }

            seenModules.insert(moduleName)

            recordReader.forEach { (occurrence: SymbolOccurrence) in
                if
                    occurrence.roles.contains(.definition) &&
                    referencedUSRs.contains(occurrence.symbol.usr) &&
                    !isChildOfProtocol(occurrence: occurrence) &&
                    !isGetterOrSetterFunction(occurrence: occurrence) &&
                    !isPublic(file: dependentUnit.mainFile, occurrence: occurrence)
                {
                    requiredTestableImports.insert(moduleName)
                }
            }
        }

        let missingTestableModules = testableImports.subtracting(seenModules)
        if !missingTestableModules.isEmpty {
            fatalError("error: some modules import with @testable were not included in the index \(unitReader.mainFile): \(missingTestableModules)")
        }

        for module in testableImports.intersection(seenModules).subtracting(requiredTestableImports) {
            print("/usr/bin/sed -i \"\" 's/^@testable import \(module)$/import \(module)/g' \(unitReader.mainFile)")
        }
    }
}

main(indexStorePath: CommandLine.arguments[1])
