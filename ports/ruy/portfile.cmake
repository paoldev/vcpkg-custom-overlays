
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO google/ruy
    REF 576e020f06334118994496b45f9796ed7fda3280
    SHA512 32367b5d7bce7576520c76e62ce90eaefa4624f9b710456a85f3a3bd8d076c7abf1f06d63e0f7fcafd34e5eabd7075761a478fbb25075e759688e2f1b3f63dd5
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
