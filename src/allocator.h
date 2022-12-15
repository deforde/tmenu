/* Copyright (C) 2022 Daniel Forde - All Rights Reserved
 * You may use, distribute and modify this code under the
 * terms of the MIT license.
 *
 * You should have received a copy of the MIT license with this file.
 * If not, please write to: <daniel.forde001 at gmail dot com>,
 * or visit: https://github.com/deforde/tmenu
 */
#ifndef ALLOCATOR_H
#define ALLOCATOR_H

#include <stddef.h>

typedef void *(*AllocFn)(size_t);
typedef void (*FreeFn)(void *);

typedef struct Allocator {
  AllocFn alloc;
  FreeFn free;
} Allocator;

extern Allocator *debug_allocator;

#define DBG_ALLOCATOR debug_allocator

#endif // ALLOCATOR_H
