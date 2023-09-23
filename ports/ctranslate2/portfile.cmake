
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO OpenNMT/CTranslate2
    REF v${VERSION}
    SHA512 31358cdd1db1e61bba7f609c5169f177a0caea9522f2968d37ad9e7f019b97514af318dc23977bfb1dac28b7285e266856459d329da82e0cbcbc2d59366c07b9
    HEAD_REF master
	PATCHES
		fix-dependencies.patch
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

if (WITH_MKL AND WITH_OPENBLAS)
	message(FATAL_ERROR "Cannot build feature 'openblas' together with feature 'mkl'.")
endif()

set(OPENMP_RUNTIME "NONE")  #todo: create feature?
if (WITH_MKL AND (VCPKG_CRT_LINKAGE STREQUAL "dynamic"))	# see intel-mkl/portfile.cmake and ctranslate2/CMakeLists.txt
	set(OPENMP_RUNTIME "INTEL")
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
