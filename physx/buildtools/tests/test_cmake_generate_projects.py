# Copyright (c) Contributors to the Open 3D Engine Project.
# SPDX-License-Identifier: Apache-2.0 OR MIT

from pathlib import Path
import os
import shlex
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from cmake_generate_projects import CMakePreset


class WindowsPresetTests(unittest.TestCase):
    def arguments(self, compiler, generator=None, gpu=False, target='win64'):
        preset = object.__new__(CMakePreset)
        preset.compiler = compiler
        preset.generator = generator
        preset.targetPlatform = target
        preset.cmakeSwitches = [
            '-DPX_GENERATE_GPU_PROJECTS=' + str(gpu).upper(),
            '-DPX_GENERATE_GPU_PROJECTS_ONLY=FALSE',
        ]
        with patch.dict(os.environ, {'PHYSX_ROOT_DIR': 'physx'}):
            command = preset.getPlatformCMakeParams() + preset.getCMakeSwitches()
        return shlex.split(command.replace('\\"', '"'))

    def test_visual_studio_2022_selects_the_requested_toolset(self):
        for compiler, toolset in [('vc16', 'v142'), ('vc17', 'v143')]:
            with self.subTest(compiler=compiler):
                arguments = self.arguments(compiler)
                self.assertEqual(arguments[arguments.index('-G') + 1], 'Visual Studio 17 2022')
                self.assertIn('-T' + toolset, arguments)

    def test_cuda_and_compiler_use_one_toolset_argument(self):
        cuda = 'C:/CUDA Toolkit'
        with patch.dict(os.environ, {'PM_CUDA_PATH': cuda}), patch('os.path.isfile', return_value=True):
            arguments = self.arguments('vc17', gpu=True)
        self.assertEqual([arg for arg in arguments if arg.startswith('-T')], ['-Tv143,cuda=' + cuda])
        self.assertIn('-DCUDAToolkit_ROOT_DIR=' + cuda, arguments)
        nvcc = 'nvcc.exe' if sys.platform == 'win32' else 'nvcc'
        self.assertIn('-DCMAKE_CUDA_COMPILER=' + cuda + '/bin/' + nvcc, arguments)

    def test_ninja_does_not_receive_visual_studio_toolset_flags(self):
        arguments = self.arguments('vc17', generator='ninja')
        self.assertEqual(arguments[arguments.index('-G') + 1], 'Ninja Multi-Config')
        self.assertFalse(any(arg.startswith(('-T', '-A')) for arg in arguments))

    def test_windows_arm_keeps_cross_compilation_settings(self):
        arguments = self.arguments('vc17', target='winArm64')
        self.assertIn('-AARM64', arguments)
        self.assertIn('-Tv143', arguments)
        self.assertIn('-DCMAKE_SYSTEM_PROCESSOR=ARM64', arguments)


if __name__ == '__main__':
    unittest.main()
