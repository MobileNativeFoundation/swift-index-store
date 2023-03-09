import Foundation

/// Computes the index store path for the current test environment using loose heuristics.
///
/// Currently supports Xcode and SwiftPM.
///
/// This is not high quality code. However, since it's a hack to use the project's index store as a test
/// fixture, it gets the job done.
///
/// - Returns: Index store path for the current test environment
func determineIndexStorePath() -> String {
    if let testSrcDir: String = ProcessInfo.processInfo.environment["TEST_SRCDIR"] {
        return testSrcDir + "/__main__/Tests/IndexStoreTests/Data/main.indexstore"
    }
    guard let service = ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"] else {
        preconditionFailure("Expected XPC_SERVICE_NAME environment variable")
    }

    if service.hasPrefix("application.com.apple.dt.Xcode"), let path = determineXcodeIndexStorePath() {
        return path
    } else if service == "0", let path = determineSwiftPMIndexStorePath() {
        return path
    }

    preconditionFailure("Could not determine index store path")
}

fileprivate func determineXcodeIndexStorePath() -> String? {
    guard let libraryPath = ProcessInfo.processInfo.environment["DYLD_LIBRARY_PATH"] else {
        preconditionFailure("Expected DYLD_LIBRARY_PATH environment variable")
    }

    return libraryPath.split(separator: ":")
        .filter { $0.hasSuffix("/Build/Products/Debug") }
        .map { "\($0)/../../../Index/DataStore" }
        .filter { path in
            var isDir: ObjCBool = false
            return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }
    .first
}

fileprivate func determineSwiftPMIndexStorePath() -> String? {
    guard let workingDir = ProcessInfo.processInfo.environment["PWD"] else {
        preconditionFailure("Expected PWD environment variable")
    }

    var dir = workingDir
    while !FileManager.default.fileExists(atPath: "\(dir)/Package.swift") {
        dir = (dir as NSString).deletingLastPathComponent
        if dir == "/" {
            return nil
        }
    }

#if arch(x86_64)
    return "\(dir)/.build/x86_64-apple-macosx/debug/index/store"
#else
    return "\(dir)/.build/arm64-apple-macosx/debug/index/store"
#endif
}
