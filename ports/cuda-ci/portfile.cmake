#
# Install cuda in "${DOWNLOADS}/tools/cuda/${CUDA_VERSION}/${CUDA_OS}-${CUDA_ARCH}" folder
# when system installation is not available, for backward compatible behaviour.
# TODO?: always install cuda in custom folder even if the system installation is available.
#
# cuda manifest is downloaded from https://developer.download.nvidia.com/compute/cuda/redist/redistrib_${CUDA_VERSION}.json
# cudnn manifest is downloaded from https://developer.download.nvidia.com/compute/cudnn/redist/redistrib_${CUDNN_VERSION}.json
#
# Note: to repair download cache, use 'vcpkg install --triplet x64-windows --overlay-ports path\to\ports --binarysource=clear cuda-ci'
#
# TODO: convert to vcpkg-tool-cuda-ci?
#

set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)

# cuda and cudnn versions
# If ${VERSION} is invalid, exceptions should be automatically thrown by list(GET ...)
string(REPLACE "-" ";" VERSION_LIST "${VERSION}")
list(GET VERSION_LIST 0 CUDA_VERSION)
list(GET VERSION_LIST 1 CUDNN_VERSION)

# Compute CUDNN_VARIANT from CUDA_VERSION
string(REPLACE "." ";" CUDA_VERSION_LIST "${CUDA_VERSION}")
list(GET CUDA_VERSION_LIST 0 CUDA_VERSION_MAJOR)
set(CUDNN_VARIANT "cuda${CUDA_VERSION_MAJOR}")

# Configurable options: begin

# Installer path: https://github.com/NVIDIA/build-system-archive-import-examples
# Commit Aug 5, 2025
set(PY_CUDA_INSTALLER_REF 20983d06bcaf0ba85933f8c6e46782cd85f64cf6)
set(PY_CUDA_INSTALLER_HASH a689c71ffbe6b2c798eff60275c34bd47c5905ee461ec42e57cb5c91dc3e5f5331d5b22288825240dd158469c55fc53039582e27f80cf7df937465883bb30596)

# https://developer.download.nvidia.com/compute/cuda/redist/redistrib_${CUDA_VERSION}.json
# cuda 13.2.0
set(CUDA_MANIFEST_HASH 5cc2ff05feccc1a4e47bf5f2ceeafe6bdf2662c6ce2f42375c7a253fde4a492a623cb3b5152e513e84f593d4ffbdb44bd70676fa99c64e4affc8ec91e97e40a6)

# https://developer.download.nvidia.com/compute/cudnn/redist/redistrib_${CUDNN_VERSION}.json
# cudnn 9.20.0
set(CUDNN_MANIFEST_HASH c86f1fff56e1e18f2698b85cd94dd16366058213c9830161e782ef2d90ea309efcaf3da9a9e04e7d4c2e30f92f10a0f5534ce4d05b88d57b16ccc5d418f6c331)

# Components' hashes are automatically validated by the py installer through the downloaded manifests.
set(CUDA_COMPONENTS --component "cuda_cccl,cuda_compat,cuda_crt,ctadvisor,cuda_cudart,cuda_culibos,cuobjdump,cuda_cupti,cuda_cuxxfilt,cuda_nvcc,cuda_nvdisasm,cuda_nvml_dev,cuda_nvprune,cuda_nvrtc,cuda_nvtx,cuda_opencl,cuda_profiler_api,cuda_sandbox_dev,cuda_sanitizer_api,cuda_tileiras,libcublas,libcudla,libcufft,libcufile,libcuobjclient,libcurand,libcusolver,libcusparse,libnpp,libnvfatbin,libnvjitlink,libnvjpeg,libnvptxcompiler,libnvvm,nvidia_fs")
set(CUDNN_COMPONENTS --component "cudnn,cudnn_jit")

# Configurable options: end

# See https://github/NVIDIA/build-system-archive-import-examples/parse_redist.py
set(CUDA_MANIFEST_URL "https://developer.download.nvidia.com/compute/cuda/redist/redistrib_${CUDA_VERSION}.json")
set(CUDNN_MANIFEST_URL "https://developer.download.nvidia.com/compute/cudnn/redist/redistrib_${CUDNN_VERSION}.json")

# Warning: 'full' option may fail due to paths longer than 260 chars.
if("full" IN_LIST FEATURES)
    set(CUDA_COMPONENTS)
    set(CUDNN_COMPONENTS)
endif()

if(VCPKG_TARGET_IS_WINDOWS AND (VCPKG_TARGET_ARCHITECTURE STREQUAL "x64"))
    set(CUDA_OS windows)
    set(CUDA_ARCH x86_64)
