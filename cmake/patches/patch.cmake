# Copyright 2026 Yeicor
# SPDX-License-Identifier: MIT
# Portions of this file are derived from Yeicor/OCP.wasm

if(NOT DEFINED REAL_SOURCE_DIR)
  message(FATAL_ERROR "REAL_SOURCE_DIR must be defined")
endif()

# --- Patch 1: Main CMakeLists.txt ---
set(FILE "${REAL_SOURCE_DIR}/CMakeLists.txt")
file(READ "${FILE}" CONTENTS)
set(NEW_CONTENTS "${CONTENTS}")

# Shared library support
string(REPLACE "# Shared library\nadd_library" "# Shared library\nset_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)\nadd_library" NEW_CONTENTS "${NEW_CONTENTS}")

# Environment settings (Only needed for Emscripten usually, but safe to keep)
if(EMSCRIPTEN)
    string(REPLACE "COMMAND ${CMAKE_COMMAND}"
                  "COMMAND /usr/bin/env \"CFLAGS=$CMAKE_C_FLAGS\" emcmake ${CMAKE_COMMAND}"
                  NEW_CONTENTS "${NEW_CONTENTS}")
endif()

# Remove OUTPUT_QUIET
string(REPLACE "OUTPUT_QUIET" "" NEW_CONTENTS "${NEW_CONTENTS}")

# Disable binary stripping
string(REPLACE "if (STRIP_BINARIES" "if (FALSE AND STRIP_BINARIES" NEW_CONTENTS "${NEW_CONTENTS}")

if(NOT "${CONTENTS}" STREQUAL "${NEW_CONTENTS}")
    file(WRITE "${FILE}" "${NEW_CONTENTS}")
    message(STATUS "Patched: ${FILE}")
else()
    message(STATUS "No changes made to: ${FILE}")
endif()

# --- Patch 2: libzip cmake-config.h.in (CRITICAL for WASM) ---
set(FILE "${REAL_SOURCE_DIR}/Libraries/libzip/cmake-config.h.in")
# Check if file exists in standard location, otherwise fallback to submodules path
if(NOT EXISTS "${FILE}")
    set(FILE "${REAL_SOURCE_DIR}/submodules/libzip/cmake-config.h.in")
endif()

if(EXISTS "${FILE}")
    file(READ "${FILE}" CONTENTS)
    set(NEW_CONTENTS "${CONTENTS}")

    # Match and comment lines that cause issues in Emscripten
    string(REGEX REPLACE "#cmakedefine[ \t]+[A-Za-z0-9_]*_S\n" "// &" NEW_CONTENTS "${NEW_CONTENTS}")
    string(REGEX REPLACE "#cmakedefine[ \t]+HAVE_ARC4RANDOM\n" "// &" NEW_CONTENTS "${NEW_CONTENTS}")
    string(REGEX REPLACE "#cmakedefine[ \t]+HAVE_CLONEFILE\n" "// &" NEW_CONTENTS "${NEW_CONTENTS}")

    if(NOT "${CONTENTS}" STREQUAL "${NEW_CONTENTS}")
        file(WRITE "${FILE}" "${NEW_CONTENTS}")
        message(STATUS "Patched: ${FILE}")
    else()
        message(STATUS "No changes made to: ${FILE}")
    endif()
else()
    message(WARNING "Could not find libzip/cmake-config.h.in to patch at ${REAL_SOURCE_DIR}")
endif()

# --- Patch 3: Fix missing <algorithm> include in NMR_ResourceDependencySorter.cpp (Fixes Aarch64 Build) ---
set(FILE "${REAL_SOURCE_DIR}/Source/Model/Writer/v100/NMR_ResourceDependencySorter.cpp")
if(EXISTS "${FILE}")
    file(READ "${FILE}" CONTENTS)
    if(NOT "${CONTENTS}" MATCHES "#include <algorithm>")
        set(NEW_CONTENTS "#include <algorithm>\n${CONTENTS}")
        file(WRITE "${FILE}" "${NEW_CONTENTS}")
        message(STATUS "Patched: ${FILE} (Added <algorithm>)")
    else()
        message(STATUS "No changes made to: ${FILE} (Already has <algorithm>)")
    endif()
else()
    message(WARNING "Could not find NMR_ResourceDependencySorter.cpp to patch at ${FILE}")
endif()
