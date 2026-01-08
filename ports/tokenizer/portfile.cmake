
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO OpenNMT/Tokenizer
    REF v${VERSION}
    SHA512 cb3b7ab40aff37fabcba44f8a317d0ae1db541b7ed0815bcb4840f8f17e3a93b331632ce2313261992fc8a331c49c0ceb818dab59bad73b75c1ed950d056b5c9
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
