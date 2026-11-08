include_guard(GLOBAL)

set(version @VERSION@)

set(progname clang)
set(archive LLVM-${version}-win64.msi)
set(url "https://github.com/llvm/llvm-project/releases/download/llvmorg-${version}/${archive}")
set(hash 1e3242a2f5750613bea990da7904ac1d37587cdbb09f50b142332695596e6c3f274b59040b39c379734f993a6542206e09f05bf21149fb17c0e0fb26de59a5c8)
set(output_path "${DOWNLOADS}/tools/clang/clang-${version}")

find_program(CLANG clang PATHS "${output_path}/bin")
find_program(CLANG_CL clang-cl PATHS "${output_path}/bin")
if(NOT CLANG OR NOT CLANG_CL)
	message(STATUS "Installing ${archive}")
	
	file(MAKE_DIRECTORY "${output_path}")

	vcpkg_download_distfile(archive_path
		URLS "${url}"
		SHA512 ${hash}
		FILENAME "${archive}"
	)

	if ("${archive}" MATCHES ".exe$")
		vcpkg_find_acquire_program(7Z)
		vcpkg_execute_in_download_mode(
			COMMAND "${7Z}" x "${archive_path}" "-o${output_path}" "-y" "-bso0" "-bsp0"
			WORKING_DIRECTORY "${output_path}"
			OUTPUT_FILE "${CURRENT_BUILDTREES_DIR}/7z-LLVM-${TARGET_TRIPLET}-out.log"
			ERROR_FILE "${CURRENT_BUILDTREES_DIR}/7z-LLVM-${TARGET_TRIPLET}-err.log"
			RESULT_VARIABLE error_code
		)
		if(error_code)
			message(FATAL_ERROR "Couldn't extract '${archive}' with 7z: error ${error_code}.")
		endif()
	elseif ("${archive}" MATCHES ".msi$")
		file(TO_NATIVE_PATH "${archive_path}" lessmsi_archive_path)
		vcpkg_execute_in_download_mode(
			COMMAND "@LESSMSI@" x "${lessmsi_archive_path}" # Using output_path here does not work in bash
			WORKING_DIRECTORY "${output_path}" 
			OUTPUT_FILE "${CURRENT_BUILDTREES_DIR}/lessmsi-LLVM-${TARGET_TRIPLET}-out.log"
			ERROR_FILE "${CURRENT_BUILDTREES_DIR}/lessmsi-LLVM-${TARGET_TRIPLET}-err.log"
			RESULT_VARIABLE error_code
		)
		if(error_code)
			message(FATAL_ERROR "Couldn't extract '${archive}' with lessmsi: error ${error_code}.")
		endif()

		get_filename_component(archive_name "${archive}" NAME_WLE)
		set(subdir_to_move "${archive_name}/SourceDir/LLVM")
		file(GLOB all_contents RELATIVE "${output_path}/${subdir_to_move}" "${output_path}/${subdir_to_move}/*")
		foreach(item ${all_contents})
			file(RENAME "${output_path}/${subdir_to_move}/${item}" "${output_path}/${item}")
		endforeach()
		file(REMOVE_RECURSE "${output_path}/${archive_name}")
	else()
		message(FATAL_ERROR "Unexpected archive format '${archive}': only exe and msi files are supported.")
	endif()

	set(CLANG "${output_path}/bin/clang@VCPKG_EXECUTABLE_SUFFIX@")
	set(CLANG_CL "${output_path}/bin/clang-cl@VCPKG_EXECUTABLE_SUFFIX@")
else()
	message(STATUS "Found clang version '${version}' at '${CLANG}'")
	message(STATUS "Found clang-cl version '${version}' at '${CLANG_CL}'")
endif()
