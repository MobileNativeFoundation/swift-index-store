load("@build_bazel_rules_swift//swift:swift.bzl", "swift_binary")

swift_binary(
    name = "unnecessary-testable",
    srcs = [
        "main.swift",
    ],
    deps = [
        "//:IndexStore",
    ],
)
