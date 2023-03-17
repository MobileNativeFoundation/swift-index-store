load("@build_bazel_rules_swift//swift:swift.bzl", "swift_binary")

swift_binary(
    name = "indexutil-export",
    srcs = [
        "TSVWriter.swift",
        "main.swift",
    ],
    deps = [
        "//:IndexStore",
    ],
)
