load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

cc_library(
    name = "CIndexStore",
    hdrs = ["Sources/CIndexStore/include/indexstore.h"],
    copts = ["-std=c++17"],
    linkstatic = True,
    tags = ["swift_module=CIndexStore"],
)

swift_library(
    name = "IndexStore",
    srcs = glob(["Sources/IndexStore/*.swift"]),
    linkopts = select({
        "@platforms//os:linux": ["-lIndexStore"],
        "//conditions:default": [],
    }),
    visibility = [
        "//visibility:public",
    ],
    deps = [
        ":CIndexStore",
    ] + select({
        "@platforms//os:linux": [],
        "//conditions:default": [
            "@StaticIndexStore//:libIndexStore",
        ],
    }),
)

swift_library(
    name = "SwiftDemangle",
    srcs = glob(["Sources/SwiftDemangle/*.swift"]),
    linkopts = select({
        "@platforms//os:linux": [],
        "//conditions:default": [
            "-Wl,-force_load,__BAZEL_XCODE_DEVELOPER_DIR__/Toolchains/XcodeDefault.xctoolchain/usr/lib/libswiftDemangle.dylib",
            "-Wl,-rpath,__BAZEL_XCODE_DEVELOPER_DIR__/Toolchains/XcodeDefault.xctoolchain/usr/lib",
        ],
    }),
    module_name = "SwiftDemangle",
    visibility = [
        "//visibility:public",
    ],
    deps = [
        "//Sources/CSwiftDemangle",
    ],
)
