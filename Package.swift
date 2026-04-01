// swift-tools-version:5.7

import PackageDescription
import Foundation

#if os(macOS)
let process = Process()
process.launchPath = "/usr/bin/xcode-select"
process.arguments = ["-p"]
let pipe = Pipe()
process.standardOutput = pipe
process.launch()
process.waitUntilExit()
let data = pipe.fileHandleForReading.readDataToEndOfFile()
let XcodePath = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .newlines)

let indexLinkerSettings: [LinkerSetting] = [
    .unsafeFlags(["-L\(XcodePath)/Toolchains/XcodeDefault.xctoolchain/usr/lib"]),
    .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "\(XcodePath)/Toolchains/XcodeDefault.xctoolchain/usr/lib"]),
]

let swiftDemangleLinkerSettings: [LinkerSetting] = [
    .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "\(XcodePath)/Toolchains/XcodeDefault.xctoolchain/usr/lib"]),
    // This is a hack to get Xcode's version instead of the system installed version
    .unsafeFlags(["-Xlinker", "-force_load", "-Xlinker", "\(XcodePath)/Toolchains/XcodeDefault.xctoolchain/usr/lib/libswiftDemangle.dylib"]),
]

#else
func runProcess(_ executableURL: URL, arguments: [String]) throws -> Data {
    let process = Process()
    process.executableURL = executableURL
    process.arguments = arguments

    let stdout = Pipe()
    process.standardOutput = stdout

    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        throw NSError(
            domain: "swift-index-store.Package",
            code: Int(process.terminationStatus),
            userInfo: [
                NSLocalizedDescriptionKey: "\(arguments.joined(separator: " ")) exited with status \(process.terminationStatus)",
            ]
        )
    }

    return stdout.fileHandleForReading.readDataToEndOfFile()
}

func linuxToolchainLibraryDirectory(containing library: String) throws -> String {
    let targetInfoData = try runProcess(
        URL(fileURLWithPath: "/usr/bin/env"),
        arguments: ["swiftc", "-print-target-info"]
    )
    let targetInfo = try JSONSerialization.jsonObject(with: targetInfoData) as? [String: Any]
    let paths = targetInfo?["paths"] as? [String: Any]

    var candidateDirectories: [String] = (paths?["runtimeLibraryPaths"] as? [String]) ?? []

    if let runtimeResourcePath = paths?["runtimeResourcePath"] as? String {
        let runtimeResourceURL = URL(fileURLWithPath: runtimeResourcePath).resolvingSymlinksInPath()
        candidateDirectories.append(runtimeResourceURL.path)
        candidateDirectories.append(runtimeResourceURL.deletingLastPathComponent().path)
        candidateDirectories.append(runtimeResourceURL.deletingLastPathComponent().deletingLastPathComponent().path)
    }

    let fileManager = FileManager.default
    let uniqueCandidateDirectories = Array(NSOrderedSet(array: candidateDirectories)) as? [String] ?? []

    if let libraryDirectory = uniqueCandidateDirectories.first(where: { directory in
        fileManager.fileExists(atPath: "\(directory)/\(library)")
    }) {
        return libraryDirectory
    }

    throw NSError(
        domain: "swift-index-store.Package",
        code: 1,
        userInfo: [
            NSLocalizedDescriptionKey: "Could not locate \(library) from swiftc -print-target-info",
        ]
    )
}

let indexStoreLibDir = try linuxToolchainLibraryDirectory(containing: "libIndexStore.so")
let swiftDemangleLibDir = try linuxToolchainLibraryDirectory(containing: "libswiftDemangle.so")

let indexLinkerSettings: [LinkerSetting] = [
    .unsafeFlags(["-L\(indexStoreLibDir)"]),
    .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "\(indexStoreLibDir)"]),
]

let swiftDemangleLinkerSettings: [LinkerSetting] = [
    .unsafeFlags(["-L\(swiftDemangleLibDir)"]),
    .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "\(swiftDemangleLibDir)"]),
    .linkedLibrary("swiftDemangle"),
]
#endif

let package = Package(
    name: "IndexStore",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "IndexStore", targets: ["IndexStore"]),
        .library(name: "CSwiftDemangle", targets: ["CSwiftDemangle"]),
        .library(name: "SwiftDemangle", targets: ["SwiftDemangle"]),
        .executable(name: "indexutil-export", targets: ["indexutil-export"]),
        .executable(name: "unnecessary-testable", targets: ["unnecessary-testable"]),
        .executable(name: "unused-imports", targets: ["unused-imports"]),
        .executable(name: "indexutil-annotate", targets: ["indexutil-annotate"]),
        .executable(name: "tycat", targets: ["tycat"]),
    ],
    targets: [
        .target(name: "CIndexStore"),
        .target(name: "IndexStore", dependencies: ["CIndexStore"], linkerSettings: indexLinkerSettings),
        .testTarget(name: "IndexStoreTests", dependencies: ["IndexStore"], exclude: ["BUILD"]),
        .target(
            name: "CSwiftDemangle",
            cxxSettings: [.headerSearchPath("PrivateHeaders/include")],
            linkerSettings: swiftDemangleLinkerSettings
        ),
        .target(name: "SwiftDemangle", dependencies: ["CSwiftDemangle"]),
        .testTarget(name: "SwiftDemangleTests", dependencies: ["SwiftDemangle"], exclude: ["BUILD"]),
        .executableTarget(name: "indexutil-export", dependencies: ["IndexStore"], exclude: ["BUILD"]),
        .executableTarget(name: "unnecessary-testable", dependencies: ["IndexStore"], exclude: ["BUILD"]),
        .executableTarget(name: "unused-imports", dependencies: ["IndexStore"], exclude: ["BUILD"]),
        .executableTarget(name: "indexutil-annotate", dependencies: ["IndexStore"], exclude: ["BUILD"]),
        .executableTarget(name: "tycat", dependencies: ["IndexStore"], exclude: ["BUILD"]),
    ],
    cxxLanguageStandard: .cxx17
)
