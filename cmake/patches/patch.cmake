# Copyright 2026 Yeicor
# SPDX-License-Identifier: MIT
# Portions of this file are derived from Yeicor/OCP.wasm

if(NOT DEFINED REAL_SOURCE_DIR)
  message(FATAL_ERROR "REAL_SOURCE_DIR must be defined")
endif()

set(FILE "${REAL_SOURCE_DIR}/CMakeLists.txt")
file(READ "${FILE}" CONTENTS)
set(NEW_CONTENTS "${CONTENTS}")

# Patch 1: Shared library support
string(REPLACE "# Shared library\nadd_library" "# Shared library\nset_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)\nadd_library" NEW_CONTENTS "${NEW_CONTENTS}")

# Patch 2: Environment settings (Only needed for Emscripten usually, but safe to keep)
if(EMSCRIPTEN)
    string(REPLACE "COMMAND ${CMAKE_COMMAND}"
                  "COMMAND /usr/bin/env \"CFLAGS=$CMAKE_C_FLAGS\" emcmake ${CMAKE_COMMAND}"
                  NEW_CONTENTS "${NEW_CONTENTS}")
endif()

# Patch 3: Remove OUTPUT_QUIET
string(REPLACE "OUTPUT_QUIET" "" NEW_CONTENTS "${NEW_CONTENTS}")

# Patch 4: Disable binary stripping
string(REPLACE "if (STRIP_BINARIES" "if (FALSE AND STRIP_BINARIES" NEW_CONTENTS "${NEW_CONTENTS}")

if(NOT "${CONTENTS}" STREQUAL "${NEW_CONTENTS}")
    file(WRITE "${FILE}" "${NEW_CONTENTS}")
    message(STATUS "Patched: ${FILE}")
else()
    message(STATUS "No changes made to: ${FILE}")
endif()
