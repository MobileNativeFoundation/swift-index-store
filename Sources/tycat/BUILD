load("@build_bazel_rules_swift//swift:swift.bzl", "swift_binary")

swift_binary(
    name = "tycat",
    srcs = [
        "TypeGraph.swift",
        "Xcode.swift",
        "main.swift",
    ],
    deps = [
        "//:IndexStore",
    ],
)
