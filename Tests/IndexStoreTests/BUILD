load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_test")

swift_library(
    name = "dummy",
    testonly = True,
    srcs = ["dummy.swift"],
    features = ["swift.index_while_building"],
)

filegroup(
    name = "dummy-index",
    testonly = True,
    srcs = [":dummy"],
    output_group = "swift_index_store",
)

swift_test(
    name = "IndexStoreTests",
    srcs = [
        "DetermineIndexStorePath.swift",
        "IndexStoreTests.swift",
    ],
    data = [":dummy-index"],
    deps = [
        "//:IndexStore",
    ],
)
