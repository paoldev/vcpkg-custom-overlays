
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO google/ruy
    REF 6f524b038f29504a2d2a7fff2d79d40194aca493
    SHA512 570f7a8f4adf9b5d276c177e6369e8b12986175ccaa1fb3aee5fd5d061e5150bfd09a431c60b95fd5456ee133d7b6e4b3ba94baf16d99231553a08a376785266
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