elseif(VCPKG_TARGET_IS_LINUX)
    set(CUDA_OS linux)
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        set(CUDA_ARCH x86_64)
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
        set(CUDA_ARCH sbsa)
    endif()
endif()

# Keep this path in sync with the one declared in 'ports/cuda/vcpkg_find_cuda.cmake'
set(CUDA_CI_CUSTOM_DIR "${DOWNLOADS}/tools/cuda/${CUDA_VERSION}/${CUDA_OS}-${CUDA_ARCH}")

# Check for system installation
set(CUDA_PATHS
        ENV CUDA_PATH
        ENV CUDA_HOME
        ENV CUDA_BIN_PATH
        ENV CUDA_TOOLKIT_ROOT_DIR)

find_program(NVCC nvcc${VCPKG_HOST_EXECUTABLE_SUFFIX}
    PATHS ${CUDA_PATHS}
    PATH_SUFFIXES bin bin64
    NO_DEFAULT_PATH)

# Already installed in default paths: just copy basic
# vcpkg license (see 'ports/cuda/portfile.cmake') and exit.
if(NVCC)
    vcpkg_install_copyright(FILE_LIST "${VCPKG_ROOT_DIR}/LICENSE.txt")
    return()
endif()

# Check if custom installation is already present, so it can be shared 
# between different triplets (such as x64-windows and x64-windows-static).
find_program(NVCC nvcc${VCPKG_HOST_EXECUTABLE_SUFFIX}
    PATHS "${CUDA_CI_CUSTOM_DIR}"
    PATH_SUFFIXES bin bin64
    NO_DEFAULT_PATH)

# If 'nvcc' exists, also check if cudnn version matches the requested
# one, otherwise reinstall the package.
set(REINSTALL OFF)
if(NVCC)
    # See 'ports/cudnn/FindCUDNN.cmake'
    # Note: this path may be dependent on cuda/cudnn version.
    set(_CUDNN_VERSION "?")
    if(EXISTS "${CUDA_CI_CUSTOM_DIR}/include/cudnn_version.h")
        file(READ "${CUDA_CI_CUSTOM_DIR}/include/cudnn_version.h" CUDNN_HEADER_CONTENTS)
        if(CUDNN_HEADER_CONTENTS)
            string(REGEX MATCH "define CUDNN_MAJOR * +([0-9]+)"
                   _CUDNN_VERSION_MAJOR "${CUDNN_HEADER_CONTENTS}")
            string(REGEX REPLACE "define CUDNN_MAJOR * +([0-9]+)" "\\1"
                   _CUDNN_VERSION_MAJOR "${_CUDNN_VERSION_MAJOR}")
            string(REGEX MATCH "define CUDNN_MINOR * +([0-9]+)"
                   _CUDNN_VERSION_MINOR "${CUDNN_HEADER_CONTENTS}")
            string(REGEX REPLACE "define CUDNN_MINOR * +([0-9]+)" "\\1"
                   _CUDNN_VERSION_MINOR "${_CUDNN_VERSION_MINOR}")
            string(REGEX MATCH "define CUDNN_PATCHLEVEL * +([0-9]+)"
                   _CUDNN_VERSION_PATCH "${CUDNN_HEADER_CONTENTS}")
            string(REGEX REPLACE "define CUDNN_PATCHLEVEL * +([0-9]+)" "\\1"
                   _CUDNN_VERSION_PATCH "${_CUDNN_VERSION_PATCH}")
            if(_CUDNN_VERSION_MAJOR)
                set(_CUDNN_VERSION "${_CUDNN_VERSION_MAJOR}.${_CUDNN_VERSION_MINOR}.${_CUDNN_VERSION_PATCH}")
            endif()
        endif()
    endif()
    if (NOT ${_CUDNN_VERSION} VERSION_EQUAL CUDNN_VERSION)
        message(STATUS "Found cudnn '${_CUDNN_VERSION}' instead of '${CUDNN_VERSION}'. Reinstalling the package.")
        set(REINSTALL ON)
    endif()
endif()

