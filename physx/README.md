# NVIDIA PhysX SDK 5

Copyright (c) 2008-2026 NVIDIA Corporation & Affiliates. All rights reserved.

PhysX is licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
The complete license is provided in [LICENSE.md](LICENSE.md).
Third-party code retains its respective terms; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Introduction

Welcome to the NVIDIA PhysX SDK source code repository.

The NVIDIA PhysX SDK is a scalable multi-platform physics solution for CPUs and GPUs.  See [PhysX SDK on developer.nvidia.com](https://developer.nvidia.com/physx-sdk).

The [Release Notes](./CHANGELOG.md) contain updates pertaining to the latest version.

## User Guide and API Documentation

The user guide and API documentation are available on [GitHub Pages](https://nvidia-omniverse.github.io/PhysX/physx/index.html). Please create an [Issue](https://github.com/NVIDIA-Omniverse/PhysX/issues/) if you find a documentation issue.

## Quick Start Instructions

Platform specific environment and build information can be found in [documentation/platformreadme](./documentation/platformreadme).

To begin, clone this repository onto your local drive.  Then change directory to physx/, run ./generate_projects.[bat|sh] and follow on-screen prompts.  This will let you select a platform specific solution to build.  You can then build from the generated solution/make file in the platform- and configuration-specific folders in the ``compiler`` folder.

Note that the PhysX distribution downloads binary content, such as the PhysX GPU binaries, from Amazon CloudFront on demand, using the packman package manager.

### Emscripten

Activate the Emscripten SDK and use `emscripten-w32` for wasm32 or `emscripten-w64` for wasm64. When adding PhysX to an existing CMake project, select the same Wasm architecture for C and C++ before the top-level `project()`. For wasm64, pass `-m64` in both `CMAKE_C_FLAGS` and `CMAKE_CXX_FLAGS`.

Browser applications using PhysX workers need a cross-origin-isolated page and a prestarted Emscripten pthread pool. Set `-sPTHREAD_POOL_SIZE=<number>` at the application link step to cover all concurrent pthreads, including the application's own threads. Run blocking simulation calls off the browser main thread where possible. The CMake SDK targets enable `-sPTHREAD_POOL_SIZE_STRICT=2` so an exhausted pool fails immediately. Pass that flag explicitly when linking the archives by hand. See the [Emscripten pthread guide](https://emscripten.org/docs/porting/pthreads.html).

## Acknowledgements

This depot references packages of third party open source software copyright their respective owners.
For downloaded packages, refer to the license files included in those packages.
For the bundled GLEW, Mesa, and Khronos code, see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

| Software                  | Copyright Holder                                                                    | Package                          |
|---------------------------|-------------------------------------------------------------------------------------|----------------------------------|
| CMake                     | Kitware, Inc. and Contributors                                                      | cmake                            |
| LLVM                      | University of Illinois at Urbana-Champaign                                          | clang-physxmetadata              |
| Visual Studio Locator     | Microsoft Corporation                                                               | VsWhere                          |
| Freeglut                  | Pawel W. Olszta                                                                     | freeglut-windows                 |
| Mesa 3-D graphics library | Brian Paul                                                                          | OpenGL                           |
| RapidJSON                 | THL A29 Limited, a Tencent company, and Milo Yip<br>Alexander Chemeris (msinttypes) | rapidjson                        |
| OpenGL Ext Wrangler Lib   | Nigel Stewart, Milan Ikits, Marcelo E. Magallon, Lev Povalahev                      | [SDK_ROOT]/snippets/graphics     |
