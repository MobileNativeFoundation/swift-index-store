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
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
process.arguments = ["swiftc"]
let swiftcPipe = Pipe()
process.standardOutput = swiftcPipe
try process.run()
process.waitUntilExit()
let swiftcData = swiftcPipe.fileHandleForReading.readDataToEndOfFile()
let swiftcBin = String(decoding: swiftcData, as: UTF8.self).trimmingCharacters(in: .newlines)
let toolchainLibDir = URL(fileURLWithPath: swiftcBin).resolvingSymlinksInPath()
    .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("lib").path

let indexLinkerSettings: [LinkerSetting] = [
    .unsafeFlags(["-L\(toolchainLibDir)"]),
    .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "\(toolchainLibDir)"]),
]

let swiftDemangleLinkerSettings: [LinkerSetting] = [
    .unsafeFlags(["-L\(toolchainLibDir)"]),
    .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "\(toolchainLibDir)"]),
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
