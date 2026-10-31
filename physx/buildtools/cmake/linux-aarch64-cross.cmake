# SPDX-License-Identifier: Apache-2.0 OR MIT
# Ubuntu packages: clang, g++-aarch64-linux-gnu, binutils-aarch64-linux-gnu.
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
find_program(CMAKE_C_COMPILER NAMES clang REQUIRED)
find_program(CMAKE_CXX_COMPILER NAMES clang++ REQUIRED)
set(CMAKE_C_COMPILER_TARGET aarch64-linux-gnu)
set(CMAKE_CXX_COMPILER_TARGET aarch64-linux-gnu)

# Query GNU's target libraries instead of assuming an installation prefix.
find_program(PHYSX_GNU_CROSS_COMPILER NAMES aarch64-linux-gnu-gcc REQUIRED)
execute_process(COMMAND "${PHYSX_GNU_CROSS_COMPILER}" -print-file-name=libc.a
    OUTPUT_VARIABLE PHYSX_TARGET_LIBC OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY)
if(NOT IS_ABSOLUTE "${PHYSX_TARGET_LIBC}" OR NOT EXISTS "${PHYSX_TARGET_LIBC}")
    message(FATAL_ERROR "The GNU ARM64 cross compiler could not locate its target libc")
endif()
get_filename_component(PHYSX_TARGET_LIBC "${PHYSX_TARGET_LIBC}" REALPATH)
get_filename_component(PHYSX_TARGET_LIB_DIR "${PHYSX_TARGET_LIBC}" DIRECTORY)
get_filename_component(PHYSX_TARGET_ROOT "${PHYSX_TARGET_LIB_DIR}" DIRECTORY)
if(NOT EXISTS "${PHYSX_TARGET_ROOT}/include/stdlib.h")
    message(FATAL_ERROR "Missing GNU ARM64 target headers under ${PHYSX_TARGET_ROOT}")
endif()
get_filename_component(PHYSX_GNU_BIN_DIR "${PHYSX_GNU_CROSS_COMPILER}" DIRECTORY)
get_filename_component(PHYSX_GNU_ROOT "${PHYSX_GNU_BIN_DIR}" DIRECTORY)
set(CMAKE_C_COMPILER_EXTERNAL_TOOLCHAIN "${PHYSX_GNU_ROOT}")
set(CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN "${PHYSX_GNU_ROOT}")
set(CMAKE_FIND_ROOT_PATH "${PHYSX_TARGET_ROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

if(PX_GENERATE_GPU_PROJECTS OR PX_GENERATE_GPU_PROJECTS_ONLY)
    find_program(CMAKE_CUDA_COMPILER NAMES nvcc HINTS "$ENV{PM_CUDA_PATH}/bin" REQUIRED)
    find_program(CMAKE_CUDA_HOST_COMPILER NAMES aarch64-linux-gnu-g++ REQUIRED)
    get_filename_component(PHYSX_CUDA_BIN_DIR "${CMAKE_CUDA_COMPILER}" DIRECTORY)
    get_filename_component(PHYSX_CUDA_ROOT "${PHYSX_CUDA_BIN_DIR}" DIRECTORY)
    find_path(PHYSX_CUDA_TARGET_INCLUDE_DIR cuda_runtime.h
        PATHS "${PHYSX_CUDA_ROOT}/targets/sbsa-linux/include" "${PHYSX_CUDA_ROOT}/targets/aarch64-linux/include"
        NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH REQUIRED)
    get_filename_component(PHYSX_CUDA_TARGET_DIR "${PHYSX_CUDA_TARGET_INCLUDE_DIR}" DIRECTORY)
    get_filename_component(PHYSX_CUDA_TARGET_NAME "${PHYSX_CUDA_TARGET_DIR}" NAME)
    if(NOT CMAKE_CUDA_FLAGS_INIT MATCHES "--target-directory=")
        string(APPEND CMAKE_CUDA_FLAGS_INIT " --target-directory=${PHYSX_CUDA_TARGET_NAME}")
    endif()
endif()
