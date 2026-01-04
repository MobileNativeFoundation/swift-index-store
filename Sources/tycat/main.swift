import IndexStore
#if canImport(Darwin)
import Darwin.C
#else
import Glibc
#endif

func main(_ storePath: String, _ subcommand: String, _ requestedType: String) throws {
    var typeGraph = TypeGraph()

    let store = try IndexStore(path: storePath)
    for unitReader in store.units {
        guard unitReader.isSource, let recordName = unitReader.recordName else {
            continue
        }

        let recordReader = try RecordReader(indexStore: store, recordName: recordName)
        recordReader.forEach { (symbolOccurrence: SymbolOccurrence) in
            symbolOccurrence.forEach { relatedSymbol, relatedRoles in
                if relatedRoles.contains(.baseOf) {
                    typeGraph.add(subtype: relatedSymbol.name, of: symbolOccurrence.symbol.name)
                }
            }
        }
    }

    let typePaths: [[String]]
    if subcommand == "supertypes" {
        typePaths = typeGraph.supertypes(of: requestedType)
    } else if subcommand == "subtypes" {
        typePaths = typeGraph.subtypes(of: requestedType)
    } else {
        preconditionFailure("unknown subcommand (\(subcommand))")
    }

    for hierarchy in typePaths {
        print(hierarchy.joined(separator: " > "))
    }
}

guard CommandLine.arguments.count == 3 else {
    fputs("usage: \(CommandLine.arguments[0]) [supertypes | subtypes] <type>\n", stderr)
    exit(EXIT_FAILURE)
}

guard let storePath = try XcodeIndexStorePath() else {
    fputs("error: could not determine Xcode indexstore path\n", stderr)
    exit(EXIT_FAILURE)
}

let subcommand = CommandLine.arguments[1]
let requestedType = CommandLine.arguments[2]
try main(storePath, subcommand, requestedType)
