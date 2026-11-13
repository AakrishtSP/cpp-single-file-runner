cmake_minimum_required(VERSION 3.20)

# Options are declared before project() because `import std` must be gated
# before a compiler is detected.
set(CPP_STD "20" CACHE STRING "C++ standard: 17, 20 or 23")
set_property(CACHE CPP_STD PROPERTY STRINGS 17 20 23)
option(IMPORT_STD "Use 'import std;' instead of #include (C++23; needs a toolchain with std modules)" OFF)

if(IMPORT_STD)
  if(CMAKE_VERSION VERSION_LESS 3.30)
    message(FATAL_ERROR "IMPORT_STD needs CMake >= 3.30 (module scanning).")
  endif()
  set(CPP_STD "23")
  # CMake 4.5 made `import std` a normal feature; before that it is gated by an
  # experimental UUID that changes per release and must be set before the
  # compiler is detected. All released gates are filled in below.
  if(CMAKE_VERSION VERSION_LESS 4.5 AND NOT CMAKE_EXPERIMENTAL_CXX_IMPORT_STD)
    if(CMAKE_VERSION VERSION_LESS 3.31)
      set(CMAKE_EXPERIMENTAL_CXX_IMPORT_STD "0e5b6991-d74f-4b3d-a41c-cf096e0b2508")
    elseif(CMAKE_VERSION VERSION_LESS 4.4)
      set(CMAKE_EXPERIMENTAL_CXX_IMPORT_STD "a9e1cf81-9932-4810-974b-6eccaf14e457")
    else()
      set(CMAKE_EXPERIMENTAL_CXX_IMPORT_STD "f35a9ac6-8463-4d38-8eec-5d6008153e7d")
    endif()
  endif()
endif()

# Language is decided after the source file is known, so the project starts
# with no languages enabled: a C-only user must not need a C++ compiler.
project(single_file_runner LANGUAGES NONE)

# ---------------------------------------------------------------------------
# Pick the source file: -DFILE=..., else src/main.cpp / src/main.c, else the
# only source file in src/.
# ---------------------------------------------------------------------------
set(FILE "" CACHE STRING "Source file to build (default: src/main.cpp or src/main.c)")
set(_pick "")
if(NOT FILE)
  foreach(_candidate src/main.cpp src/main.c src/main.cc src/main.cxx)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${_candidate}")
      set(_pick "${_candidate}")
      break()
    endif()
  endforeach()
  if(NOT _pick)
    file(GLOB _sources CONFIGURE_DEPENDS
      "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp" "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c")
    list(LENGTH _sources _n)
    if(_n EQUAL 0)
      message(FATAL_ERROR "No source found. Put a file in src/ or pass -DFILE=path/to/file.cpp")
    endif()
    list(GET _sources 0 _pick)
    file(RELATIVE_PATH _pick "${CMAKE_CURRENT_SOURCE_DIR}" "${_pick}")
  endif()
  set(FILE "${_pick}")
endif()

if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${FILE}" AND NOT EXISTS "${FILE}")
  message(FATAL_ERROR "FILE does not exist: ${FILE}")
endif()

get_filename_component(_ext "${FILE}" EXT)
if(_ext STREQUAL ".c")
  enable_language(C)
else()
  enable_language(CXX)
endif()

if(IMPORT_STD AND _ext STREQUAL ".c")
  message(FATAL_ERROR "IMPORT_STD is a C++ feature; ${FILE} is C.")
endif()

add_executable(app "${FILE}")

if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
  set_target_properties(app PROPERTIES C_STANDARD 17 C_STANDARD_REQUIRED ON)
endif()
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang|MSVC")
  set_target_properties(app PROPERTIES
    CXX_STANDARD "${CPP_STD}"
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF)
endif()
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  target_compile_options(app PRIVATE -Wall -Wextra)
endif()
if(IMPORT_STD)
  # Scanning is what actually enables `import std`; since CMake 4.5 nothing else
  # is needed. Older releases additionally want CXX_MODULE_STD on the target.
  set_target_properties(app PROPERTIES CXX_SCAN_FOR_MODULES ON)
  if(CMAKE_VERSION VERSION_LESS 4.5)
    set_target_properties(app PROPERTIES CXX_MODULE_STD ON)
  endif()
endif()

target_include_directories(app PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")
set_target_properties(app PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

if(_ext STREQUAL ".c")
  message(STATUS "Building ${FILE} (C17) -> ${CMAKE_BINARY_DIR}/app")
elseif(IMPORT_STD)
  message(STATUS "Building ${FILE} (C++${CPP_STD}, import std) -> ${CMAKE_BINARY_DIR}/app")
else()
  message(STATUS "Building ${FILE} (C++${CPP_STD}) -> ${CMAKE_BINARY_DIR}/app")
endif()
