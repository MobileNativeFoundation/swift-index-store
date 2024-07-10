cc_library(
    name = "CSwiftDemangle",
    srcs = glob([
        "PrivateHeaders/**/*.h",
    ]) + [
        "CSwiftDemangle.cpp",
    ],
    hdrs = glob([
        "include/**/*.h",
    ]),
    aspect_hints = ["@build_bazel_rules_swift//swift:auto_module"],
    copts = ["-std=c++17"],
    includes = [
        "PrivateHeaders/include",
        "include",
    ],
    linkopts = [
        "-lswiftDemangle",
    ],
    textual_hdrs = glob([
        "**/*.def",
    ]),
    visibility = [
        "//:__pkg__",
    ],
)
