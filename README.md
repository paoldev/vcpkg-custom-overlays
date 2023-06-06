# vcpkg-custom-overlays

## How to install and use

> 1. git clone https://github.com/paoldev/vcpkg-custom-overlays
> 2. cd vcpkg
> 3. vcpkg install --overlay-ports path/to/vcpkg-custom-overlays/ports --overlay-triplets path/to/vcpkg-custom-overlays/triplets --triplet [triplet to use] [packages to install]


## Ports

### 000000-my-tools

Port to download some tools.

### icu

Custom icu port with Windows SDK ICU support, for both windows-desktop and uwp platforms. It is a modification of the original vcpkg port found at <https://github.com/microsoft/vcpkg/tree/master/ports/icu>.

Additional feature: **ms-icu** (see below for details)

### libpsl

Port to build libpsl library available at <https://github.com/rockdaboot/libpsl>.

Features:
- **default (without arguments)**: it builds libpsl with -Druntime=no option
- **icu**: it builds libpsl with -Druntime=libicu option
- **libidn2**: it builds libpsl with -Druntime=libidn2 option

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

## Triplets

- x64-windows-static-md-release
- x64-uwp-static-md-release

# License

This project is licensed under the terms of the MIT license: please see [./LICENSE](./LICENSE).
