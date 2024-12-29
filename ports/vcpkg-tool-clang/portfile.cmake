
configure_file(
	"${CMAKE_CURRENT_LIST_DIR}/vcpkg-port-config.cmake" 
	"${CURRENT_PACKAGES_DIR}/share/${PORT}/vcpkg-port-config.cmake" 
	@ONLY)

vcpkg_install_copyright(FILE_LIST "${VCPKG_ROOT_DIR}/LICENSE.txt")
set(VCPKG_POLICY_CMAKE_HELPER_PORT enabled)
