load("@build_bazel_rules_swift//swift:swift.bzl", "swift_test")

swift_test(
    name = "IndexStoreTests",
    srcs = [
        "DetermineIndexStorePath.swift",
        "IndexStoreTests.swift",
    ],
    data = glob([
        "Data/**",
    ]),
    deps = [
        "//:IndexStore",
    ],
)
