// C++23 standard-library module. Needs CMake >= 3.30, Ninja, and a toolchain
// that can build `std` (GCC 15+, Clang 18+, MSVC 19.40+):
//   ./run.sh -i -f examples/import_std.cpp
import std;

int main() {
    std::vector<std::string> words{"import", "std", "works"};
    for (const auto& w : words) std::println("{}", w);
    return 0;
}
