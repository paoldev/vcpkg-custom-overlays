
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO google/ruy
    REF 2af88863614a8298689cc52b1a47b3fcad7be835
    SHA512 e2cb19d7cc98c29b86a02971cb98941954eee05505ff1600e3eebbd0ec85afad01c22eed7d49d9948fde9f83413704f86b58f4a10c5dedcb0bbfaf854fa25242
    HEAD_REF master
	PATCHES
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
		-DRUY_MINIMAL_BUILD=ON
		-DRUY_FIND_CPUINFO=ON
		-DRUY_ENABLE_INSTALL=ON
		-DRUY_PROFILER=OFF
)

vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()
vcpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake/${PORT}")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share"
                    "${CURRENT_PACKAGES_DIR}/debug/include"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
