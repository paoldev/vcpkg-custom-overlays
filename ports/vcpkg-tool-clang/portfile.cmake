
# Escaping is required to suppress "warning: There should be no absolute paths, such as the following, 
# in an installed package.To suppress this message, add set(VCPKG_POLICY_SKIP_ABSOLUTE_PATHS_CHECK enabled)"
file(RELATIVE_PATH LESSMSI_RELATIVE "${DOWNLOADS}" "${LESSMSI}")
set(LESSMSI "\${DOWNLOADS}/${LESSMSI_RELATIVE}")

configure_file(
	"${CMAKE_CURRENT_LIST_DIR}/vcpkg-port-config.cmake" 
	"${CURRENT_PACKAGES_DIR}/share/${PORT}/vcpkg-port-config.cmake" 
	@ONLY)

vcpkg_install_copyright(FILE_LIST "${VCPKG_ROOT_DIR}/LICENSE.txt")
set(VCPKG_POLICY_CMAKE_HELPER_PORT enabled)
