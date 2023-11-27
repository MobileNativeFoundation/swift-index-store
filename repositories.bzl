"""Definitions for handling Bazel repositories used by the swift-index-store."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _maybe(repo_rule, name, **kwargs):
    """
    Executes the given repository rule if it hasn't been executed already.

    Args:
      repo_rule: The repository rule to be executed (e.g., `http_archive`.)
      name: The name of the repository to be defined by the rule.
      **kwargs: Additional arguments passed directly to the repository rule.
    """
    if not native.existing_rule(name):
        repo_rule(name = name, **kwargs)

def swift_index_store_dependencies(bzlmod = False):
    if not bzlmod:
        _maybe(
            http_archive,
            name = "build_bazel_rules_swift",
            sha256 = "28a66ff5d97500f0304f4e8945d936fe0584e0d5b7a6f83258298007a93190ba",
            url = "https://github.com/bazelbuild/rules_swift/releases/download/1.13.0/rules_swift.1.13.0.tar.gz",
        )
        _maybe(
            http_archive,
            name = "build_bazel_rules_apple",
            sha256 = "34c41bfb59cdaea29ac2df5a2fa79e5add609c71bb303b2ebb10985f93fa20e7",
            url = "https://github.com/bazelbuild/rules_apple/releases/download/3.1.1/rules_apple.3.1.1.tar.gz",
        )

    _maybe(
        http_archive,
        name = "StaticIndexStore",
        url = "https://github.com/keith/StaticIndexStore/releases/download/5.7/libIndexStore.xcframework.zip",
        sha256 = "da69bab932357a817aa0756e400be86d7156040bfbea8eded7a3acc529320731",
        build_file_content = """
load("@build_bazel_rules_apple//apple:apple.bzl", "apple_static_xcframework_import")

apple_static_xcframework_import(
    name = "libIndexStore",
    visibility = ["//visibility:public"],
    xcframework_imports = glob(["libIndexStore.xcframework/**"]),
)
        """,
    )

def _bzlmod_deps(_):
    swift_index_store_dependencies(bzlmod = True)

bzlmod_deps = module_extension(implementation = _bzlmod_deps)
