cmake_minimum_required(VERSION 3.20)

# Language is decided after the source file is known, so the project starts
# with no languages enabled: a C-only user must not need a C++ compiler.
project(single_file_runner LANGUAGES NONE)

set(GRAPHICS OFF CACHE BOOL "Link the legacy graphics.h (libbgi). Windows + MinGW only.")

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

add_executable(app "${FILE}")

target_include_directories(app PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/include")
set_target_properties(app PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  target_compile_options(app PRIVATE -Wall -Wextra)
endif()

# ---------------------------------------------------------------------------
# graphics.h: the Turbo C++ API, reimplemented by libbgi (WinBGIm). It is a
# Win32 library built for MinGW, so it cannot be linked anywhere else.
# ---------------------------------------------------------------------------
if(GRAPHICS)
  if(NOT WIN32)
    message(FATAL_ERROR "GRAPHICS=ON needs Windows + MinGW (libbgi is a Win32 library).")
  endif()
  if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/lib/libbgi.a")
    message(FATAL_ERROR "lib/libbgi.a is missing.")
  endif()
  target_link_libraries(app PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/lib/libbgi.a"
    gdi32 comdlg32 uuid oleaut32 ole32 msimg32)
  target_link_options(app PRIVATE -static-libgcc -static-libstdc++)
  message(STATUS "graphics.h enabled: linking lib/libbgi.a")
endif()

message(STATUS "Building ${FILE} -> ${CMAKE_BINARY_DIR}/app")
