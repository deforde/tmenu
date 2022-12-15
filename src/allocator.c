/* Copyright (C) 2022 Daniel Forde - All Rights Reserved
 * You may use, distribute and modify this code under the
 * terms of the MIT license.
 *
 * You should have received a copy of the MIT license with this file.
 * If not, please write to: <daniel.forde001 at gmail dot com>,
 * or visit: https://github.com/deforde/tmenu
 */
#include "allocator.h"

#include <stdlib.h>

static void *dbgalloc(size_t sz);
static void dbgfree(void *p);

Allocator *debug_allocator = &(Allocator){
    .alloc = dbgalloc,
    .free = dbgfree,
};

void *dbgalloc(size_t sz) { return calloc(1, sz); }

void dbgfree(void *p) { free(p); }
