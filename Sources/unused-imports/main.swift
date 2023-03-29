import IndexStore
import Darwin
import Foundation

// FIXME: This isn't complete
private let identifierRegex = try NSRegularExpression(
    pattern: "([a-zA-Z_][a-zA-Z0-9_]*)", options: [])
private let importRegex = try Regex(#"\bimport\b"#)
private let ignoreRegex = try Regex(#"// *ignore-import"#)

private func getImports(path: String, recordReader: RecordReader?) -> (Set<String>, [String: Int]) {
    guard let recordReader else {
        return ([], [:])
    }

    var importsToLineNumbers = [String: Int]()
    let lines = try! String(contentsOfFile: path).split(separator: "\n", omittingEmptySubsequences: false)

    var imports = Set<String>()
    recordReader.forEach { (occurrence: SymbolOccurrence) in
        if occurrence.symbol.kind == .module && occurrence.roles.contains(.reference) {
            let line = lines[occurrence.location.line - 1]
            // FIXME: This won't work if we are also adding missing imports, return it separately
            if line.firstMatch(of: importRegex) != nil && line.firstMatch(of: ignoreRegex) == nil {
                imports.insert(occurrence.symbol.name)
                importsToLineNumbers[occurrence.symbol.name] = occurrence.location.line
            }
        }
    }

    return (imports, importsToLineNumbers)
}

private func getReferenceUSRs(unitReader: UnitReader, recordReader: RecordReader?) -> Storage {
    // Empty source files have units but no records
    guard let recordReader else {
        return Storage(usrs: [], typealiases: [])
    }

    var lines: [String.SubSequence]?
    var usrs = Set<String>()
    var typealiasExts = Set<String>()
    recordReader.forEach { (occurrence: SymbolOccurrence) in
        if occurrence.symbol.subkind == .swiftExtensionOfStruct  {
            usrs.insert(occurrence.symbol.usr)
            if lines == nil {
                lines = try! String(contentsOfFile: unitReader.mainFile).split(separator: "\n", omittingEmptySubsequences: false)
            }

            let line = String(lines![occurrence.location.line - 1])
            let indexes = line.index(line.startIndex, offsetBy: occurrence.location.column - 1)..<line.endIndex
            let range = NSRange(indexes, in: line)
            // FIXME: extension [Int] doesn't match
            guard let identifierRange = identifierRegex.firstMatch(in: line, range: range)?.range(at: 1) else {
                // print("no identifier line is: \(line[indexes]) in \(unitReader.mainFile)")
                return
            }
            let identifier = String(line[Range(identifierRange, in: line)!])
            if identifier != occurrence.symbol.name {
                typealiasExts.insert(identifier)
            }
        } else if occurrence.roles.contains(.reference) {
            usrs.insert(occurrence.symbol.usr)
        }
    }

    return Storage(usrs: usrs, typealiases: typealiasExts)
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
            do {
                let recordReader = try RecordReader(indexStore: store, recordName: recordName)
                unitToRecord[unitReader.mainFile] = recordReader
            } catch {
                fatalError("error: failed to load record: \(recordName) \(error)")
            }
        }
    }

    if units.isEmpty {
        fatalError("error: failed to load units from \(indexStorePath)")
    }

    return (units, unitToRecord)
}

struct Storage {
    let usrs: Set<String>
    let typealiases: Set<String>
}

func main(
    indexStorePath: String,
    ignoredFileRegex: Regex<AnyRegexOutput>?,
    ignoredModuleRegex: Regex<AnyRegexOutput>?)
{
    if let directory = ProcessInfo.processInfo.environment["BUILD_WORKSPACE_DIRECTORY"] {
        FileManager.default.changeCurrentDirectoryPath(directory)
    }

    let pwd = FileManager.default.currentDirectoryPath
    var filesToUSRDefinitions: [String: Storage] = [:]
    let (units, unitToRecord) = collectUnitsAndRecords(indexStorePath: indexStorePath)
    var modulesToUnits: [String: [UnitReader]] = [:]
    var allModuleNames = Set<String>()
    for unitReader in units {
        allModuleNames.insert(unitReader.moduleName)
        modulesToUnits[unitReader.moduleName, default: []].append(unitReader)

        if let recordReader = unitToRecord[unitReader.mainFile] {
            var definedUsrs = Set<String>()
            var definedTypealiases = Set<String>()

            recordReader.forEach { (occurrence: SymbolOccurrence) in
                if occurrence.roles.contains(.definition) {
                    definedUsrs.insert(occurrence.symbol.usr)
                    if occurrence.symbol.kind == .typealias {
                        definedTypealiases.insert(occurrence.symbol.name)
                    }
                }

            }

            filesToUSRDefinitions[unitReader.mainFile] = Storage(
                usrs: definedUsrs, typealiases: definedTypealiases)
        }
    }

    for unitReader in units {
        if let ignoredFileRegex, unitReader.mainFile.wholeMatch(of: ignoredFileRegex) != nil {
            continue
        } else if let ignoredModuleRegex, unitReader.moduleName.wholeMatch(of: ignoredModuleRegex) != nil {
            continue
        }

        let (rawImports, importsToLineNumbers) = getImports(
            path: unitReader.mainFile, recordReader: unitToRecord[unitReader.mainFile])
        let allImports = rawImports.intersection(allModuleNames)
        if allImports.isEmpty {
            continue
        }

        let referencedUSRs = getReferenceUSRs(
            unitReader: unitReader, recordReader: unitToRecord[unitReader.mainFile])
        var usedImports = Set<String>()
        for anImport in allImports {
            for dependentUnit in modulesToUnits[anImport] ?? [] {
                if usedImports.contains(anImport) {
                    break
                }

                // Empty files have units but no records and therefore no usrs
                guard let storage = filesToUSRDefinitions[dependentUnit.mainFile] else {
                    continue
                }

                if !storage.usrs.intersection(referencedUSRs.usrs).isEmpty {
                    usedImports.insert(dependentUnit.moduleName)
                } else if !storage.typealiases.intersection(referencedUSRs.typealiases).isEmpty {
                    // If the typealias isn't already imported then it's probably not the one we're looking for
                    if allImports.contains(dependentUnit.moduleName) {
                        usedImports.insert(dependentUnit.moduleName)
                    }
                }
            }

            if allImports.subtracting(usedImports).isEmpty {
                break
            }
        }

        let unusedImports = allImports.subtracting(usedImports)
        if !unusedImports.isEmpty {
            let sedCmd = unusedImports.map { "\(importsToLineNumbers[$0]!)d" }.sorted().joined(separator: ";")
            let relativePath = unitReader.mainFile.replacingOccurrences(of: pwd + "/", with: "")
            print("/usr/bin/sed -i \"\" '\(sedCmd)' \(relativePath)")
        }
    }
}

if CommandLine.arguments.count == 4 {
    let ignoredFileRegex = try Regex(CommandLine.arguments[2])
    let ignoredModuleRegex = try Regex(CommandLine.arguments[3])

    main(
        indexStorePath: CommandLine.arguments[1],
        ignoredFileRegex: ignoredFileRegex,
        ignoredModuleRegex: ignoredModuleRegex
    )
} else {
    main(
        indexStorePath: CommandLine.arguments[1],
        ignoredFileRegex: nil,
        ignoredModuleRegex: nil
    )
}
