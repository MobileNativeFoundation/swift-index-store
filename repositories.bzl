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

def swift_index_store_dependencies():
    build_bazel_rules_swift_sha = "40c36c936c9c80b4aefa3f008ecf99dbe002be2c"
    _maybe(
        http_archive,
        name = "build_bazel_rules_swift",
        sha256 = "dd08813524deb0b449b0bcbde193caa284f45dd8fd624f9ed4ef1fcbfa78b8a8",
        url = "https://github.com/bazelbuild/rules_swift/archive/%s.zip" % build_bazel_rules_swift_sha,
        strip_prefix = "rules_swift-%s" % build_bazel_rules_swift_sha,
    )

    build_bazel_rules_apple_sha = "5f036277bd2e1e357fd8502bf0ade9d293cf91b3"
    _maybe(
        http_archive,
        name = "build_bazel_rules_apple",
        sha256 = "635de45a7c07daed728962a9be983503221da22b6c6759e2f67f283cbb6cbe37",
        url = "https://github.com/bazelbuild/rules_apple/archive/%s.zip" % build_bazel_rules_apple_sha,
        strip_prefix = "rules_apple-%s" % build_bazel_rules_apple_sha,
    )

    _maybe(
        http_archive,
        name = "StaticIndexStore",
        url = "https://github.com/keith/StaticIndexStore/releases/download/5.7/libIndexStore.xcframework.zip",
        sha256 = "da69bab932357a817aa0756e400be86d7156040bfbea8eded7a3acc529320731",
        build_file_content = """
load(
    "@build_bazel_rules_apple//apple:apple.bzl",
    "apple_static_xcframework_import",
)

apple_static_xcframework_import(
    name = "libIndexStore",
    visibility = [
        "//visibility:public",
    ],
    xcframework_imports = glob(["libIndexStore.xcframework/**"]),
)
        """,
    )
