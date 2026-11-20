# PhysX FetchContent Integration

Integrate PhysX into CMake projects via `FetchContent` with zero manual setup.

## Requirements

- **CMake** 3.21 or later. The Visual Studio 2026 generator requires CMake 4.2 or later.
- **C++14**-capable compiler (GCC 7+, Clang 5+, MSVC 2017+)
- **GPU builds (optional):** CUDA toolkit and a compatible NVIDIA GPU

## How to Use

### Basic Usage with Presets (Recommended)
```cmake
cmake_minimum_required(VERSION 3.21)
project(MyPhysXApp LANGUAGES CXX)

include(FetchContent)

set(PHYSX_PRESET "windows-vc17-x64")    # Visual Studio 2022 x64
# set(PHYSX_PRESET "linux-x64")        # Linux x64

# Download and configure PhysX (pin GIT_TAG to a release tag or commit you need)
FetchContent_Declare(
    physx_lib
    GIT_REPOSITORY https://github.com/o3de/PhysX.git
    GIT_TAG        <commit>     # Pin an O3DE revision containing these presets
    SOURCE_SUBDIR  physx
)

FetchContent_MakeAvailable(physx_lib)

# Create your application
add_executable(my_app main.cpp)

# Link with PhysX (automatically includes headers, libraries, definitions)
target_link_libraries(my_app PRIVATE physx_lib)
```

### Manual Configuration (Advanced)
```cmake
# Instead of presets, set options explicitly before FetchContent_Declare:
set(PX_GENERATE_GPU_PROJECTS OFF CACHE BOOL "" FORCE)
set(PX_GENERATE_STATIC_LIBRARIES ON CACHE BOOL "" FORCE)
set(PX_BUILDSNIPPETS OFF CACHE BOOL "" FORCE)

FetchContent_Declare(
    physx_lib
    GIT_REPOSITORY https://github.com/o3de/PhysX.git
    GIT_TAG        <commit>     # Pin an O3DE revision containing these presets
    SOURCE_SUBDIR  physx
)
FetchContent_MakeAvailable(physx_lib)
```

### Available Presets

| Platform | Presets |
|----------|---------|
| Windows | `windows-vc17-x64`, `windows-vc17-a64`, `windows-vc18-x64`, `windows-vc18-a64` |
| Linux | `linux-x64`, `linux-a64` |
| macOS | `mac-x64`, `mac-a64` |
| iOS | `ios-a64`, `ios-simulator-a64`, `ios-simulator-x64` |
| Android | `android-a64`, `android-x64` |
| Emscripten | `emscripten-w32`, `emscripten-w64` |

The presets default to CPU builds. On CUDA-capable targets, enable GPU support with `-DPX_GENERATE_GPU_PROJECTS=ON`. When using the legacy generator, a `.user.xml` preset can enable the same option.

Linux uses CMake's compiler selection. Set `CC` and `CXX` before configuring a new build directory to choose GCC or Clang. The legacy generator uses Ninja. To build Linux ARM64 from an x64 host, pass `-DCMAKE_TOOLCHAIN_FILE=<path>` to direct CMake or set the `CMAKE_TOOLCHAIN_FILE` environment variable before running `generate_projects.sh linux-a64`. The repository provides `physx/buildtools/cmake/linux-aarch64-cross.cmake` for a Linux host with the GNU ARM64 cross-toolchain installed.

With direct CMake, select the generator and architecture before configuring. For example, pass `-G "Visual Studio 17 2022" -A ARM64` with `windows-vc17-a64`, or `-G Xcode` with an Apple preset.

