
cmake_minimum_required(VERSION 3.24)
project(${SKBUILD_PROJECT_NAME} LANGUAGES C CXX VERSION ${SKBUILD_PROJECT_VERSION})

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

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

  # Download the original Manylinux wheel to "repack" (reuse python structure, replace binary)
  FetchContent_Declare(
    lib3mf-wheel-original
    URL "https://github.com/3MFConsortium/lib3mf/releases/download/v2.4.1/lib3mf-2.4.1-py3-none-manylinux2014_x86_64.whl"
  )
  FetchContent_MakeAvailable(lib3mf-wheel-original)

  FetchContent_GetProperties(lib3mf lib3mf-wheel-original)
  set(WHEEL_CONTENTS_DIR "${CMAKE_CURRENT_BINARY_DIR}/lib3mf-wheel-contents")

  # Create the wheel structure
  add_custom_command(
    DEPENDS lib3mf
    OUTPUT "${WHEEL_CONTENTS_DIR}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${WHEEL_CONTENTS_DIR}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${WHEEL_CONTENTS_DIR}/lib3mf"
    
    # Copy Python files from the official wheel
    COMMAND /bin/sh -c "cp '${lib3mf-wheel-original_SOURCE_DIR}/lib3mf/'*.py '${WHEEL_CONTENTS_DIR}/lib3mf/'"
    
    # Patch Python files for Emscripten (Linux -> Emscripten)
    COMMAND /bin/sh -c "sed -i 's/linux/emscripten/g;s/Linux/Emscripten/g' '${WHEEL_CONTENTS_DIR}/lib3mf/'*.py"
    
    # Apply the ctypes 32-bit patch (CRITICAL for WASM)
    COMMAND /bin/sh -c "patch -p1 '${WHEEL_CONTENTS_DIR}/lib3mf/Lib3MF.py' < '${CMAKE_CURRENT_LIST_DIR}/cmake/patches/Lib3MF.py.patch'"
    
    # Copy the compiled WASM binary (built by FetchContent lib3mf above)
    COMMAND /bin/sh -c "cp '${lib3mf_BINARY_DIR}/lib3mf.so' '${WHEEL_CONTENTS_DIR}/lib3mf/lib3mf.so'"
    
    # Optional: Copy debug maps if they exist
    COMMAND /bin/sh -c "[ -f '${lib3mf_BINARY_DIR}/lib3mf.wasm.debug.wasm' ] && cp '${lib3mf_BINARY_DIR}/lib3mf.wasm.debug.wasm' '${WHEEL_CONTENTS_DIR}/lib3mf/lib3mf.wasm.debug.wasm' || true"
    
    VERBATIM
  )

  add_custom_target(lib3mf-wheel-target ALL DEPENDS "${WHEEL_CONTENTS_DIR}")
  
  # Install the constructed folder into the wheel
  install(DIRECTORY "${WHEEL_CONTENTS_DIR}/" DESTINATION ".")

# --- 3. Native / Aarch64 Build Strategy ---
else()
  message(STATUS "Configuring for Native/Aarch64...")

  # For Aarch64, we rely on the FetchContent build of lib3mf defined above.
  # We just need to install the shared library and the python wrapper from the source.

  # 1. Install the shared library
  install(TARGETS lib3mf DESTINATION "py_lib3mf")

  # 2. Install the Python wrapper code (from the fetched source, NOT the wheel)
  # Note: ocp.wasm patches Lib3MF.py for WASM, but for Aarch64 we want the standard one.
  # However, py-lib3mf repo HAS a wrapper in `py_lib3mf/Lib3MF.py`.
  # We should use the one from the lib3mf repo to ensure version match (v2.4.1), 
  # OR use the one in this repo if it's updated. 
  # Assuming we want to ship v2.4.1 logic:
  
  install(
    FILES "${lib3mf_SOURCE_DIR}/Bindings/Python/Lib3MF.py" 
    DESTINATION "py_lib3mf"
  )
  
  # Install the package init
  install(
    FILES "${CMAKE_CURRENT_SOURCE_DIR}/py_lib3mf/__init__.py"
    DESTINATION "py_lib3mf"
  )

endif()
