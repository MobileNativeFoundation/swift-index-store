# swift-index-store

`swift-index-store` is collection of libraries and tools for
programmatically reading the source code index produced by `swiftc` and
`clang`.

## Example Usage

The `IndexStore` library is the primary entrypoint. For example if you
want to print all the `class`es defined in a specific file:

```swift
let storePath = // path/to/DerivedData/index/store
let sourceFile = // path/to/interesting/source/file

// Load the index store produced by swiftc
let store = try IndexStore(path: storePath)
for unit in store.units {
    // Find the unit that corresponds to the source file we're interested in
    guard unit.mainFile == sourceFile, let recordName = unit.recordName else {
        continue
    }

    let recordReader = try RecordReader(indexStore: store, recordName: recordName)
    recordReader.forEach { symbolOccurrence in
        // Print class definitions in the source file
        if symbolOccurrence.roles.contains(.definition) && symbolOccurrence.symbol.kind == .class {
            print(symbolOccurrence.symbol.name)
        }
    }
}
```

For more examples see:

- [`unnecessary-testable`](Sources/unnecessary-testable/main.swift)
  which discovers uses of `@testable` that aren't required based on the
  API being called by the importing file.
- [`tycat`](Sources/tycat) which print the subtypes or supertypes of a
  given type.
- [`indexutil-annotate`](Sources/indexutil-annotate) which outputs
  the index information overlaid on the given source file for debugging
  unexpected index data.

## Setup

Swift Package Manager:

```swift
let package = Package(
    // ...
    dependencies: [
        .package(url: "https://github.com/lyft/swift-index-store", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(name: "<command-line-tool>", dependencies: [
            .product(name: "IndexStore", package: "swift-index-store"),
        ]),
    ]
)
```

Bazel:

Add the following to your `WORKSPACE` file:

```python
SWIFT_INDEX_STORE_VERSION = "1.1.0"

http_archive(
    name = "IndexStore",
    sha256 = "b9c7dbcf100783c55d2c24e491feab943a489b485b016016dcd3f3d568836b3b",
    strip_prefix = "swift-index-store-%s" % SWIFT_INDEX_STORE_VERSION,
    url = "https://github.com/lyft/swift-index-store/archive/refs/tags/%s.tar.gz" % SWIFT_INDEX_STORE_VERSION,
)
```

then you can consume the target like so:

```python
deps = [
    "@com_github_lyft_swift_index_store//:IndexStore",
]
```

Xcode:

1. Add the swift-index-store as a Package Dependency to your project (via File ▸ Add Packages…).
2. Added the “IndexStore” library to your target's Frameworks and Libraries.
3. Add `$(TOOLCHAIN_DIR)/usr/lib` to your target's Runpath Search Paths (LD_RUNPATH_SEARCH_PATHS) build setting.
4. Add `$(TOOLCHAIN_DIR)/usr/lib` to your target's Library Search Paths (LIBRARY_SEARCH_PATHS) build setting.

## How it works

During compilation, both `swiftc` and `clang` can generate a detailed
source code index by providing the `-index-store-path` flag. The data
model of the index is public, just not well known or well documented.

`IndexStore` is a Swift wrapper over the first party `libIndexStore` C
library which is part of LLVM. Xcode and Swift for Linux contain
`libIndexStore`, but its header is found separately in
[apple/llvm-project's
`indexstore.h`](https://github.com/apple/llvm-project/blob/apple/next/clang/include/indexstore/indexstore.h).

For more details on the index store's data model, see:

1. Adding Index-While-Building and Refactoring to Clang: <https://www.youtube.com/watch?v=jGJhnIT-D2M>
2. High level design: <https://docs.google.com/document/d/1cH2sTpgSnJZCkZtJl1aY-rzy4uGPcrI-6RrUpdATO2Q/>

### How does this differ from [`indexstore-db`][indexstore-db]

The goal of this library is to provide a thin Swift layer on top of the
C library for one shot tools that manage the structure of the index data
themselves. [`indexstore-db`][indexstore-db] provides more comprehensive
support for querying index data as it changes across multiple builds.

[indexstore-db]: https://github.com/apple/indexstore-db
