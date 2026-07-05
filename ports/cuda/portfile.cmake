# This package doesn't install CUDA. It instead verifies that CUDA is installed.
# Other packages can depend on this package to declare a dependency on CUDA.
# If this package is installed, we assume that CUDA is properly installed.

#note: this port must be kept in sync with CUDNN and NCCL ports: every time one is upgraded, the other must be too

include("${CMAKE_CURRENT_LIST_DIR}/vcpkg_find_cuda.cmake")

vcpkg_find_cuda(OUT_CUDA_TOOLKIT_ROOT CUDA_TOOLKIT_ROOT)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/vcpkg-port-config.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
configure_file("${CMAKE_CURRENT_LIST_DIR}/vcpkg_find_cuda.cmake" "${CURRENT_PACKAGES_DIR}/share/${PORT}/vcpkg_find_cuda.cmake" @ONLY)  #my-change
file(INSTALL "${VCPKG_ROOT_DIR}/LICENSE.txt" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)

set(VCPKG_POLICY_CMAKE_HELPER_PORT enabled)
