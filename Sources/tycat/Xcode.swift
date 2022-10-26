import Foundation

func XcodeIndexStorePath() throws -> String? {
    let process = Process()
    process.launchPath = "/usr/bin/xcodebuild"
    process.arguments = ["-showBuildSettings"]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(decoding: data, as: UTF8.self)

    guard
        let start = output.range(of: "BUILD_ROOT = ")?.upperBound,
        let end = output.rangeOfCharacter(from: .newlines, range: start..<output.endIndex)?.lowerBound
    else {
        return nil
    }

    // ¯\_(ツ)_/¯
    let buildProducts = output[start..<end] as NSString
    let root = (buildProducts.deletingLastPathComponent as NSString).deletingLastPathComponent as NSString
    let indexStore = (root.appendingPathComponent("Index.noindex") as NSString).appendingPathComponent("DataStore")

    return indexStore
}
