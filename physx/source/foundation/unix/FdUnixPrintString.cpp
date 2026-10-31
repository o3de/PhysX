// Copyright (c) 2001-2004 NovodeX AG. All rights reserved.
// Copyright (c) 2004-2008 AGEIA Technologies, Inc. All rights reserved.
// SPDX-FileCopyrightText: Copyright (c) 2008-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

#include "foundation/PxString.h"
#include <stdio.h>

#if PX_ANDROID
#include <android/log.h>
#endif

namespace physx
{

void PxPrintString(const char* str)
{
#if PX_ANDROID
	__android_log_print(ANDROID_LOG_INFO, "PsPrintString", "%s", str);
#else
	puts(str);
#endif
}

} // namespace physx
