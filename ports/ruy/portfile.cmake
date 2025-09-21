
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO google/ruy
    REF 9940fbf1e0c0863907e77e0600b99bb3e2bc2b9f
    SHA512 a3628713b0346610c4bee10a847afe1956783e16102598a1c012b2c09fc418fbc272f1081cff7fd180822f19c646d668deb826ef327134b2c3bbf32522d9fb36
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
