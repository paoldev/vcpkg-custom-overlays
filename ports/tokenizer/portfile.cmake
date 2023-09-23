
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO OpenNMT/Tokenizer
    REF v${VERSION}
    SHA512 ddda4853449aa2394c3da5abacbdb2121b5a728eaadf8dee2bd88618b3583cedb97b63a79b5d8e0e4904e1fe2ed0db6dc128d72c000f09885bb563b899880265
    HEAD_REF master
	PATCHES
		fix-sentencepiece-dependency.patch
)

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" BUILD_SHARED_LIBS)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
		-DLIB_ONLY=ON
        -DBUILD_TESTS=OFF
		-DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}
)

vcpkg_cmake_install()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

configure_file("${SOURCE_PATH}/LICENSE.md" "${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright" COPYONLY)

vcpkg_copy_pdbs()

vcpkg_fixup_pkgconfig()
