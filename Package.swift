// swift-tools-version:5.2

import PackageDescription

#if os(macOS)
import Foundation
let linkerSettings: [LinkerSetting]? = {
    let process = Process()
    process.launchPath = "/usr/bin/xcode-select"
    process.arguments = ["-p"]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.launch()
    process.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let XcodePath = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .newlines)
    return [
        .unsafeFlags(["-L\(XcodePath)/Toolchains/XcodeDefault.xctoolchain/usr/lib"]),
        .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "\(XcodePath)/Toolchains/XcodeDefault.xctoolchain/usr/lib"]),
    ]
}()
#else
let linkerSettings: [LinkerSetting]? = nil
#endif

let package = Package(
    name: "IndexStore",
    products: [
        .library(name: "IndexStore", targets: ["IndexStore"]),
        .library(name: "CSwiftDemangle", targets: ["CSwiftDemangle"]),
        .library(name: "SwiftDemangle", targets: ["SwiftDemangle"]),
        .executable(name: "indexutil-export", targets: ["indexutil-export"]),
        .executable(name: "unnecessary-testable", targets: ["unnecessary-testable"]),
        .executable(name: "indexutil-annotate", targets: ["indexutil-annotate"]),
        .executable(name: "tycat", targets: ["tycat"]),
    ],
    targets: [
        .target(name: "CIndexStore"),
        .target(name: "IndexStore", dependencies: ["CIndexStore"]),
        .testTarget(name: "IndexStoreTests", dependencies: ["IndexStore"], linkerSettings: linkerSettings),
        .target(
            name: "CSwiftDemangle",
            cxxSettings: [.headerSearchPath("PrivateHeaders/include")],
            linkerSettings: [.linkedLibrary("swiftDemangle")]
        ),
        .target(name: "SwiftDemangle", dependencies: ["CSwiftDemangle"]),
        .testTarget(name: "SwiftDemangleTests", dependencies: ["SwiftDemangle"]),
        .target(name: "indexutil-export", dependencies: ["IndexStore"], linkerSettings: linkerSettings),
        .target(name: "unnecessary-testable", dependencies: ["IndexStore"], linkerSettings: linkerSettings),
        .target(name: "indexutil-annotate", dependencies: ["IndexStore"], linkerSettings: linkerSettings),
        .target(name: "tycat", dependencies: ["IndexStore"], linkerSettings: linkerSettings),
    ],
    cxxLanguageStandard: .cxx11
)
