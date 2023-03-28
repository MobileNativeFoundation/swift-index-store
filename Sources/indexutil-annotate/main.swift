import IndexStore
import Foundation

func main(_ storePath: String, _ sourcePath: String) throws {
    let store = try IndexStore(path: storePath)

    var recordName: String?
    var foundUnits = false
    for unitReader in store.units {
        foundUnits = true
        if unitReader.mainFile == sourcePath {
            recordName = unitReader.recordName
            break
        }
    }

    if !foundUnits {
        fputs("error: no records found, your index store might be invalid?\n", stderr)
        exit(EXIT_FAILURE)
    }

    if recordName == nil {
        fputs("error: no record file for \(sourcePath)\n", stderr)
        exit(EXIT_FAILURE)
    }

    let recordReader = try RecordReader(indexStore: store, recordName: recordName!)

    var lineAnnotations: [Int: [Annotation]] = [:]
    recordReader.forEach { (symbolOccurrence: SymbolOccurrence) in
        let annotation = Annotation(symbolOccurrence)
        lineAnnotations[annotation.line, default: []].append(annotation)
    }

    let lines = try String(contentsOfFile: sourcePath).components(separatedBy: .newlines)

    var annotatedLines: [String] = []
    for (number, line) in lines.enumerated() {
        if let annotations = lineAnnotations[number] {
            let columns = annotations.map { $0.column }

            // Setup the line graphics used to draw arrows.
            var lines = Array(repeating: " ", count: columns.last! + 1)
            var arrows = lines
            for column in columns {
                lines[column]  = "|"
                arrows[column] = "v"
            }

            let indent = indentation(of: line)
            annotatedLines.append(indent + "/*")
            for annotation in annotations  {
                // The prefix has indentation, plus continues to draw the lines from annotations above this one.
                let prefix = lines[..<annotation.column].joined()
                annotatedLines.append("\(prefix)\(annotation)")
            }
            annotatedLines.append(arrows.joined() + "  */")
        }

        annotatedLines.append(line)
    }

    for line in annotatedLines {
        print(line)
    }
}

private func indentation(of string: String) -> Substring {
    guard let indent = string.rangeOfCharacter(from: CharacterSet.whitespaces.inverted) else {
        return ""
    }
    return string[..<indent.lowerBound]
}

guard CommandLine.arguments.count == 3 else {
    fputs("usage: \(CommandLine.arguments[0]) <indexstore> <sourcepath>\n", stderr)
    exit(EXIT_FAILURE)
}

let storePath = CommandLine.arguments[1]
var sourcePath = CommandLine.arguments[2]
if !(sourcePath as NSString).isAbsolutePath {
    sourcePath = (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent(sourcePath)
}

do {
    try main(storePath, sourcePath)
} catch {
    fputs("error: \(error)\n", stderr)
    exit(EXIT_FAILURE)
}
