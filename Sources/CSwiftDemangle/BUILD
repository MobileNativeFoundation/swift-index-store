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
    copts = ["-std=c++17"],
    includes = [
        "PrivateHeaders/include",
        "include",
    ],
    linkopts = [
        "-lswiftDemangle",
    ],
    tags = ["swift_module=CSwiftDemangle"],
    textual_hdrs = glob([
        "**/*.def",
    ]),
    visibility = [
        "//:__pkg__",
    ],
)
