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
    var output = [String: [String: Int]]()

    for (unitReader, recordReader) in unitsAndRecords {
        allModuleNames.insert(unitReader.moduleName)
        modulesToUnits[unitReader.moduleName, default: []].append(unitReader)

        var definedUSRs = Set<String>()
        recordReader.forEach { (occurrence: SymbolOccurrence) in
            if occurrence.roles.contains(.definition) {
                definedUSRs.insert(occurrence.symbol.usr)
                allDefinedUSRs.insert(occurrence.symbol.usr)
            }
        }

        filesToDefinitions[unitReader.mainFile] = definedUSRs
    }

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
                if !intersection.isEmpty {
                    output[currentModule, default: [:]][anImport, default: 0] += intersection.count
                }
            }
        }
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try! encoder.encode(output)
    print(String(data: data, encoding: .utf8)!)
}

main(indexStorePath: CommandLine.arguments[1])
