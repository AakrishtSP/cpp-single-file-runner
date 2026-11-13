#!/usr/bin/env python3
"""Build and run one C/C++ file through CMake.

  python run.py                   build src/main.cpp and run it
  python run.py -f src/foo.c      build a different file
  python run.py -s 23             C++ standard 17, 20 or 23
  python run.py -i                use `import std;` (C++23 std module)
  python run.py -r                Release build
  python run.py -c                wipe the build directory first
  python run.py -B                build only, do not run
  python run.py -- --flag arg     pass arguments to the program
"""
import argparse
import os
import shutil
import subprocess
import sys


def main(argv):
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("-f", "--file", default="")
    parser.add_argument("-s", "--std", choices=["17", "20", "23"], default="")
    parser.add_argument("-i", "--import-std", action="store_true")
    parser.add_argument("-r", "--release", action="store_true")
    parser.add_argument("-c", "--clean", action="store_true")
    parser.add_argument("-B", "--build-only", action="store_true")
    parser.add_argument("-h", "--help", action="store_true")
    # Everything after `--` belongs to the program, not to this script.
    if "--" in argv:
        split = argv.index("--")
        argv, program_args = argv[:split], argv[split + 1:]
    else:
        program_args = []
    args = parser.parse_args(argv)

    if args.help:
        print(__doc__)
        return 0

    root = os.path.dirname(os.path.abspath(__file__))
    # A separate build directory for `import std`: on CMake before 4.5 the
    # experimental gate has to be set before compiler detection, which an
    # existing cache cannot do; either way the std module build stays separate.
    build = os.path.join(root, "build-import-std" if args.import_std else "build")
    config = "Release" if args.release else "Debug"

    if args.clean:
        for name in ("build", "build-import-std"):
            shutil.rmtree(os.path.join(root, name), ignore_errors=True)

    configure = ["cmake", "-S", root, "-B", build, f"-DCMAKE_BUILD_TYPE={config}"]
    generator = os.environ.get("CMAKE_GENERATOR") or (
        "Ninja" if shutil.which("ninja") else ""
    )
    if generator:
        configure += ["-G", generator]
    if args.file:
        configure.append(f"-DFILE={args.file}")
    if args.std:
        configure.append(f"-DCPP_STD={args.std}")
    configure.append("-DIMPORT_STD=" + ("ON" if args.import_std else "OFF"))

    subprocess.run(configure, check=True)
    subprocess.run(
        ["cmake", "--build", build, "--target", "app", "--config", config],
        check=True,
    )
    if args.build_only:
        return 0

    exe = os.path.join(build, "app")
    if os.path.exists(exe + ".exe"):
        exe += ".exe"
    return subprocess.run([exe, *program_args]).returncode


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
