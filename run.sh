#!/usr/bin/env bash
# Build and run one C/C++ file through CMake.
#
#   ./run.sh                     build src/main.cpp and run it
#   ./run.sh -f src/foo.c        build a different file
#   ./run.sh -s 23               C++ standard 17, 20 or 23
#   ./run.sh -i                  use `import std;` (C++23 std module)
#   ./run.sh -r                  Release build
#   ./run.sh -c                  wipe the build directory first
#   ./run.sh -B                  build only, do not run
#   ./run.sh -- --flag arg       pass arguments to the program (also: ./run.sh - arg)
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
file=""
std=""
config="Debug"
import_std=0
clean=0
build_only=0
prog_args=()

usage() { sed -n '3,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    -f|--file)       file="${2:?-f needs a path}"; shift 2 ;;
    -s|--std)        std="${2:?-s needs 17, 20 or 23}"; shift 2 ;;
    -i|--import-std) import_std=1; shift ;;
    -r|--release)    config="Release"; shift ;;
    -c|--clean)      clean=1; shift ;;
    -B|--build-only) build_only=1; shift ;;
    -h|--help)       usage; exit 0 ;;
    --)              shift; prog_args=("$@"); break ;;
    -*)              echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)               prog_args=("$@"); break ;;
  esac
done

# `import std` is gated before compiler detection, so it gets its own build
# directory: flipping the flag inside one cache makes CMake refuse to generate.
if [ "$import_std" -eq 1 ]; then
  build="$root/build-import-std"
else
  build="$root/build"
fi

if [ "$clean" -eq 1 ]; then
  rm -rf "$build" "$root/build" "$root/build-import-std"
fi

# Ninja when present: same generator on every machine, faster builds.
if [ -n "${CMAKE_GENERATOR:-}" ]; then
  generator="$CMAKE_GENERATOR"
elif command -v ninja >/dev/null 2>&1; then
  generator="Ninja"
else
  generator=""
fi

configure=(-S "$root" -B "$build" -DCMAKE_BUILD_TYPE="$config")
[ -n "$generator" ] && configure+=(-G "$generator")
[ -n "$file" ] && configure+=(-DFILE="$file")
[ -n "$std" ] && configure+=(-DCPP_STD="$std")
if [ "$import_std" -eq 1 ]; then
  configure+=(-DIMPORT_STD=ON)
else
  configure+=(-DIMPORT_STD=OFF)
fi

cmake "${configure[@]}"
cmake --build "$build" --target app --config "$config"

[ "$build_only" -eq 1 ] && exit 0

exe="$build/app"
[ -x "$exe.exe" ] && exe="$exe.exe"
exec "$exe" ${prog_args[@]+"${prog_args[@]}"}
