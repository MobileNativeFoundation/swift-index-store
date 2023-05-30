import IndexStore
import Darwin
import Foundation

private func getImports(path: String, recordReader: RecordReader) -> Set<String> {
    if path.contains(".generated.swift") {
        return []
    }
    let lines = try! String(contentsOfFile: path).split(separator: "\n", omittingEmptySubsequences: false)

    var imports = Set<String>()
    recordReader.forEach { (occurrence: SymbolOccurrence) in
        if occurrence.symbol.kind == .module && occurrence.roles.contains(.reference) {
            let line = lines[occurrence.location.line - 1]
            // FIXME: This won't work if we are also adding missing imports, return it separately
            if line.hasPrefix("import ") || line.contains(" import ") {
                imports.insert(occurrence.symbol.name)
            }
        }
    }

    return imports
}

private func getReferences(unitReader: UnitReader, recordReader: RecordReader) -> Set<String> {
    var usrs = Set<String>()
    recordReader.forEach { (occurrence: SymbolOccurrence) in
        if occurrence.roles.contains(.reference) {
            usrs.insert(occurrence.symbol.usr)
        }
    }

    return usrs
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

func main(indexStorePath: String) {
    if let directory = ProcessInfo.processInfo.environment["BUILD_WORKSPACE_DIRECTORY"] {
        FileManager.default.changeCurrentDirectoryPath(directory)
    }

    var filesToDefinitions: [String: Set<String>] = [:]
    let unitsAndRecords = collectUnitsAndRecords(indexStorePath: indexStorePath)
    var modulesToUnits: [String: [UnitReader]] = [:]
    var allModuleNames = Set<String>()
    var allDefinedUSRs = Set<String>()
    var definedIn = [String: String]()
    var usedIn = [String: Set<String>]()

    for (unitReader, recordReader) in unitsAndRecords {
        allModuleNames.insert(unitReader.moduleName)
        modulesToUnits[unitReader.moduleName, default: []].append(unitReader)

        var definedUSRs = Set<String>()
        recordReader.forEach { (occurrence: SymbolOccurrence) in
            if occurrence.roles.contains(.definition) 
            && !occurrence.roles.contains(.implicit)
            && !occurrence.roles.contains(.accessorOf)
            && !occurrence.roles.contains(.baseOf)
            && !occurrence.roles.contains(.overrideOf)
            {
                definedUSRs.insert(occurrence.symbol.usr)
                allDefinedUSRs.insert(occurrence.symbol.usr)
                definedIn[occurrence.symbol.usr] = unitReader.moduleName
            }
        }

        filesToDefinitions[unitReader.mainFile] = definedUSRs
    }

    print(allDefinedUSRs.count)

    for (unitReader, recordReader) in unitsAndRecords {
        let rawImports = getImports(path: unitReader.mainFile, recordReader: recordReader)
        let allImports = rawImports.intersection(allModuleNames)
        if allImports.isEmpty {
            continue
        }

        let currentModule = unitReader.moduleName
        let references = getReferences(unitReader: unitReader, recordReader: recordReader).intersection(allDefinedUSRs)
        for anImport in allImports {
            for dependentUnit in modulesToUnits[anImport] ?? [] {
                guard let definedUSRs = filesToDefinitions[dependentUnit.mainFile] else {
                    continue
                }

                let intersection = definedUSRs.intersection(references)
                for referenced in intersection {
                    usedIn[referenced, default: []].insert(currentModule)
                }
            }
        }
    }

    for (usr, users) in usedIn {
        if users.count > 1 {
            // TODO: you could probably come up with something smarter for this, maybe if multiple modules
            // depended on it but they were further up the dependency tree it could still be moved up
            // somewhere
            continue
        }

        if users.first! != definedIn[usr]! {
            print("\(usr) should be moved from \(definedIn[usr]!) to \(users.first!)")
        }
    }
}

main(indexStorePath: CommandLine.arguments[1])
