# Single-file C/C++ runner (CMake + VS Code)

Build and run one `.c` / `.cpp` file without writing a build system, on Linux,
macOS and Windows. `src/main.cpp` is the default target; any other file can be
built with one flag. Legacy `<graphics.h>` (libbgi) is supported as an opt-in
for MinGW, because that library is the reason this template exists.

## Quick start

```bash
./run.sh                 # Linux / macOS / Git Bash: build src/main.cpp, run it
./run.ps1                # Windows PowerShell: same thing
cmake -S . -B build && cmake --build build && ./build/app   # plain CMake
```

Build another file (nothing else to edit):

```bash
./run.sh -f examples/graphics_demo.cpp
./run.sh -f path/to/other.c -- --flag 42     # arguments go to the program
```

## Flags

| `run.sh` | `run.ps1` | Meaning |
|---|---|---|
| `-f, --file <path>` | `-File <path>` | Source file to build (default `src/main.cpp`) |
| `-r, --release` | `-Release` | Release build instead of Debug |
| `-g, --graphics` | `-Graphics` | Link `lib/libbgi.a` (`GRAPHICS=ON`) |
| `-c, --clean` | `-Clean` | Delete `build/` first |
| `-B, --build-only` | `-BuildOnly` | Build without running |
| `-h, --help` | — | Usage |
| `-- args...` | `-- args...` | Everything after `--` is passed to the program |

The scripts use Ninja when it is installed (same generator everywhere, faster
builds), otherwise they let CMake choose. Override with `CMAKE_GENERATOR`.

## Layout

```
.
├── CMakeLists.txt          # single-file target, picks C or C++ from the extension
├── CMakePresets.json       # default / release / graphics / make
├── run.sh, run.ps1         # configure + build + run helpers
├── src/main.cpp            # default target
├── examples/graphics_demo.cpp
├── include/                # graphics.h, winbgi.h (libbgi headers)
├── lib/libbgi.a            # static WinBGIm library (MinGW, Win32)
└── .vscode/                # settings, tasks, launch, IntelliSense, extensions
```

`CMakeLists.txt` reads the source from `-DFILE=...`, else `src/main.cpp`,
else `src/main.c`, else the only file in `src/`. The language is enabled from
the file extension, so a C-only machine never needs a C++ compiler.

## `graphics.h`

`graphics.h` is the Turbo C++ API; `libbgi` reimplements it on Win32, so it only
links on **Windows with MinGW**:

```bash
./run.sh -g -f examples/graphics_demo.cpp
```

`GRAPHICS=ON` adds `lib/libbgi.a` and the Win32 libraries it needs (`gdi32`,
`comdlg32`, `uuid`, `oleaut32`, `ole32`, `msimg32`) and links the C/C++
runtimes statically, which is what stops the old library from failing at
startup. On other platforms CMake stops with a clear error instead of a
confusing link failure.

## VS Code

Open the folder and accept the recommended extensions (`cpptools`,
`cmake-tools`). Then:

- **Ctrl+Shift+B** — build (`Build` task, default).
- **Ctrl+Shift+P → Tasks: Run Task** — `Run`, `Run current file`,
  `Build current file`, `Run (graphics.h)`, `Clean`.
- **F5** — debug the CMake target with `preLaunchTask: Build`
  (gdb on Linux/MinGW, lldb on macOS).

`settings.json` already sets the CMake source/build directory, the generator,
C++20 IntelliSense, `include/` on the include path, and `-Wall -Wextra`.
`c_cpp_properties.json` reads the compile database, so includes resolve exactly
as the compiler sees them.

## Other IDEs

`CMakePresets.json` is read by VS Code CMake Tools, CLion, Visual Studio, Qt
Creator and most CMake-aware editors: pick the `default` preset, or
`graphics` on Windows. No IDE-specific project files are needed — anything that
can open a CMake project works.

## Requirements

- CMake ≥ 3.20
- A C/C++ toolchain: GCC or Clang (Linux/macOS), MinGW-w64 (Windows)
- Ninja (optional, recommended)
- PowerShell 5.1+ on Windows if you prefer `run.ps1` over `run.sh` in Git Bash
