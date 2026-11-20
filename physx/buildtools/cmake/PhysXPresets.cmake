# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# PhysX Preset Support for FetchContent Integration
# 
# This module provides functionality to apply PhysX build presets from XML files,
# similar to how generate_projects.py processes presets but integrated into CMake.
#
# Presets are applied in two phases so that switches (like PX_GENERATE_GPU_PROJECTS)
# take effect before project() and can control CUDA language selection, while
# parameters (like CMAKE_INSTALL_PREFIX) are applied after project() where
# CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT is available.
#
# Usage:
#   include("${CMAKE_CURRENT_LIST_DIR}/buildtools/cmake/PhysXPresets.cmake")
#   physx_apply_preset_switches(${PHYSX_PRESET})   # before project()
#   project(MyProject ...)
#   physx_apply_install_prefix()                    # after project()

# IMPORTANT: Capture CMAKE_CURRENT_LIST_DIR at file parse time, not inside functions.
# Inside functions, CMAKE_CURRENT_LIST_DIR refers to the file calling the function!
set(_PHYSX_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/../.." CACHE INTERNAL "PhysX root directory")
set(_PHYSX_PRESETS_DIR "${_PHYSX_ROOT_DIR}/buildtools/presets" CACHE INTERNAL "")

# Function to display available presets
function(physx_list_available_presets)
    message(STATUS "Available PhysX presets:")
    file(GLOB PUBLIC_PRESETS "${_PHYSX_PRESETS_DIR}/public/*.xml")
    foreach(PRESET_FILE IN LISTS PUBLIC_PRESETS)
        get_filename_component(PRESET_NAME "${PRESET_FILE}" NAME_WE)
        message(STATUS "  ${PRESET_NAME}")
    endforeach()
    message(STATUS "Select a preset with -DPHYSX_PRESET=<name>")
endfunction()

# Phase 1 - call BEFORE project().
# Reads the preset XML and applies boolean switches (PX_GENERATE_GPU_PROJECTS, etc.)
# so they are available when the project() call decides whether to enable CUDA.
function(physx_apply_preset_switches preset_name)
    _physx_resolve_preset_file("${preset_name}")

    message(STATUS "Applying preset switches from: ${_PHYSX_PRESET_FILE}")
    file(READ "${_PHYSX_PRESET_FILE}" PRESET_CONTENT)
    physx_parse_cmake_switches("${PRESET_CONTENT}")
    foreach(PARAM_NAME TARGET_BUILD_PLATFORM CMAKE_SYSTEM_NAME CMAKE_SYSTEM_PROCESSOR
            CMAKE_OSX_ARCHITECTURES CMAKE_OSX_SYSROOT CMAKE_OSX_DEPLOYMENT_TARGET
            CMAKE_TOOLCHAIN_FILE ANDROID_ABI ANDROID_PLATFORM PHYSX_EMSCRIPTEN_ARCH)
        string(REGEX MATCH "cmakeParam name=\"${PARAM_NAME}\" value=\"([^\"]+)\"" PARAM_MATCH "${PRESET_CONTENT}")
        if(PARAM_MATCH)
            set(PARAM_VALUE "${CMAKE_MATCH_1}")
            if(PARAM_NAME STREQUAL "CMAKE_TOOLCHAIN_FILE" AND NOT IS_ABSOLUTE "${PARAM_VALUE}")
                set(PARAM_VALUE "${_PHYSX_ROOT_DIR}/${PARAM_VALUE}")
            endif()
            if(PARAM_NAME STREQUAL "PHYSX_EMSCRIPTEN_ARCH" AND DEFINED PHYSX_EMSCRIPTEN_ARCH
                    AND NOT PHYSX_EMSCRIPTEN_ARCH STREQUAL PARAM_VALUE)
                message(FATAL_ERROR "Preset ${preset_name} requires ${PARAM_VALUE}. Use a separate build directory for each Wasm architecture")
            endif()
            set(${PARAM_NAME} "${PARAM_VALUE}" CACHE STRING "Set by preset ${preset_name}")
        endif()
    endforeach()

    message(STATUS "PhysX preset '${preset_name}' switches applied (phase 1 - before project)")
endfunction()

# CMake only reports whether the prefix was supplied by the caller after project().
function(physx_apply_install_prefix)
    if(NOT PROJECT_IS_TOP_LEVEL OR NOT CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
        return()
    endif()

    set(INSTALL_PREFIX "${PROJECT_BINARY_DIR}/install")
    if(PHYSX_PRESET AND _PHYSX_PRESET_FILE)
        file(READ "${_PHYSX_PRESET_FILE}" PRESET_CONTENT)
        string(REGEX MATCH [[cmakeParam name="CMAKE_INSTALL_PREFIX" value="([^"]+)"]] PREFIX_MATCH "${PRESET_CONTENT}")
        if(PREFIX_MATCH)
            get_filename_component(INSTALL_PREFIX "${CMAKE_MATCH_1}" ABSOLUTE BASE_DIR "${_PHYSX_ROOT_DIR}")
        endif()
    endif()
    set(CMAKE_INSTALL_PREFIX "${INSTALL_PREFIX}" CACHE PATH "Install path prefix" FORCE)
endfunction()

# Internal helper: resolve and cache the preset file path.
function(_physx_resolve_preset_file preset_name)
    set(PUBLIC_PRESET_PATH "${_PHYSX_PRESETS_DIR}/public/${preset_name}.xml")
    set(INTERNAL_PRESET_PATH "${_PHYSX_PRESETS_DIR}/${preset_name}.xml")

    if(EXISTS "${PUBLIC_PRESET_PATH}")
        set(_PHYSX_PRESET_FILE "${PUBLIC_PRESET_PATH}" CACHE INTERNAL "Resolved preset file" FORCE)
        message(STATUS "Using public preset: ${preset_name}")
    elseif(EXISTS "${INTERNAL_PRESET_PATH}")
        set(_PHYSX_PRESET_FILE "${INTERNAL_PRESET_PATH}" CACHE INTERNAL "Resolved preset file" FORCE)
        message(STATUS "Using internal preset: ${preset_name}")
    else()
        physx_list_available_presets()
        message(FATAL_ERROR "Preset '${preset_name}' not found. See available presets listed above.")
    endif()
endfunction()

# Function to parse CMake switches from preset XML content
function(physx_parse_cmake_switches xml_content)
    # Common PhysX CMake switches that we support
    set(SUPPORTED_SWITCHES
        "PX_BUILDSNIPPETS"
        "PX_BUILDPVDRUNTIME"
        "PX_GENERATE_STATIC_LIBRARIES"
        "PX_GENERATE_GPU_PROJECTS"
        "PX_GENERATE_GPU_PROJECTS_ONLY"
        "PX_GENERATE_GPU_STATIC_LIBRARIES"
        "PX_SCALAR_MATH"
        "NV_USE_STATIC_WINCRT"
        "NV_USE_DEBUG_WINCRT"
        "PX_FLOAT_POINT_PRECISE_MATH"
        "PX_GENERATE_GPU_REDUCED_ARCHITECTURES"
    )
    
    foreach(SWITCH_NAME ${SUPPORTED_SWITCHES})
        # Look for the switch in XML content using regex
        # Pattern: <cmakeSwitch name="SWITCH_NAME" value="True|False"
        string(REGEX MATCH "cmakeSwitch name=\"${SWITCH_NAME}\" value=\"([^\"]+)\"" SWITCH_MATCH "${xml_content}")
        
        if(SWITCH_MATCH)
            # Extract the value (True/False)
            string(REGEX REPLACE ".*value=\"([^\"]+)\".*" "\\1" SWITCH_VALUE "${SWITCH_MATCH}")
            
            # Convert to CMake boolean and set the cache variable.
            # Use set(... CACHE BOOL ...) WITHOUT FORCE so that explicit
            # command-line -D flags take precedence over preset values.
            # CMake's cache semantics: if the variable is already in the cache
            # (from -D), set() without FORCE is a no-op, preserving the user's choice.
            # This also means the caller must not declare these options (option() or
            # set(CACHE)) before this function runs, or the preset value is lost.
            if("${SWITCH_VALUE}" STREQUAL "True")
                set(PRESET_BOOL ON)
            elseif("${SWITCH_VALUE}" STREQUAL "False")
                set(PRESET_BOOL OFF)
            else()
                continue()
            endif()
            set(${SWITCH_NAME} ${PRESET_BOOL} CACHE BOOL "Set by preset ${PHYSX_PRESET}")
            # Report the effective value and say so when it is not the preset's,
            # instead of a line that contradicts itself.
            if((${SWITCH_NAME} AND PRESET_BOOL) OR (NOT ${SWITCH_NAME} AND NOT PRESET_BOOL))
                message(STATUS "  ${SWITCH_NAME} = ${PRESET_BOOL} (from preset)")
            else()
                message(STATUS "  ${SWITCH_NAME} = ${${SWITCH_NAME}} (preset says ${PRESET_BOOL}; kept the value already in the cache, from -D or a previous configure)")
            endif()
        endif()
    endforeach()
endfunction()

# Function to override preset options that are incompatible with FetchContent
function(physx_override_fetchcontent_incompatible_options)
    # Disable snippets - they require FreeGLUT which we don't support in FetchContent
    if(PX_BUILDSNIPPETS)
        set(PX_BUILDSNIPPETS OFF CACHE BOOL "Disabled for FetchContent (requires FreeGLUT)" FORCE)
        message(STATUS "  PX_BUILDSNIPPETS = OFF (overridden for FetchContent compatibility)")
    endif()
    
    # For cpu-only presets, ensure GPU-only mode is also disabled
    if(PHYSX_PRESET MATCHES "cpu-only")
        set(PX_GENERATE_GPU_PROJECTS_ONLY OFF CACHE BOOL "Disabled for CPU-only preset" FORCE)
    endif()
endfunction()

