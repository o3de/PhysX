# SPDX-License-Identifier: Apache-2.0 OR MIT
# Use the installed NDK on either Windows or Linux.
if(NOT DEFINED CMAKE_ANDROID_NDK)
    set(CMAKE_ANDROID_NDK "$ENV{ANDROID_NDK_HOME}" CACHE PATH "Android NDK")
endif()
if(NOT EXISTS "${CMAKE_ANDROID_NDK}/build/cmake/android.toolchain.cmake")
    message(FATAL_ERROR "Set ANDROID_NDK_HOME or CMAKE_ANDROID_NDK to an installed Android NDK")
endif()
set(ANDROID_STL c++_static CACHE STRING "Android C++ runtime")
include("${CMAKE_ANDROID_NDK}/build/cmake/android.toolchain.cmake")
