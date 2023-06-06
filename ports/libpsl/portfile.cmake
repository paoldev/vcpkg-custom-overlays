
vcpkg_download_distfile(ARCHIVE
    URLS "https://github.com/rockdaboot/libpsl/releases/download/${VERSION}/libpsl-${VERSION}.tar.gz"
    FILENAME "libpsl-${VERSION}.tar.gz"
    SHA512 f1df72220bf4391d4701007100b0df66c833a2cbcb7481c9d13f0b9e0cad3b66d2d15d4b976e5bad60d2ad1540355112fa1acb07aa925c241d2d7cd20681c71d
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
	PATCHES
	  missing-U_ICU_VERSION.patch
	  fix-uwp-linker.patch
	  optionally-build-tools-and-tests.patch
)

set(RUNTIME no)
if ("icu" IN_LIST FEATURES)
  set(RUNTIME libicu)
elseif ("libidn2" IN_LIST FEATURES)
  set(RUNTIME libidn2)
  if(VCPKG_TARGET_IS_WINDOWS)
    set(VCPKG_C_FLAGS "${VCPKG_C_FLAGS} -Dstrcasecmp=_stricmp")	#compile fix with libidn2
	set(VCPKG_CXX_FLAGS "${VCPKG_CXX_FLAGS} -Dstrcasecmp=_stricmp")	#compile fix with libidn2
  endif()
endif()

vcpkg_configure_meson(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
		-Dbuiltin=true
        -Druntime=${RUNTIME}
		-Ddocs=false
		-Dtools=false
		-Dtests=false
)
vcpkg_install_meson()

file(REMOVE "${CURRENT_PACKAGES_DIR}/bin/psl-make-dafsa")
file(REMOVE "${CURRENT_PACKAGES_DIR}/debug/bin/psl-make-dafsa")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/share/man")
file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
  vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/libpsl.h" "defined PSL_STATIC" "1")
  file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin")
endif()

vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()
