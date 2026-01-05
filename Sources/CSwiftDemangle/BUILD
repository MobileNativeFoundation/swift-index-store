load("@build_bazel_rules_swift//swift:swift.bzl", "swift_interop_hint")

# Interop hint for Swift access to C headers
swift_interop_hint(
    name = "CSwiftDemangle_swift_hint",
    module_name = "CSwiftDemangle",
)

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
    alwayslink = True,
    aspect_hints = [":CSwiftDemangle_swift_hint"],
    copts = ["-std=c++17"],
    includes = [
        "PrivateHeaders/include",
        "include",
    ],
    linkopts = select({
        "@platforms//os:linux": [],
        "//conditions:default": ["-lswiftDemangle"],
    }),
    linkstatic = True,
    textual_hdrs = glob([
        "**/*.def",
    ]),
    visibility = [
        "//:__pkg__",
    ],
)
