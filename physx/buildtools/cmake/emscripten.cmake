# Copyright (c) Contributors to the Open 3D Engine Project.
# SPDX-License-Identifier: Apache-2.0 OR MIT

set(_physx_emscripten_toolchain "$ENV{EMSDK}/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake")
if(NOT EXISTS "${_physx_emscripten_toolchain}")
    message(FATAL_ERROR "Activate the Emscripten SDK or set CMAKE_TOOLCHAIN_FILE explicitly")
endif()

if(PHYSX_EMSCRIPTEN_ARCH)
    # Emscripten reads CMAKE_C_FLAGS to determine the pointer size when its toolchain loads.
    list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES PHYSX_EMSCRIPTEN_ARCH)
    foreach(_physx_language C CXX)
        set(_physx_flags "${CMAKE_${_physx_language}_FLAGS}")
        if(NOT DEFINED CMAKE_${_physx_language}_FLAGS)
            set(_physx_flags "$ENV{${_physx_language}FLAGS}")
        endif()
        if(NOT _physx_flags MATCHES "(^| )--target=${PHYSX_EMSCRIPTEN_ARCH}$")
            string(STRIP "${_physx_flags} --target=${PHYSX_EMSCRIPTEN_ARCH}" _physx_flags)
        endif()
        set(CMAKE_${_physx_language}_FLAGS "${_physx_flags}")
    endforeach()
endif()

include("${_physx_emscripten_toolchain}")
