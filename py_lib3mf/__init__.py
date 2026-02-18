__version__ = "2.4.1"

import platform
from . import Lib3MF

system = platform.system().lower()
machine = platform.machine().lower()

# Allow Linux, Darwin, Windows, AND Emscripten (WASM)
if system not in ("linux", "darwin", "windows", "emscripten"):
    raise OSError(f"Unsupported Operating System: {system}")

# Relax machine checks to include aarch64/arm64 and wasm
if system == "linux":
    if machine not in ("x86_64", "aarch64", "arm64"):
        raise OSError(f"Unsupported Machine Type: {machine}")
elif system == "windows":
    if machine not in ("x86_64", "amd64"):
        raise OSError(f"Unsupported Machine Type: {machine}")
# WASM (Emscripten) and Darwin (macOS) usually don't need strict machine checks here
