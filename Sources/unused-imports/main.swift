import IndexStore
import Darwin
import Foundation

private typealias References = (usrs: Set<String>, typealiases: Set<String>)
private let identifierRegex = try Regex("([a-zA-Z_][a-zA-Z0-9_]*)")
private let ignoreRegex = try Regex(#"// *ignore-import$"#)
private var cachedLines = [String: [String.SubSequence]]()

private func getImports(path: String, recordReader: RecordReader) -> (Set<String>, [String: Int]) {
    var importsToLineNumbers = [String: Int]()
    let lines = try! String(contentsOfFile: path).split(separator: "\n", omittingEmptySubsequences: false)
    cachedLines[path] = lines

    var imports = Set<String>()
    recordReader.forEach { (occurrence: SymbolOccurrence) in
        if occurrence.symbol.kind == .module && occurrence.roles.contains(.reference) {
            let line = lines[occurrence.location.line - 1]
            // FIXME: This won't work if we are also adding missing imports, return it separately
            if (line.hasPrefix("import ") || line.contains(" import ")) &&
                line.firstMatch(of: ignoreRegex) == nil
            {
                imports.insert(occurrence.symbol.name)
                importsToLineNumbers[occurrence.symbol.name] = occurrence.location.line
            }
        }
    }

    return (imports, importsToLineNumbers)
}

private func getReferences(unitReader: UnitReader, recordReader: RecordReader) -> References {
    var usrs = Set<String>()
    var typealiasExts = Set<String>()
    recordReader.forEach { (occurrence: SymbolOccurrence) in
        if occurrence.symbol.subkind == .swiftExtensionOfStruct  {
            usrs.insert(occurrence.symbol.usr)
            let lines = cachedLines[unitReader.mainFile]!
            let line = lines[occurrence.location.line - 1]
            let startIndex = line.index(line.startIndex, offsetBy: occurrence.location.column - 1)
            // FIXME: `extension [Int]` doesn't match
            guard let match = line[startIndex...].firstMatch(of: identifierRegex) else {
                return
            }

            let identifier = String(match.0)
            if identifier != occurrence.symbol.name {
                typealiasExts.insert(identifier)
            }
        } else if occurrence.roles.contains(.reference) {
            usrs.insert(occurrence.symbol.usr)
        }
    }

    return References(usrs: usrs, typealiases: typealiasExts)
}

private func collectUnitsAndRecords(indexStorePath: String) -> [(UnitReader, RecordReader)] {
    let store: IndexStore
    do {
        store = try IndexStore(path: indexStorePath)
    } catch {
        fatalError("error: failed to open index store: \(error)")
    }

    var unitsAndRecords: [(UnitReader, RecordReader)] = []
    var seenUnits = Set<String>()
    for unitReader in store.units {
        if unitReader.mainFile.isEmpty {
            continue
        }

        if seenUnits.contains(unitReader.mainFile) {
            continue
        }

        if let recordName = unitReader.recordName {
            do {
                let recordReader = try RecordReader(indexStore: store, recordName: recordName)
                unitsAndRecords.append((unitReader, recordReader))
                seenUnits.insert(unitReader.mainFile)
            } catch {
                fatalError("error: failed to load record: \(recordName) \(error)")
            }
        }
    }

    if unitsAndRecords.isEmpty {
        fatalError("error: failed to load units from \(indexStorePath)")
    }

    return unitsAndRecords
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
    var filesToDefinitions: [String: References] = [:]
    let unitsAndRecords = collectUnitsAndRecords(indexStorePath: indexStorePath)
    var modulesToUnits: [String: [UnitReader]] = [:]
    var allModuleNames = Set<String>()

    for (unitReader, recordReader) in unitsAndRecords {
        allModuleNames.insert(unitReader.moduleName)
        modulesToUnits[unitReader.moduleName, default: []].append(unitReader)

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

        filesToDefinitions[unitReader.mainFile] = References(
            usrs: definedUsrs, typealiases: definedTypealiases)
    }

    for (unitReader, recordReader) in unitsAndRecords {
        if let ignoredFileRegex, unitReader.mainFile.wholeMatch(of: ignoredFileRegex) != nil {
            continue
        } else if let ignoredModuleRegex, unitReader.moduleName.wholeMatch(of: ignoredModuleRegex) != nil {
            continue
        }

        let (rawImports, importsToLineNumbers) = getImports(
            path: unitReader.mainFile, recordReader: recordReader)
        let allImports = rawImports.intersection(allModuleNames)
        if allImports.isEmpty {
            continue
        }

        let references = getReferences(unitReader: unitReader, recordReader: recordReader)
        var usedImports = Set<String>()
        for anImport in allImports {
            for dependentUnit in modulesToUnits[anImport] ?? [] {
                if usedImports.contains(anImport) {
                    break
                }

                // Empty files have units but no records and therefore no usrs
                guard let definitions = filesToDefinitions[dependentUnit.mainFile] else {
                    continue
                }

                if !definitions.usrs.intersection(references.usrs).isEmpty {
                    usedImports.insert(dependentUnit.moduleName)
                } else if !definitions.typealiases.intersection(references.typealiases).isEmpty {
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
            let sedCmd = unusedImports.map { importsToLineNumbers[$0]! }.sorted().map { "\($0)d" }.joined(separator: ";")
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
