# vcpkg-custom-overlays

[![License: MIT](https://img.shields.io/badge/License-MIT-red.svg)](LICENSE)

This repository contains some custom ports I used / use for few projects of mine.

## How to install and use

### As overlay folder

> 1. git clone https://github.com/paoldev/vcpkg-custom-overlays
> 2. cd vcpkg
> 3. vcpkg install --overlay-ports path/to/vcpkg-custom-overlays/ports --overlay-triplets path/to/vcpkg-custom-overlays/triplets --triplet [triplet to use] [packages to install]

### As vcpkg git registry

vcpkg-configuration.json:

> {  
> &nbsp;&nbsp;"registries": [  
> &nbsp;&nbsp;&nbsp;&nbsp;{  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"kind": "git",  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"baseline": "<commit_sha>",  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"repository": "https://github.com/paoldev/vcpkg-custom-overlays.git",  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"packages": [  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"000000-my-tools",  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"cairo",  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"cpprestsdk",  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"ctranslate2",  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"icu",  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"intel-mkl",  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"libpsl",  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"lua",  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"ms-icu",  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"ruy",  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"sentencepiece",  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"tokenizer",  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"vcpkg-tool-clang"  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;]  
> &nbsp;&nbsp;&nbsp;&nbsp;}  
> &nbsp;&nbsp;]  
> }

## Ports

### 000000-my-tools

Port to download some tools.

### cairo

Custom cairo port

New platform:
- **uwp**: it can be built on uwp, without exposing win32 cairo surface and font.  
Usage example:  
    > vcpkg install --overlay-ports path/to/vcpkg-custom-overlays/ports --triplet x64-uwp cairo\[freetype\]

**Note**: the custom **cairo\[angle\]** feature is no more available since the cairo 'gl-backend' has been removed upstream, starting from 'cairo 1.17.8' release.

### cpprestsdk

Custom cpprestsdk port

New feature:
- **windows-asio**: add 'asio' support to windows platform.  
It also contains the patch related to my PR <https://github.com/microsoft/cpprestsdk/pull/1466>, not integrated in main 'cpprestsdk' repository yet.

### ctranslate2

New port for the "CTranslate2" library from https://github.com/OpenNMT/CTranslate2:  

> CTranslate2 is a C++ and Python library for efficient inference with Transformer models.

This library is released under the "MIT" license: https://github.com/OpenNMT/CTranslate2/blob/master/LICENSE.  

For details, see the links above.

### icu

Custom icu port with Windows SDK ICU support, for both windows-desktop and uwp platforms. It is a modification of the original vcpkg port found at <https://github.com/microsoft/vcpkg/tree/master/ports/icu>.

- Fix for 'File name too long' error during install-icu phase, while executing 'ln -s' command.
- Additional feature: **ms-icu** (see below for details)

### intel-mkl

Custom intel-mkl port.  

New feature:  
- updated dynamic crt dependency, when used by static libraries compiled with MultiThreaded\<Debug\>DLL crt flags (/MD(d)).  
  See <https://www.intel.com/content/www/us/en/docs/onemkl/developer-guide-windows/2023-0/linking-with-compiler-run-time-libraries.html>:
  > /MT for linking with static Intel� oneAPI Math Kernel Library libraries  
  /MD for linking with dynamic Intel� oneAPI Math Kernel Library libraries  

  I got unexpected runtime results when using "x64-windows-static-md" triplet that mixed "/MD static libraries" with official "/MT static intel-mkl" port.

### libpsl

Custom libpsl port.  

New features:
- uwp support
- optional support for "ms-icu" dependency

### lua

Custom lua port.  

New feature:  
- export LUA_VERSION_STRING to meson build system.

### ms-icu

Port to expose Windows SDK ICU to other vcpkg ports.  
See <https://learn.microsoft.com/en-us/windows/win32/intl/international-components-for-unicode--icu-> for details about differences with "standard" icu library (<https://github.com/unicode-org/icu>).

Features:
- **default (without arguments)**: it looks for "icu.h" and "icu.lib" files in current Windows SDK; if such files are not available, it looks for legacy "icucommon.h", "icui18n.h", "icuuc.lib" and "icuin.lib": if these files are missing too, an error is triggered.
- **forcelegacy**: it only looks for legacy headers and libs files.
- **dummyheaders**: it generates dummy files in "include/unicode" folder as if the "standard" icu library were built.  
It's useful to try to compile "standard" icu dependent packages without applying any modification.  
However, U_ICU_VERSION macro and c++ code are not exposed by "ms-icu" (as described at the link above), so compile-time errors may still happen.  
To use this port as a replacement of the "standard" icu port, the custom icu port above has to be used, by declaring its "ms-icu" feature.  
Usage example:  
    > vcpkg install --overlay-ports path/to/vcpkg-custom-overlays/ports --triplet x64-windows my_icu_dependent_package icu\[ms-icu\]

To use **icu\[ms-icu\]** outside of the vcpkg toolchain, probably a customized **FindICU.cmake** file has to be added to the project; for example  
```
#
# my FindICU.cmake
#
find_package(PkgConfig QUIET)
pkg_check_modules(PC_ICU REQUIRED QUIET icu-uc)

#Ignore ICU_VERSION
#set(ICU_VERSION ${PC_ICU_VERSION})

set(ICU_INCLUDE_DIRS ${PC_ICU_INCLUDE_DIRS})
set(ICU_LIBRARIES ${PC_ICU_LINK_LIBRARIES})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ICU
    FOUND_VAR ICU_FOUND
    REQUIRED_VARS ICU_LIBRARIES ICU_INCLUDE_DIRS
    VERSION_VAR ICU_VERSION
)

foreach(_ICU_component ${ICU_FIND_COMPONENTS})
  string(TOUPPER "${_ICU_component}" _ICU_component_upcase)
  set(_ICU_component_cache "ICU_${_ICU_component_upcase}_LIBRARY")
  set(_ICU_imported_target "ICU::${_ICU_component}")
  if(NOT TARGET ${_ICU_imported_target})
    add_library(${_ICU_imported_target} UNKNOWN IMPORTED)
    set_target_properties(${_ICU_imported_target} PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${PC_ICU_INCLUDE_DIRS}")
    foreach (lib ${PC_ICU_LINK_LIBRARIES})
      #${PC_ICU_LINK_LIBRARIES} contains 2 libs at most (icuin and icuuc), in legacy mode.
      if ("${_ICU_component}" MATCHES "in" AND "${lib}" MATCHES "icuin.Lib$")
        set_target_properties(${_ICU_imported_target} PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "CXX" IMPORTED_LOCATION "${lib}")
        set(${${_ICU_component_cache}} ${lib})
      else()
        set_target_properties(${_ICU_imported_target} PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "CXX" IMPORTED_LOCATION "${lib}")
        set(${${_ICU_component_cache}} ${lib})
      endif()
    endforeach()
  endif()
endforeach()

mark_as_advanced(ICU_INCLUDE_DIRS ICU_LIBRARIES)
```
### ruy

New port for "The ruy matrix multiplication library" from https://github.com/google/ruy.  

This library is released under the "Apache-2.0" license: https://github.com/google/ruy/blob/master/LICENSE.  

For details, see the links above.

### sentencepiece

Custom sentencepiece port.  

New feature:  
- add pkgconfig support to the Windows library.

### tokenizer

New port for the "Tokenizer" library from https://github.com/OpenNMT/Tokenizer:  

> Tokenizer is a fast, generic, and customizable text tokenization library for C++ and Python with minimal dependencies.

This library is released under the "MIT" license: https://github.com/OpenNMT/Tokenizer/blob/master/LICENSE.md.  

For details, see the links above.

### vcpkg-tool-clang

New custom "clang" port to directly download and use recent 'clang-cl.exe' versions, to avoid patching 'vcpkg_find_acquire_program(CLANG).cmake' which is still on clang version '15.0.6'.  
NB: only x64 windows version is downloaded.

## Triplets

- x64-uwp-static-md-release

# License

This project is licensed under the terms of the [MIT license](./LICENSE). The libraries
provided by ports are licensed under the terms of their original authors.
