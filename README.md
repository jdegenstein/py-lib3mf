# py-lib3mf
Minimal files required to use lib3mf in python. Provides a pip-installable package for the python API that wraps Lib3MF API available here: [https://github.com/3MFConsortium/lib3mf](https://github.com/3MFConsortium/lib3mf). The repository that is used to prepare the PyPI release is here [https://github.com/jdegenstein/py-lib3mf](https://github.com/jdegenstein/py-lib3mf)

# Installation
The recommended method for most users is to install **py-lib3mf** with one of the following two commands.

In Linux/MacOS, use the following command:
```
python3 -m pip install py-lib3mf
```
In Windows, use the following command:
```
python -m pip install py-lib3mf
```
If you receive errors about conflicting dependencies, you can retry the installation after having upgraded pip to the latest version with the following command:
```
python3 -m pip install --upgrade pip
```

## Acknowledgements
* The WASM build infrastructure and CMake patching logic are adapted from [Yeicor/OCP.wasm](https://github.com/Yeicor/OCP.wasm).
