
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO OpenNMT/CTranslate2
    REF v${VERSION}
    SHA512 3d852c5d6d36d8574bf2037db6c1321c0f35f38fab5ba25ad3ff9a5a6a08b6f75fecefc74a3db2399e3e4105a0a62eaafd28029937dc2c1d09f717cf1980d66f
    HEAD_REF master
	PATCHES
		fix-dependencies.patch
		fix-utf8-warning-c4566.patch
)

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" BUILD_SHARED_LIBS)

vcpkg_check_features(
    OUT_FEATURE_OPTIONS FEATURE_OPTIONS
	FEATURES
	  cpu-dispatch ENABLE_CPU_DISPATCH
	  mkl WITH_MKL
	  dnnl WITH_DNNL
	  openblas WITH_OPENBLAS
	  ruy WITH_RUY
	  cuda WITH_CUDA
	  cuda CUDA_DYNAMIC_LOADING	# always use cuda dynamic loading
	  cudnn WITH_CUDNN
)

#features not exposed in vcpkg.json
set(WITH_ACCELERATE OFF)
set(ENABLE_PROFILING OFF)
set(BUILD_CLI OFF)
set(BUILD_TESTS OFF)
set(WITH_TENSOR_PARALLEL OFF)
set(WITH_FLASH_ATTN OFF)

if (WITH_MKL AND WITH_OPENBLAS)
	message(FATAL_ERROR "Cannot build feature 'openblas' together with feature 'mkl'.")
endif()

set(OPENMP_RUNTIME "NONE")  #todo: create feature?
if (WITH_MKL AND (VCPKG_CRT_LINKAGE STREQUAL "dynamic"))	# see intel-mkl/portfile.cmake and ctranslate2/CMakeLists.txt
	set(OPENMP_RUNTIME "INTEL")
else()
    set(OPENMP_RUNTIME "COMP") # force "openmp=comp", to avoid dead-lock when destroying thread_local thread_pool in parallel.cc if "openmp=none".
endif()

if (WITH_MKL)
	# use mkl from vcpkg installation directory
	set(ENV{INTELROOT} "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}")
endif()

if (WITH_CUDA)
	if(NOT DEFINED ENV{CUDA_PATH} AND NOT DEFINED ENV{CUDA_TOOLKIT_ROOT_DIR})
		message(WARNING "Environment variables CUDA_PATH and/or CUDA_TOOLKIT_ROOT_DIR are not defined. Disabling Cuda support.")
		set(WITH_CUDA OFF)
		set(CUDA_DYNAMIC_LOADING OFF)
		list(REMOVE_ITEM FEATURE_OPTIONS -DWITH_CUDA=ON -DCUDA_DYNAMIC_LOADING=ON)
		list(APPEND FEATURE_OPTIONS -DWITH_CUDA=OFF -DCUDA_DYNAMIC_LOADING=OFF)
		if (WITH_CUDNN)
			set(WITH_CUDNN OFF)
			list(REMOVE_ITEM FEATURE_OPTIONS -WITH_CUDNN=ON)
			list(APPEND FEATURE_OPTIONS -DWITH_CUDNN=OFF)
		endif()
	elseif(NOT DEFINED ENV{CUDA_PATH} AND DEFINED ENV{CUDA_TOOLKIT_ROOT_DIR})
		# Sometime CUDA_TOOLKIT_ROOT_DIR is not correctly detected by "${SOURCE_PATH}/CMakeLists.txt".
		# Using CUDA_PATH seems to work better than CUDA_TOOLKIT_ROOT_DIR.
	    file(TO_CMAKE_PATH $ENV{CUDA_TOOLKIT_ROOT_DIR} ENV_CUDA_TOOLKIT_ROOT_DIR)
		list(APPEND FEATURE_OPTIONS -DCUDA_TOOLKIT_ROOT_DIR=${ENV_CUDA_TOOLKIT_ROOT_DIR})
	endif()
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
		-DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}
		-DOPENMP_RUNTIME=${OPENMP_RUNTIME}
		-DBUILD_CLI=${BUILD_CLI}
		-DBUILD_TESTS=${BUILD_TESTS}
		-DWITH_TENSOR_PARALLEL=${WITH_TENSOR_PARALLEL}
		-DWITH_FLASH_ATTN=${WITH_FLASH_ATTN}
)

vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()
vcpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake/${PORT}")

if (BUILD_CLI)
    vcpkg_copy_tools(TOOL_NAMES	translator AUTO_CLEAN)
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share"
                    "${CURRENT_PACKAGES_DIR}/debug/include"
)

configure_file("${SOURCE_PATH}/LICENSE" "${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright" COPYONLY)
