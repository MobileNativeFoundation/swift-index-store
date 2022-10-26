import IndexStore
import Foundation
import struct ObjectiveC.ObjCBool

struct StandardErrorStream: TextOutputStream {
    mutating func write(_ string: String) {
        fputs(string, Foundation.stderr)
    }
}

var stderr = StandardErrorStream()

func usage() -> Never {
    print("Usage: indexutil export <format> <index-store-path> <output-dir>", to: &stderr)
    exit(EXIT_FAILURE)
}

guard CommandLine.arguments.count == 4 else {
    usage()
}

let exportFormat = CommandLine.arguments[1]
let indexStorePath = CommandLine.arguments[2]
let outputPath = CommandLine.arguments[3]

let knownFormats = Set(["tsv"])
guard knownFormats.contains(exportFormat) else {
    print("Error: Unknown export format \(exportFormat)", to: &stderr)
    print("Supported formats: \(knownFormats.joined(separator: ", "))", to: &stderr)
    usage()
}

let store: IndexStore
do {
    store = try IndexStore(path: indexStorePath)
} catch {
    print("Error opening index store: \(error)", to: &stderr)
    usage()
}

var outputPathIsDirectory: ObjCBool = false
let outputPathExists = FileManager.default.fileExists(atPath: outputPath, isDirectory: &outputPathIsDirectory)
if outputPathExists && !outputPathIsDirectory.boolValue {
    print("Error: Output path is not directory - \(outputPath)", to: &stderr)
    usage()
}

if !outputPathExists {
    do {
        try FileManager.default.createDirectory(atPath: outputPath, withIntermediateDirectories: true)
    } catch {
        print("Error: Could not create output directory - \(error)", to: &stderr)
        usage()
    }
}

let outputDirectory = URL(fileURLWithPath: outputPath)
guard
    let symbols = TSVWriter(outputDirectory.appendingPathComponent("symbols.tsv")),
    let occurrences = TSVWriter(outputDirectory.appendingPathComponent("occurrences.tsv")),
    let relations = TSVWriter(outputDirectory.appendingPathComponent("relations.tsv"))
else {
    print("Error: Could not open output files in \(outputPath)", to: &stderr)
    exit(EXIT_FAILURE)
}

// Symbols info is duplicated across record files. This set tracks which symbols have been exported to ensure
// the exported symbols are unique.
var symbolsExported: Set<String> = []

for unitReader in store.units {
    let mainFile = unitReader.mainFile
    let isSystem = unitReader.isSystem
    for recordName in unitReader.recordNames {
        let recordReader: RecordReader
        do {
            recordReader = try RecordReader(indexStore: store, recordName: recordName)
        } catch {
            print("Error: \(error)", to: &stderr)
            continue
        }

        recordReader.forEach { (symbol: Symbol) in
            if !symbolsExported.contains(symbol.usr) {
                symbols.write(symbol.usr, symbol.name, symbol.kind, symbol.subkind, isSystem)
                symbolsExported.insert(symbol.usr)
            }
        }

        recordReader.forEach { (occurrence: SymbolOccurrence) in
            let symbolRoles = occurrence.roles.subtracting(.relationRoles)
            for role in SymbolRoles.allCases where symbolRoles.contains(role) {
                let (line, column) = occurrence.location
                occurrences.write(occurrence.symbol.usr, role, mainFile, line, column)
            }

            occurrence.forEach { relatedSymbol, relationRoles in
                for role in SymbolRoles.allCases where relationRoles.contains(role) {
                    relations.write(occurrence.symbol.usr, role, relatedSymbol.usr)
                }
            }
        }
    }
}
