// Default single file. Edit this, then press Run (or ./run.sh).
//
// Build a different file without touching this one:
//   ./run.sh -f examples/hello.c
//   ./run.sh -i -f examples/import_std.cpp   # C++23 `import std;`
#include <iostream>

int main() {
    std::cout << "Hello from the single-file CMake runner.\n";
    return 0;
}