# Download only if not installed yet.
if((NOT NVCC) OR REINSTALL)
    message(STATUS "Installing cuda")

    # Clean-up any previous 'corrupted' installation
    file(REMOVE_RECURSE "${CUDA_CI_CUSTOM_DIR}")

    cmake_path(GET CUDA_CI_CUSTOM_DIR PARENT_PATH CUDA_INSTALL_ROOT)
    set(CUDA_DOWNLOAD_CACHE_DIR "${DOWNLOADS}/cuda-cache")

    vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO NVIDIA/build-system-archive-import-examples
        REF ${PY_CUDA_INSTALLER_REF}
        SHA512 ${PY_CUDA_INSTALLER_HASH}
        HEAD_REF main
        PATCHES
            download-multiple-components.patch
    )

    vcpkg_find_acquire_program(PYTHON3)

    file(MAKE_DIRECTORY "${CUDA_DOWNLOAD_CACHE_DIR}")

    set(CUDA_LOCAL_MANIFEST "cuda_${CUDA_VERSION}_manifest.json")
    set(CUDNN_LOCAL_MANIFEST "cudnn_${CUDNN_VERSION}_manifest.json")

    vcpkg_download_distfile(CUDA_MANIFEST
        URLS ${CUDA_MANIFEST_URL}
        FILENAME ${CUDA_LOCAL_MANIFEST}
        SHA512 ${CUDA_MANIFEST_HASH})

    vcpkg_download_distfile(CUDNN_MANIFEST
        URLS ${CUDNN_MANIFEST_URL}
        FILENAME ${CUDNN_LOCAL_MANIFEST}
        SHA512 ${CUDNN_MANIFEST_HASH})

    set(CUDA_URL_OR_LABEL --url "${CUDA_MANIFEST}")
    set(CUDNN_URL_OR_LABEL --url "${CUDNN_MANIFEST}")

    # To force manifest download via 'parse_redist.py', use '--label {version}' option.
    #set(CUDA_URL_OR_LABEL --label ${CUDA_VERSION})
    #set(CUDNN_URL_OR_LABEL --label ${CUDNN_VERSION})

    # cuda - begin
    vcpkg_execute_in_download_mode(
        COMMAND "${PYTHON3}" "${SOURCE_PATH}/parse_redist.py" --product cuda ${CUDA_URL_OR_LABEL} --os ${CUDA_OS} --arch ${CUDA_ARCH} --output ${CUDA_INSTALL_ROOT} ${CUDA_COMPONENTS}
        WORKING_DIRECTORY "${CUDA_DOWNLOAD_CACHE_DIR}"
        RESULT_VARIABLE error_code
    )
    if(NOT error_code STREQUAL "0")
        message(FATAL_ERROR "Failed to fetch cuda ${CUDA_VERSION} for ${CUDA_OS}-${CUDA_ARCH}.")
    endif()
    file(RENAME "${CUDA_CI_CUSTOM_DIR}/LICENSE" "${CUDA_CI_CUSTOM_DIR}/LICENSE-CUDA")
    # cuda - end

    # cudnn - begin
    vcpkg_execute_in_download_mode(
        COMMAND "${PYTHON3}" "${SOURCE_PATH}/parse_redist.py" --product cudnn ${CUDNN_URL_OR_LABEL} --os ${CUDA_OS} --arch ${CUDA_ARCH} --variant ${CUDNN_VARIANT} --output ${CUDA_INSTALL_ROOT} ${CUDNN_COMPONENTS}
        WORKING_DIRECTORY "${CUDA_DOWNLOAD_CACHE_DIR}"
        RESULT_VARIABLE error_code
    )
    if(NOT error_code STREQUAL "0")
        message(FATAL_ERROR "Failed to fetch cudnn ${CUDNN_VERSION} for ${CUDA_OS}-${CUDA_ARCH}.")
    endif()

    # Move "${CUDA_CI_CUSTOM_DIR}/${CUDNN_VARIANT}" folder content into ${CUDA_CI_CUSTOM_DIR}, to be compatible with FindCUDNN.cmake file. 
    if(NOT "${CUDNN_VARIANT}" STREQUAL "")
        file(RENAME "${CUDA_CI_CUSTOM_DIR}/${CUDNN_VARIANT}/LICENSE" "${CUDA_CI_CUSTOM_DIR}/${CUDNN_VARIANT}/LICENSE-CUDNN")
        file(COPY "${CUDA_CI_CUSTOM_DIR}/${CUDNN_VARIANT}/" DESTINATION "${CUDA_CI_CUSTOM_DIR}/")
        file(REMOVE_RECURSE "${CUDA_CI_CUSTOM_DIR}/${CUDNN_VARIANT}")
    else()
        file(RENAME "${CUDA_CI_CUSTOM_DIR}/LICENSE" "${CUDA_CI_CUSTOM_DIR}/LICENSE-CUDNN")
    endif()
    # cudnn - end
endif()

vcpkg_install_copyright(FILE_LIST
    "${CUDA_CI_CUSTOM_DIR}/LICENSE-CUDA"
    "${CUDA_CI_CUSTOM_DIR}/LICENSE-CUDNN")
