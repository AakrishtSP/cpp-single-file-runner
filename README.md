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
./run.sh                 # Linux / macOS / Git Bash: build src/main.cpp, run it
./run.ps1                # Windows PowerShell: same thing
```

Plain CMake works too: `cmake -S . -B build && cmake --build build && ./build/app`.

## Build another file

```bash
./run.sh -f examples/hello.c              # C file
./run.sh -f path/to/other.cpp -- --flag 42
./run.sh -i -f examples/import_std.cpp    # C++23 `import std;`
```

Nothing needs editing: the source file is a CMake cache variable.

## Flags

| `run.sh` | `run.ps1` | Meaning |
|---|---|---|
| `-f, --file <path>` | `-File <path>` | Source file (default `src/main.cpp`) |
| `-s, --std <17\|20\|23>` | `-Std <17\|20\|23>` | C++ standard, default 20 |
| `-i, --import-std` | `-ImportStd` | Use `import std;` (builds in `build-import-std/`) |
| `-r, --release` | `-Release` | Release build instead of Debug |
| `-c, --clean` | `-Clean` | Delete both build directories first |
| `-B, --build-only` | `-BuildOnly` | Build without running |
| `-h, --help` | — | Usage |
| `-- args...` | `-- args...` | Everything after `--` goes to the program |

The scripts use Ninja when installed (same generator everywhere, faster
builds) and let CMake choose otherwise. Override with `CMAKE_GENERATOR`.

## `import std`

```bash
./run.sh -i -f examples/import_std.cpp
```

Needs CMake ≥ 3.30, Ninja ≥ 1.11, and a toolchain that can build the standard
library module (GCC 15+, Clang 18+, MSVC 19.40+). CMake gates the feature with
an experimental UUID that changes between releases; `CMakeLists.txt` fills in
the ones it knows and you can override `CMAKE_EXPERIMENTAL_CXX_IMPORT_STD`
yourself.

`import std` gets its own build directory (`build-import-std/`) because the gate
must be set *before* compiler detection — flipping it inside an existing cache
makes CMake refuse to generate. Switching back is just leaving the flag off.

## Layout

```
.
├── CMakeLists.txt      # -DFILE=..., C/C++ from the extension, CPP_STD, IMPORT_STD
├── CMakePresets.json   # default | release | import-std | make
├── run.sh, run.ps1     # configure + build + run helpers
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

`settings.json` sets the CMake source/build directory, generator, C++20
IntelliSense, and `-Wall -Wextra`; `c_cpp_properties.json` reads the compile
database so includes resolve exactly as the compiler sees them.

## Other IDEs

`CMakePresets.json` is read by VS Code CMake Tools, CLion, Visual Studio, Qt
Creator and most CMake-aware editors — pick the `default` preset (or
`import-std`). No IDE-specific project files are needed.

## Requirements

- CMake ≥ 3.20
- GCC or Clang (Linux/macOS), MinGW-w64 or MSVC (Windows)
- Ninja (optional, recommended)
- PowerShell 5.1+ for `run.ps1`

## License

MIT — see [LICENSE](LICENSE).
