# Export Z_VCPKG_CUDA_CI_CUSTOM_DIR for 'cuda' port
# These variables are needed to suppress the next vcpkg warning if using
#    set(Z_VCPKG_CUDA_CI_CUSTOM_DIR "@CUDA_CI_CUSTOM_DIR@")
#    warning: There should be no absolute paths, such as the following, in an installed package.
#    To suppress this message, add set(VCPKG_POLICY_SKIP_ABSOLUTE_PATHS_CHECK enabled)
set(Z_VCPKG_CUDA_CI_CUSTOM_DIR_ESCAPED "\@CUDA_CI_CUSTOM_DIR_ESCAPED@")
string(REPLACE "\${DOWNLOADS}" "${DOWNLOADS}" Z_VCPKG_CUDA_CI_CUSTOM_DIR "${Z_VCPKG_CUDA_CI_CUSTOM_DIR_ESCAPED}")
