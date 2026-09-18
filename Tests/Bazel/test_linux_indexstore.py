"""Exercise LinuxIndexStore linking and runfiles using a synthetic Swift toolchain."""

import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
import unittest


def repository_file(name):
    if os.environ.get("RUNFILES_DIR") or os.environ.get("RUNFILES_MANIFEST_FILE"):
        from python.runfiles import runfiles

        return Path(runfiles.Create().Rlocation(f"swift-index-store/{name}"))
    return Path(__file__).resolve().parents[2] / name


# Resolve declared inputs even on hosts that skip the Linux runtime tests.
REPOSITORIES_BZL = repository_file("repositories.bzl").read_text()
MODULE_BAZEL = repository_file("MODULE.bazel").read_text()
BAZEL_VERSION = repository_file(".bazelversion").read_text().strip()


@unittest.skipUnless(sys.platform.startswith("linux"), "requires an ELF linker and loader")
class LinuxIndexStoreTest(unittest.TestCase):
    def test_runtime_library_names(self):
        bazel = shutil.which("bazel") or shutil.which("bazelisk")
        self.assertIsNotNone(bazel, "bazel or bazelisk must be on PATH")
        compiler = shlex.split(os.environ.get("CC", "cc"))
        env = os.environ.copy()
        env.setdefault("USE_BAZEL_VERSION", BAZEL_VERSION)
        env.pop("LD_LIBRARY_PATH", None)
        env.pop("LD_PRELOAD", None)
        # The nested build must not reuse the outer Python test's runfiles.
        for name in ("RUNFILES_DIR", "RUNFILES_MANIFEST_FILE", "JAVA_RUNFILES", "PYTHON_RUNFILES"):
            env.pop(name, None)

        with tempfile.TemporaryDirectory(
            prefix="indexstore-soname-", dir=os.environ.get("TEST_TMPDIR")
        ) as temporary:
            root = Path(temporary)
            source_root = root / "swift-index-store"
            source_root.mkdir()
            (source_root / "MODULE.bazel").write_text(MODULE_BAZEL)
            (source_root / "repositories.bzl").write_text(REPOSITORIES_BZL)
            (source_root / "BUILD.bazel").touch()
            workspace = root / "workspace"
            workspace.mkdir()
            (workspace / "MODULE.bazel").write_text(
                'module(name = "indexstore_soname_test")\n'
                'bazel_dep(name = "rules_cc", version = "0.2.17")\n'
                'bazel_dep(name = "swift-index-store", version = "1.10.0")\n'
                'local_path_override(module_name = "swift-index-store", '
                f'path = "{source_root.as_posix()}")\n'
                'deps = use_extension("@swift-index-store//:repositories.bzl", "bzlmod_deps")\n'
                'use_repo(deps, "LinuxIndexStore")\n'
            )
            (workspace / "BUILD.bazel").write_text(
                'load("@rules_cc//cc:defs.bzl", "cc_binary")\n'
                'cc_binary(name = "probe", srcs = ["main.c"], '
                'deps = ["@LinuxIndexStore//:libIndexStore"])\n'
            )
            (workspace / "main.c").write_text(
                "extern int indexstore_soname_test(void);\n"
                "int main(void) { return indexstore_soname_test() == 42 ? 0 : 1; }\n"
            )
            library_source = root / "library.c"
            library_source.write_text("int indexstore_soname_test(void) { return 42; }\n")

            cases = [
                ("unversioned", "libIndexStore.so", None),
                ("versioned_without_soname", "libIndexStore.so.1.2.3", None),
                ("versioned", "libIndexStore.so.1", "libIndexStore.so.1"),
                ("different_soname", "libIndexStore.so.1.2.3", "libIndexStore.so.1"),
            ]
            for case, filename, soname in cases:
                with self.subTest(case=case):
                    toolchain = root / case
                    bin_dir = toolchain / "bin"
                    lib_dir = toolchain / "lib"
                    bin_dir.mkdir(parents=True)
                    lib_dir.mkdir()
                    swiftc = bin_dir / "swiftc"
                    swiftc.write_text("#!/bin/sh\nexit 1\n")
                    swiftc.chmod(0o755)
                    command = compiler + ["-shared", "-fPIC", str(library_source), "-o", str(lib_dir / filename)]
                    if soname:
                        command.append(f"-Wl,-soname,{soname}")
                    subprocess.run(command, check=True, env=env)
                    if soname and soname != filename:
                        (lib_dir / soname).symlink_to(filename)
                    if filename != "libIndexStore.so":
                        (lib_dir / "libIndexStore.so").symlink_to(soname or filename)
                    subprocess.run(
                        [
                            bazel,
                            "--batch",
                            "--ignore_all_rc_files",
                            f"--output_user_root={root / 'bazel'}",
                            "run",
                            "--enable_bzlmod",
                            "--enable_workspace=false",
                            f"--repo_env=PATH={bin_dir}{os.pathsep}{env['PATH']}",
                            "//:probe",
                        ],
                        cwd=workspace,
                        env=env,
                        check=True,
                    )


if __name__ == "__main__":
    unittest.main()
