#if os(macOS)
import Darwin.C
#elseif os(Linux)
import Glibc
#endif
import Foundation

struct StandardStream: TextOutputStream {
    private let stream: UnsafeMutablePointer<FILE>

    fileprivate init(_ stream: UnsafeMutablePointer<FILE>) {
        self.stream = stream
    }

    mutating func write(_ string: String) {
        fputs(string, self.stream)
    }
}

var stderr = StandardStream(Foundation.stderr)
