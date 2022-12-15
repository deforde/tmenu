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
