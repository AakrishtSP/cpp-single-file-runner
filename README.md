# Single-file C/C++ runner

A GitHub template: build and run one `.c` / `.cpp` file with CMake, no build
system to write. `src/main.cpp` is the default target; any other file builds
with one flag. Works on Linux, macOS and Windows.

## Use this template

Click **Use this template → Create a new repository**, or clone it and start
writing code:

```bash
git clone https://github.com/AakrishtSP/cpp-single-file-runner my-lab
cd my-lab
./run.sh                 # Linux / macOS / Git Bash
python run.py            # Windows, or anywhere with Python 3
```

Both do the same thing: configure, build `src/main.cpp`, run it. Plain CMake
works too: `cmake -S . -B build && cmake --build build && ./build/app`.

## Build another file

```bash
./run.sh -f examples/hello.c              # C file
python run.py -f path/to/other.cpp -- --flag 42
./run.sh -i -f examples/import_std.cpp    # C++23 `import std;`
```

Nothing needs editing: the source file is a CMake cache variable.

## Flags

`run.sh` and `run.py` take the same short flags (Python also accepts the long
ones, e.g. `--import-std`).

| Flag | Meaning |
|---|---|
| `-f, --file <path>` | Source file (default `src/main.cpp`) |
| `-s, --std <17\|20\|23>` | C++ standard, default 20 |
| `-i, --import-std` | Use `import std;` (builds in `build-import-std/`) |
| `-r, --release` | Release build instead of Debug |
| `-c, --clean` | Delete both build directories first |
| `-B, --build-only` | Build without running |
| `-h, --help` | Usage |
| `-- args...` | Everything after `--` goes to the program |

The scripts use Ninja when installed (same generator everywhere, faster
builds) and let CMake choose otherwise. Override with `CMAKE_GENERATOR`.

## `import std`

```bash
./run.sh -i -f examples/import_std.cpp
```

Needs Ninja ≥ 1.11 and a toolchain that can build the standard library module
(GCC 15+, Clang 18+, MSVC 19.36+). CMake 4.5 and newer support it directly —
`CXX_SCAN_FOR_MODULES` is all it asks for. On CMake 3.30–4.4 the feature is
gated by an experimental UUID that changes per release, and `CMakeLists.txt`
fills in every published one.

`import std` gets its own build directory (`build-import-std/`). On CMake
before 4.5 the gate has to be set *before* compiler detection, which an
existing cache cannot do; either way the std module build stays out of the way
of normal builds. Switching back is just leaving the flag off.

## Layout

```
.
├── CMakeLists.txt      # -DFILE=..., C/C++ from the extension, CPP_STD, IMPORT_STD
├── CMakePresets.json   # default | release | import-std | make
├── run.sh, run.py      # configure + build + run helpers
├── src/main.cpp        # default target
├── examples/           # hello.c, import_std.cpp
└── .vscode/            # settings, tasks, launch, IntelliSense, extensions
```

`CMakeLists.txt` reads the source from `-DFILE=...`, else `src/main.cpp`, else
`src/main.c`, else the only file in `src/`. The language is enabled from the
file extension, so a C-only machine never needs a C++ compiler.

## VS Code

Open the folder and accept the recommended extensions (`cpptools`,
`cmake-tools`). Then:

- **Ctrl+Shift+B** — build (`Build` task, default).
- **Ctrl+Shift+P → Tasks: Run Task** — `Run`, `Build current file`,
  `Run current file`, `Run current file with import std`, `Clean`.
- **F5** — debug the CMake target with `preLaunchTask: Build`
  (gdb on Linux/MinGW, lldb on macOS).

The tasks run `./run.sh` on Linux/macOS and `python run.py` on Windows, so no
extra setup. `settings.json` sets the CMake source/build directory, generator,
C++20 IntelliSense, and `-Wall -Wextra`; `c_cpp_properties.json` reads the
compile database so includes resolve exactly as the compiler sees them.

## Other IDEs

`CMakePresets.json` is read by VS Code CMake Tools, CLion, Visual Studio, Qt
Creator and most CMake-aware editors — pick the `default` preset (or
`import-std`). No IDE-specific project files are needed.

## Requirements

- CMake ≥ 3.20
- GCC or Clang (Linux/macOS), MinGW-w64 or MSVC (Windows)
- Ninja (optional, recommended)
- Python 3.8+ (only for `run.py`)

## License

MIT — see [LICENSE](LICENSE).
