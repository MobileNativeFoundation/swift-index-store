load("@rules_python//python:defs.bzl", "py_test")

py_test(
    name = "linux_indexstore_test",
    size = "large",
    srcs = ["test_linux_indexstore.py"],
    data = ["//:repository_test_files"],
    env_inherit = [
        "CC",
        "PATH",
        "USE_BAZEL_VERSION",
    ],
    main = "test_linux_indexstore.py",
    # Nested Bazel invocations need host build tools and repository downloads.
    tags = [
        "local",
        "requires-network",
    ],
    deps = ["@rules_python//python/runfiles"],
)
