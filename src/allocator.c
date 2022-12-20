/* Copyright (C) 2022 Daniel Forde - All Rights Reserved
 * You may use, distribute and modify this code under the
 * terms of the MIT license.
 *
 * You should have received a copy of the MIT license with this file.
 * If not, please write to: <daniel.forde001 at gmail dot com>,
 * or visit: https://github.com/deforde/tmenu
 */
#include "allocator.h"

#include <assert.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define NARENA
#ifdef NARENA

static void stdAllocInit(void);
static void stdAllocDestroy(void);
static void *stdAlloc(size_t sz);

Allocator *allocator = &(Allocator){
    .init = stdAllocInit,
    .destroy = stdAllocDestroy,
    .alloc = stdAlloc,
    .free = free,
};

void stdAllocInit(void) {}

void stdAllocDestroy(void) {}

void *stdAlloc(size_t sz) { return calloc(1, sz); }

#else

#define ARENA_SIZE 1024ULL
#define ARENA_ALIGN (2 * sizeof(void *))

typedef struct {
  unsigned char *buf;
  size_t buf_len;
  size_t offset;
} ArenaAllocator;

static void arenaInit(void);
static void arenaDestroy(void);
static void *arenaAlloc(size_t sz);
static void arenaFree(void *p);

Allocator *allocator = &(Allocator){
    .init = arenaInit,
    .destroy = arenaDestroy,
    .alloc = arenaAlloc,
    .free = arenaFree,
};

static ArenaAllocator arena = {0};

void arenaInit(void) {
  size_t sz = ARENA_SIZE;
  if (sz % ARENA_ALIGN != 0) {
    sz = (sz / ARENA_ALIGN + 1) * ARENA_ALIGN;
  }
  arena.buf = calloc(1, sz);
  arena.buf_len = sz;
  arena.offset = 0;
}

void arenaDestroy(void) {
  free(arena.buf);
  arena.buf_len = 0;
  arena.offset = 0;
}

void *arenaAlloc(size_t sz) {
  uintptr_t cur = (uintptr_t)arena.buf + (uintptr_t)arena.offset;
  if (cur % ARENA_ALIGN != 0) {
    cur = (cur / ARENA_ALIGN + 1) * ARENA_ALIGN;
    arena.offset = cur - (uintptr_t)arena.buf;
  }

  if (sz > (arena.buf_len - arena.offset)) {
    return NULL;
  }

  void *mem = &arena.buf[arena.offset];
  assert((uintptr_t)mem % 16 == 0);
  arena.offset += sz;
  return mem;
}

void arenaFree(__attribute__((unused)) void *p) {}

#endif
