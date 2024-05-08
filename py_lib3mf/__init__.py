__version__ = '2.3.1'

import platform
from . import Lib3MF

system = platform.system().lower()

if system not in ("linux", "darwin", "windows"):
    raise OSError(f"Unsupported Operating System: {system}")

machine = platform.machine().lower()

if system == "linux" and machine != "x86_64":
    raise OSError(f"Unsupported Machine Type: {machine}")
elif system == "windows" and machine not in ("x86_64", "amd64")
    raise OSError(f"Unsupported Machine Type: {machine}")

# skipping darwin machine check for now
