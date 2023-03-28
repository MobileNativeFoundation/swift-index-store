import IndexStore
import Darwin
import Foundation

// FIXME: Loosen this regex
// FIXME: this ignores 'import foo.bar' and all other 'import struct foo.bar' things
private let testableRegex = try NSRegularExpression(
    pattern: #"^[^/\n]*\bimport ([^ \n.]+)( *// *noqa)?$"#, options: [.anchorsMatchLines])
// FIXME: This isn't complete
private let identifierRegex = try NSRegularExpression(
    pattern: "([a-zA-Z_][a-zA-Z0-9_]*)", options: [])

private func getImports(path: String) -> Set<String> {
    guard let searchText = try? String(contentsOfFile: path) else {
        fatalError("failed to read '\(path)'")
    }

    let matches = testableRegex.matches(
        in: searchText, range: NSRange(searchText.startIndex..<searchText.endIndex, in: searchText))

    return Set(matches.compactMap { match in
        guard let range = Range(match.range(at: 1), in: searchText) else {
            fatalError("error: failed to get regex match: \(path)")
        }

        if let range = Range(match.range(at: 2), in: searchText) {
            let comment = String(searchText[range])
            if comment.contains("noqa") {
                // FIXME: This won't work if we are also adding missing imports, return it separately
                return nil
            }
        }

        return String(searchText[range])
    })
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
        } else if occurrence.roles.contains(.reference){
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
            let recordReader: RecordReader
            do {
                recordReader = try RecordReader(indexStore: store, recordName: recordName)
            } catch {
                fatalError("error: failed to load record: \(recordName) \(error)")
            }

            // FIXME: Duplicates can happen if a single file is included in multiple targets / configurations
            // if let existingRecord = unitToRecord[unitReader.mainFile] {
            //     // fatalError("error: found duplicate record for \(unitReader.mainFile) in \(existingRecord.name) and \(recordReader.name)")
            // }

            unitToRecord[unitReader.mainFile] = recordReader
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

        let allImports = getImports(path: unitReader.mainFile).intersection(allModuleNames)
        if allImports.isEmpty {
            continue
        }

        let referencedUSRs = getReferenceUSRs(unitReader: unitReader, recordReader: unitToRecord[unitReader.mainFile])
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
                }

                if !storage.typealiases.intersection(referencedUSRs.typealiases).isEmpty {
                    // If the type alias isn't already imported then it's probably not the one we're looking for
                    if allImports.contains(dependentUnit.moduleName) {
                        usedImports.insert(dependentUnit.moduleName)
                    }
                }
            }

            if allImports.subtracting(usedImports).isEmpty {
                break
            }
        }

        for module in allImports.intersection(allModuleNames).subtracting(usedImports) {
            print("/usr/bin/sed -i \"\" '/^import \(module)$/d' \(unitReader.mainFile)")
        }
    }
}

if CommandLine.arguments.count == 4 {
    let ignoredFileRegex = try! Regex(CommandLine.arguments[2])
    let ignoredModuleRegex = try! Regex(CommandLine.arguments[3])

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
