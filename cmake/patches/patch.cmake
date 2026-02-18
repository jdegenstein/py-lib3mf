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
# Note: lib3mf structure puts libzip in Libraries/libzip. 
# If that path fails, check if it's submodules/libzip or similar in the fetched source.
# Based on OCP.wasm, it might be "submodules/libzip" or "Libraries/libzip".
# Let's try to detect or just use the relative path found in lib3mf source.
# The error log shows: _deps/lib3mf-src/Libraries/libzip/Include/zipint.h
# So it is likely "Libraries/libzip".

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
     # Fallback: check submodules/libzip (OCP.wasm used this path)
     set(FILE "${REAL_SOURCE_DIR}/submodules/libzip/cmake-config.h.in")
     if(EXISTS "${FILE}")
        file(READ "${FILE}" CONTENTS)
        set(NEW_CONTENTS "${CONTENTS}")
        string(REGEX REPLACE "#cmakedefine[ \t]+[A-Za-z0-9_]*_S\n" "// &" NEW_CONTENTS "${NEW_CONTENTS}")
        string(REGEX REPLACE "#cmakedefine[ \t]+HAVE_ARC4RANDOM\n" "// &" NEW_CONTENTS "${NEW_CONTENTS}")
        string(REGEX REPLACE "#cmakedefine[ \t]+HAVE_CLONEFILE\n" "// &" NEW_CONTENTS "${NEW_CONTENTS}")
        if(NOT "${CONTENTS}" STREQUAL "${NEW_CONTENTS}")
            file(WRITE "${FILE}" "${NEW_CONTENTS}")
            message(STATUS "Patched: ${FILE}")
        endif()
     else()
        message(WARNING "Could not find libzip/cmake-config.h.in to patch at ${REAL_SOURCE_DIR}")
     endif()
endif()
