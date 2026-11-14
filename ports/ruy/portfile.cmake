
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO google/ruy
    REF 0face1b4633b877082d26e3d4a75db394ef5fed3
    SHA512 3bb54175f775f67d74a97d6a5e5d6a2e6f9c7d5066070e4b3108fb6f5cd79fdc12135d85245959235aa7432b0191558127de8fb2a1cd02a81da582df1b161d87
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
