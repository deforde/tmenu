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
