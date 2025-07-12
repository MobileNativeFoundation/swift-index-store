load("@build_bazel_rules_swift//swift:swift.bzl", "swift_binary")

swift_binary(
    name = "unused-imports",
    srcs = [
        "main.swift",
        "SourceFileWithUnusedImports.swift",
        "UnusedImportStatement.swift",
        "Reporters/JSONReporter.swift",
        "Reporters/SedCommandReporter.swift",
        "Reporters/UnusedImportReporter.swift",
    ],
    tags = [
        "manual",
    ],
    deps = [
        "//:IndexStore",
    ],
    visibility = ["//visibility:public"],
)
