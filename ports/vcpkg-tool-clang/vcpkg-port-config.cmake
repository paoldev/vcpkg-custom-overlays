include_guard(GLOBAL)

set(version @VERSION@)

set(progname clang)
set(archive "LLVM-${version}-win64.exe")
set(url "https://github.com/llvm/llvm-project/releases/download/llvmorg-${version}/LLVM-${version}-win64.exe")
set(hash 0789a5bd609ce8db6a48ef51d90f0931bae6778398071d64ac96401598e971978a7c24b7cc720062de559f2ca75e961e4f94912bb08b738244d29680b06f104c)
set(output_path "${DOWNLOADS}/tools/clang/clang-${version}")

find_program(CLANG clang PATHS "${output_path}/bin")
find_program(CLANG_CL clang-cl PATHS "${output_path}/bin")
if(NOT CLANG OR NOT CLANG_CL)
	message(STATUS "Installing ${archive}")
	
	file(MAKE_DIRECTORY "${output_path}")

	vcpkg_find_acquire_program(7Z)

	vcpkg_download_distfile(archive_path
		URLS "${url}"
		SHA512 ${hash}
		FILENAME "${archive}"
	)

	vcpkg_execute_in_download_mode(
		COMMAND "${7Z}" x "${archive_path}" "-o${output_path}" "-y" "-bso0" "-bsp0"
		WORKING_DIRECTORY "${output_path}"
	)
	
	set(CLANG "${output_path}/bin/clang@VCPKG_EXECUTABLE_SUFFIX@")
	set(CLANG_CL "${output_path}/bin/clang-cl@VCPKG_EXECUTABLE_SUFFIX@")
else()
	message(STATUS "Found clang version '${version}' at '${CLANG}'")
	message(STATUS "Found clang-cl version '${version}' at '${CLANG_CL}'")
endif()
