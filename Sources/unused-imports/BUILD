load("@build_bazel_rules_swift//swift:swift.bzl", "swift_binary")

swift_binary(
    name = "unused-imports",
    srcs = [
        "Reporters/JSONReporter.swift",
        "Reporters/SedCommandReporter.swift",
        "Reporters/UnusedImportReporter.swift",
        "SourceFileWithUnusedImports.swift",
        "UnusedImportStatement.swift",
        "main.swift",
    ],
    tags = [
        "manual",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "//:IndexStore",
    ],
)
