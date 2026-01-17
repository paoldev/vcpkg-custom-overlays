
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO OpenNMT/Tokenizer
    REF v${VERSION}
    SHA512 abae15a571721cb64f32b1abb178c65d793b38eebc69fbc0e31f36a42efd89ecaafc0ce262627a64fdfe6a3f59c779a0c084dc4df786878a8c699c3a030bafad
    HEAD_REF master
    PATCHES
        fix-sentencepiece-dependency.patch
)

# Needed to find sentencepiece dependencies.
vcpkg_find_acquire_program(PKGCONFIG)
set(ENV{PKG_CONFIG} "${PKGCONFIG}")

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" BUILD_SHARED_LIBS)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DLIB_ONLY=ON
        -DBUILD_TESTS=OFF
        -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}
)

vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.md")