### Manual Customization Options
```cmake
# Control library types
set(PX_GENERATE_STATIC_LIBRARIES ON)        # Use static libraries
# WARNING: Do NOT enable PX_GENERATE_GPU_STATIC_LIBRARIES when PX_GENERATE_STATIC_LIBRARIES is ON.
# Building both PhysX and PhysXGpu as static causes duplicate symbol linker errors.
# Keep PhysXGpu shared (the default) when using static PhysX libraries.
# set(PX_GENERATE_GPU_STATIC_LIBRARIES ON)  # Not recommended with static PhysX

# Control features
set(PX_GENERATE_GPU_PROJECTS OFF)           # Disable GPU support
set(PX_BUILDPVDRUNTIME ON)                  # Include PVD runtime
# set(PX_BUILDSNIPPETS ON)                  # NOT recommended: +8min build, requires OpenGL/GLUT

# Then make available
FetchContent_MakeAvailable(physx_lib)
```

### Advanced Configuration

#### Custom User Presets

For reusable configurations, create a preset XML file in `physx/buildtools/presets/` (use `.user.xml` suffix to keep it out of version control):

```xml
<?xml version="1.0" encoding="utf-8"?>
<preset name="my-project-x64">
  <platform targetPlatform="windows" compiler="vc17" />
  <CMakeSwitches>
    <cmakeSwitch name="PX_GENERATE_GPU_PROJECTS" value="True" />
    <cmakeSwitch name="PX_GENERATE_STATIC_LIBRARIES" value="False" />
    <cmakeSwitch name="PX_BUILDPVDRUNTIME" value="True" />
    <cmakeSwitch name="NV_USE_STATIC_WINCRT" value="False" />
  </CMakeSwitches>
</preset>
```

The Windows project generator uses the `-x64` or `-a64` preset suffix to select the Visual Studio architecture. Reference the preset by filename without `.xml`:
```cmake
set(PHYSX_PRESET "my-project-x64.user" CACHE STRING "" FORCE)
```

#### Command-Line Configuration

Pass options directly without modifying CMakeLists.txt:
```bash
cmake -B build -DPHYSX_PRESET=windows-vc17-x64                    # Use a preset
cmake -B build -DPX_GENERATE_GPU_PROJECTS=OFF -DPX_GENERATE_STATIC_LIBRARIES=ON  # Manual flags
cmake -B build -DPHYSX_PRESET= -DPX_GENERATE_GPU_PROJECTS=OFF       # Bypass preset
```

#### Windows Runtime Library

Public presets use `/MD` (dynamic CRT) to match CMake defaults. For `/MT` (static CRT):
```cmake
set(NV_USE_STATIC_WINCRT ON CACHE BOOL "" FORCE)
```

### Build Configuration Types (Important for Visual Studio / Xcode)

