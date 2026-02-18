cmake_minimum_required(VERSION 3.24)
project(${SKBUILD_PROJECT_NAME} LANGUAGES C CXX VERSION ${SKBUILD_PROJECT_VERSION})

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# --- Overload install command (Keep this!) ---
function(install)
  if("${ARGV0}" STREQUAL "INSTALL_ME")
    list(SUBLIST ARGV 1 -1 rest_args)
    _install(${rest_args})
  else()
    message(STATUS "Skipping upstream install rule for: ${ARGV}")
  endif()
endfunction()

include(FetchContent)
Set(FETCHCONTENT_QUIET FALSE)

# --- 1. Fetch Lib3MF C++ Source ---
FetchContent_Declare(
  lib3mf
  GIT_REPOSITORY "https://github.com/3MFConsortium/lib3mf.git"
  GIT_TAG "v2.4.1"
  GIT_PROGRESS TRUE
  PATCH_COMMAND "${CMAKE_COMMAND}" "-DREAL_SOURCE_DIR=<SOURCE_DIR>" -P "${CMAKE_CURRENT_LIST_DIR}/cmake/patches/patch.cmake"
  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(lib3mf)

# --- 2. WASM (Emscripten) Build Strategy ---
if(EMSCRIPTEN)
  message(STATUS "Configuring for Emscripten (WASM)...")

  FetchContent_Declare(
    lib3mf-wheel-original
    URL "https://github.com/3MFConsortium/lib3mf/releases/download/v2.4.1/lib3mf-2.4.1-py3-none-manylinux2014_x86_64.whl"
  )
  FetchContent_MakeAvailable(lib3mf-wheel-original)

  FetchContent_GetProperties(lib3mf lib3mf-wheel-original)
  set(WHEEL_CONTENTS_DIR "${CMAKE_CURRENT_BINARY_DIR}/lib3mf-wheel-contents")

  add_custom_command(
    DEPENDS lib3mf
    OUTPUT "${WHEEL_CONTENTS_DIR}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${WHEEL_CONTENTS_DIR}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${WHEEL_CONTENTS_DIR}/lib3mf"
    
    # Copy Python files from the official wheel
    COMMAND /bin/sh -c "cp '${lib3mf-wheel-original_SOURCE_DIR}/lib3mf/'*.py '${WHEEL_CONTENTS_DIR}/lib3mf/'"
    
    # Patch Python files for Emscripten
    COMMAND /bin/sh -c "sed -i 's/linux/emscripten/g;s/Linux/Emscripten/g' '${WHEEL_CONTENTS_DIR}/lib3mf/'*.py"
    COMMAND /bin/sh -c "patch -p1 '${WHEEL_CONTENTS_DIR}/lib3mf/Lib3MF.py' < '${CMAKE_CURRENT_LIST_DIR}/cmake/patches/Lib3MF.py.patch'"
    
    # Copy Compiled WASM
    COMMAND /bin/sh -c "cp '${lib3mf_BINARY_DIR}/lib3mf.so' '${WHEEL_CONTENTS_DIR}/lib3mf/lib3mf.so'"
    COMMAND /bin/sh -c "[ -f '${lib3mf_BINARY_DIR}/lib3mf.wasm.debug.wasm' ] && cp '${lib3mf_BINARY_DIR}/lib3mf.wasm.debug.wasm' '${WHEEL_CONTENTS_DIR}/lib3mf/lib3mf.wasm.debug.wasm' || true"
    
    # NEW: Overwrite __init__.py with our local version (to support Pyodide/Emscripten checks)
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_SOURCE_DIR}/py_lib3mf/__init__.py" "${WHEEL_CONTENTS_DIR}/lib3mf/__init__.py"
    
    VERBATIM
  )

  add_custom_target(lib3mf-wheel-target ALL DEPENDS "${WHEEL_CONTENTS_DIR}")
  
  # Install the constructed folder. 
  # This creates 'lib3mf' in the wheel root because WHEEL_CONTENTS_DIR contains a 'lib3mf' folder.
  install(INSTALL_ME DIRECTORY "${WHEEL_CONTENTS_DIR}/" DESTINATION ".")

# --- 3. Native / Aarch64 Build Strategy ---
else()
  message(STATUS "Configuring for Native/Aarch64...")

  # 1. Install the shared library to 'lib3mf' (was py_lib3mf)
  install(INSTALL_ME TARGETS lib3mf DESTINATION "lib3mf")

  # 2. Install the wrapper to 'lib3mf'
  install(
    INSTALL_ME 
    FILES "${lib3mf_SOURCE_DIR}/Bindings/Python/Lib3MF.py" 
    DESTINATION "lib3mf"
  )
  
  # 3. Install our local __init__.py to 'lib3mf'
  install(
    INSTALL_ME 
    FILES "${CMAKE_CURRENT_SOURCE_DIR}/py_lib3mf/__init__.py"
    DESTINATION "lib3mf"
  )

endif()
