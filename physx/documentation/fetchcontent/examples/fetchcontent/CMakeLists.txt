# Required minimum CMake version
#
# PhysX requires CMake 3.21+. FetchContent_MakeAvailable is available since 3.14.
cmake_minimum_required(VERSION 3.21)

# Define project name and languages
project(hello-physx-cmake LANGUAGES CXX)

#########################################################
# DEPENDENCIES SETUP
#########################################################

# Include required CMake modules
include(FetchContent)       # Module for downloading and configuring external dependencies
include(GNUInstallDirs)     # Sets standard installation directories (bin, lib, etc.)

# <DEBUG>
# To use a local PhysX repository instead of downloading, set the path to the repo root
# (the directory that contains the "physx" subdirectory):
# if(WIN32)
#   set(FETCHCONTENT_SOURCE_DIR_PHYSX_LIB "C:/path/to/physics-repo")
# else()
#   set(FETCHCONTENT_SOURCE_DIR_PHYSX_LIB "/path/to/physics-repo")
# endif()
# </DEBUG>

# Display download progress in the terminal (useful for larger dependencies)
set(FETCHCONTENT_QUIET OFF)

#########################################################
# PHYSX CONFIGURATION - Choose your build preset
#########################################################

# Set PHYSX_PRESET explicitly when choosing a different toolset or target.
if(NOT DEFINED PHYSX_PRESET)
    if(CMAKE_GENERATOR MATCHES "^Visual Studio (17|18) ")
        set(physx_vs_version "${CMAKE_MATCH_1}")
        string(TOLOWER "${CMAKE_VS_PLATFORM_NAME}" physx_arch)
        if(physx_arch STREQUAL "arm64")
            set(physx_arch "a64")
        endif()
        if(physx_arch MATCHES "^(x64|a64)$")
            set(PHYSX_PRESET "windows-vc${physx_vs_version}-${physx_arch}")
        endif()
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        if(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
            set(PHYSX_PRESET "linux-a64")
        elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
            set(PHYSX_PRESET "linux-x64")
        endif()
    endif()
endif()

# OPTION 2: Manual configuration (advanced users only)
# You can override specific options instead of using a preset:
# set(PX_GENERATE_GPU_PROJECTS OFF CACHE BOOL "" FORCE)      # Disable GPU
# set(PX_GENERATE_STATIC_LIBRARIES ON CACHE BOOL "" FORCE)   # Use static libs
# set(PX_BUILDSNIPPETS ON CACHE BOOL "" FORCE)               # Build 50+ examples (NOT recommended: +8min build time + OpenGL deps)

#########################################################
# FETCHCONTENT DECLARATION  
#########################################################

# Use the PhysX checkout that contains this example.
FetchContent_Declare(
    physx_lib
    SOURCE_DIR    "${CMAKE_CURRENT_LIST_DIR}/../../../../.."
    SOURCE_SUBDIR physx
)

# Note: We intentionally avoid requiring very new CMake features (e.g.
# CMAKE_POLICY_VERSION_MINIMUM) so the example configures with CMake 3.21+.
# You can also set additional cmake options here for PhysX before the MakeAvailable call
# where PhysX is configured.
# set(PX_GENERATE_STATIC_LIBRARIES ON)
# set(PX_GENERATE_GPU_STATIC_LIBRARIES ON)

# Make PhysX available to our project
# This downloads, configures, and makes PhysX targets available
FetchContent_MakeAvailable(physx_lib)

# Log PhysX directories for debugging purposes
message(STATUS "PhysX source directory: ${physx_lib_SOURCE_DIR}")
message(STATUS "PhysX binary directory: ${physx_lib_BINARY_DIR}")

#########################################################
# APPLICATION SETUP
#########################################################

# Create our application executable
add_executable(hello-physx-cmake main.cpp)

# Link our executable with PhysX - the modern CMake way
# This automatically includes all necessary dependencies:
# - All PhysX libraries
# - Required include directories  
# - Compiler definitions
# - Runtime library settings (/MD on Windows by default)
# - Other properties from the PhysX targets
target_link_libraries(hello-physx-cmake PRIVATE physx_lib)

#########################################################
# INSTALLATION OF EXECUTABLE AND DEPENDENCIES
#########################################################

# Configure runtime path for the executable
# This ensures the executable can find its shared libraries at runtime
set_target_properties(hello-physx-cmake PROPERTIES
  # $ORIGIN refers to the executable's location (Linux specific)
  # This sets the runtime search path to look in ../lib relative to the executable
  INSTALL_RPATH "$ORIGIN/../${CMAKE_INSTALL_LIBDIR}"

  # Don't use install RPATH during the build phase
  BUILD_WITH_INSTALL_RPATH OFF

  # Remove build directory paths from the binary, activate this if you just want
  # to install your app and not test it from the build folder
  #  SKIP_BUILD_RPATH        ON
)

if (WIN32) # Optional
  # After building hello-physx-cmake, copy all its runtime DLLs next to the EXE in the build folder.
  # This is useful for windows (since there's no rpath) to find the DLLs at runtime
  add_custom_command(TARGET hello-physx-cmake
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      $<TARGET_RUNTIME_DLLS:hello-physx-cmake>
      $<TARGET_FILE_DIR:hello-physx-cmake>
    # ensure the generator expression list is expanded
    COMMAND_EXPAND_LISTS
  )
endif()

# Optional: Basic installation of the executable 
# Note: For advanced dependency installation, use cmake --install with --prefix
install(TARGETS hello-physx-cmake
  RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"   # For executables
  LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"   # For shared libraries  
  ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"   # For static libraries
)