PhysX uses custom build configuration types: `debug`, `checked`, `profile`, and `release` — not the standard CMake `Debug`, `Release`, `RelWithDebInfo`, `MinSizeRel`. These custom configs are required by the PhysX SDK (e.g., `checked` enables validation and performance profiling that doesn't map to any standard CMake config).

When PhysX is included via FetchContent, it sets `CMAKE_CONFIGURATION_TYPES` to these custom values. This has the following implications for **multi-config generators** (Visual Studio, Xcode):

- Use `--config release` (lowercase) instead of `--config Release` when building:
  ```bash
  cmake --build build --config release
  ```
- The Visual Studio configuration dropdown will show `debug`, `checked`, `profile`, `release` instead of the standard names
- CMake generator expressions like `$<CONFIG:Release>` still work — they are case-insensitive since CMake 3.19, and this MR requires CMake 3.21+
- Output directories follow PhysX conventions (e.g., `bin/win.x86_64.vc143/release/`)

**Single-config generators** (Makefiles, Ninja) are unaffected — set `CMAKE_BUILD_TYPE` as usual:
```bash
cmake -DCMAKE_BUILD_TYPE=release ../physx
```

### What the `physx_lib` target provides

`FetchContent_MakeAvailable(physx_lib)` creates an INTERFACE target named `physx_lib`. It is an INTERFACE target (not STATIC/SHARED) because PhysX can be built as either — the INTERFACE target abstracts this away. It aggregates:

- **Libraries**: PhysX, PhysXCommon, PhysXFoundation, PhysXCharacterKinematic, PhysXVehicle, PhysXExtensions, PhysXPvdSDK (and PhysXGpu when GPU is enabled)
- **Include directories**: All public PhysX headers
- **Compile definitions**: GPU/CPU mode flags, platform defines

`target_link_libraries(my_app PRIVATE physx_lib)` is all you need.

### Installing and using find_package

Both build entry points default to `<build-dir>/install`. Set `CMAKE_INSTALL_PREFIX` at configure time or pass `--prefix` when installing to choose a different directory. When installing multiple configurations from a Visual Studio or Xcode build tree, give each configuration its own prefix if you want to keep them side by side.

Use separate build and install directories for static and shared SDKs. Both use the same library basenames. Start with fresh build directories when switching to these names so cached output paths and old binaries stay out of the new build.

PhysX supports the standard CMake install + `find_package` workflow for production deployments:

```bash
# Build and install PhysX (top-level, not via FetchContent)
cmake -B build physx -DCMAKE_BUILD_TYPE=release -DCMAKE_INSTALL_PREFIX=/opt/physx \
      -DPX_GENERATE_GPU_PROJECTS=OFF -DPX_BUILDPVDRUNTIME=ON
cmake --build build --parallel
cmake --install build
```

Then consume from another project:
```cmake
cmake_minimum_required(VERSION 3.21)
project(my_app LANGUAGES CXX)

find_package(PhysX REQUIRED)

add_executable(my_app main.cpp)
target_link_libraries(my_app PRIVATE ${PhysX_LIBRARIES})
target_include_directories(my_app PRIVATE ${PhysX_INCLUDE_DIRS})
```

Configure with:
```bash
cmake -B build -DCMAKE_PREFIX_PATH=/opt/physx
```

The installed package provides both legacy variables (`PhysX_LIBRARIES`, `PhysX_INCLUDE_DIRS`) and modern namespaced targets (`PhysX::PhysX`, `PhysX::PhysXCommon`, etc.).

### Debug and development options
```cmake
set(FETCHCONTENT_QUIET OFF)  # Verbose FetchContent output

# Use a local PhysX repo instead of downloading
# (path must be the repo root containing the "physx/" subdirectory)
set(FETCHCONTENT_SOURCE_DIR_PHYSX_LIB "C:/dev/physics-repo")   # Windows
set(FETCHCONTENT_SOURCE_DIR_PHYSX_LIB "/home/dev/physics-repo") # Linux
```

## Reference

### Key Files

| File | Role |
|---|---|
| `physx/CMakeLists.txt` | Root entry point — preset loading, `project()` with CUDA handling, `physx_lib` interface target, install/export logic |
| `physx/buildtools/cmake/PhysXPresets.cmake` | Two-phase preset system (switches before `project()`, params after) |
| `physx/buildtools/cmake/PhysXConfigurationTypes.cmake` | Custom build configs (debug/checked/profile/release) |
| `physx/source/compiler/cmake/PhysXConfig.cmake.in` | `find_package(PhysX)` config template for post-install consumption |
| `physx/documentation/fetchcontent/` | User guide, CI guide, working example app |

### Key Design Decisions

1. **Two-phase presets** — GPU/CUDA options resolved *before* `project()` so CUDA is only enabled when needed
2. **Subproject CUDA handling** — Uses `enable_language(CUDA)` instead of declaring it in `project()` to avoid conflicts with parent project languages
3. **`physx_lib` INTERFACE target** — Single aggregator with curated include paths; does not propagate individual target includes to avoid exposing internal source tree paths
4. **`PX_ENABLE_INSTALL`** — TRUE for top-level, FALSE for subprojects, gating all install rules
5. **Snippets forced OFF** — Snippets require OpenGL/GLUT and add ~8 min build time
6. **`PX_BUILDPVDRUNTIME` opt-in** — Default `OFF` (the standard presets enable it); when set, builds the static OmniPVD runtime linked into every OmniPVD owner
7. **RPATH for shared libraries** — `$ORIGIN`-based RPATH so shared libs find each other at runtime
