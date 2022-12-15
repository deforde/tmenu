/* Copyright (C) 2022 Daniel Forde - All Rights Reserved
 * You may use, distribute and modify this code under the
 * terms of the MIT license.
 *
 * You should have received a copy of the MIT license with this file.
 * If not, please write to: <daniel.forde001 at gmail dot com>,
 * or visit: https://github.com/deforde/tmenu
 */
#include <assert.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#include <dirent.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <ncurses.h>

// typedefs

typedef void *(*alloc_fn_t)(size_t);
typedef void (*free_fn_t)(void *);

typedef struct Allocator {
  alloc_fn_t alloc;
  free_fn_t free;
} Allocator;

typedef struct Entry Entry;
struct Entry {
  Entry *prev;
  Entry *next;
  char name[];
};

// func decls

static void *dbgalloc(size_t sz);
static void dbgfree(void *p);

static Entry *createEntry(const Allocator *allocator, const char *s);
static void destroyEntry(const Allocator *allocator, Entry *e);
static void appendEntry(Entry **entries, Entry *e);
static void removeEntry(Entry *e);
static bool addEntry(Entry **entries, Entry *e);
static void destroyEntries(const Allocator *allocator, Entry *entries);
static void printEntries(Entry *entries);
static void filterEntries(Entry **entries, Entry **fout, const char *s);

// global vars

static Allocator dbgallocator = {
    .alloc = dbgalloc,
    .free = dbgfree,
};

// func defs

void *dbgalloc(size_t sz) { return calloc(1, sz); }

void dbgfree(void *p) { free(p); }

Entry *createEntry(const Allocator *allocator, const char *s) {
  size_t nm_len = strlen(s) + 1;
  size_t sz = sizeof(Entry) + nm_len;
  Entry *e = allocator->alloc(sz);
  if (e) {
    strncpy(e->name, s, nm_len);
    assert(e->name[nm_len - 1] == 0); // TODO: add proper error-checking
  }
  return e;
}

void destroyEntry(const Allocator *allocator, Entry *e) { allocator->free(e); }

void appendEntry(Entry **entries, Entry *e) {
  if (*entries) {
    (*entries)->prev = e;
  }
  e->next = *entries;
  *entries = e;
}

bool addEntry(Entry **entries, Entry *e) {
  for (Entry *p = *entries; p; p = p->next) {
    if (strlen(p->name) == strlen(e->name) && strcmp(p->name, e->name) == 0) {
      return false;
    }
  }
  appendEntry(entries, e);
  return true;
}

void removeEntry(Entry *e) {
  Entry *prev = e->prev;
  Entry *next = e->next;
  if (prev) {
    prev->next = next;
  }
  if (next) {
    next->prev = prev;
  }
  e->prev = NULL;
  e->next = NULL;
}

void destroyEntries(const Allocator *allocator, Entry *entries) {
  for (Entry *e = entries; e;) {
    Entry *tmp = e->next;
    destroyEntry(allocator, e);
    e = tmp;
  }
}

void printEntries(Entry *entries) {
  for (Entry *e = entries; e; e = e->next) {
    printf("%s\n", e->name);
  }
}

void filterEntries(Entry **entries, Entry **fout, const char *s) {
  for (Entry *e = *entries; e;) {
    if(!strstr(e->name, s)) {
      Entry *tmp = e->next;
      removeEntry(e);
      appendEntry(fout, e);
      if (*entries == e) {
        *entries = tmp;
      }
      e = tmp;
      continue;
    }
    e = e->next;
  }
}

int main() {
  char *path = getenv("PATH");
  if (path == NULL) {
    printf("Failed to get the environment variable: 'PATH'\n");
    exit(EXIT_FAILURE);
  }

  Allocator *allocator = &dbgallocator;
  Entry *entries = NULL;

  char *saveptr = NULL;
  for (char *str = path;; str = NULL) {
    char *tok = strtok_r(str, ":", &saveptr);
    if (tok == NULL) {
      break;
    }

    struct dirent **namelist = NULL;
    int n = scandir(tok, &namelist, NULL, alphasort);
    if (n == -1) {
      // perror("scandir");
      continue;
    }

    while (n--) {
      struct dirent *dent = namelist[n];
      if (dent->d_type == DT_REG) {
        char realpath[PATH_MAX] = {0};
        int r =
            snprintf(realpath, sizeof(realpath), "%s/%s", tok, dent->d_name);
        if (r == -1) {
          perror("snprintf");
          exit(EXIT_FAILURE);
        } else if (r >= (int)sizeof(realpath)) {
          printf("snprintf: destination buffer too small (actual size: %zu, "
                 "expected: %i)\n",
                 sizeof(realpath), r);
        }

        struct stat sb;
        if (stat(realpath, &sb) == -1) {
          perror("stat");
          exit(EXIT_FAILURE);
        }
        if (sb.st_mode & S_IXUSR) {
          // printf("%s\n", dent->d_name);
          Entry *e = createEntry(allocator, dent->d_name);
          if (e == NULL) {
            printf("Failed to allocate memory for entry\n");
            exit(EXIT_FAILURE);
          }
          if (!addEntry(&entries, e)) {
            destroyEntry(allocator, e);
          }
        }
      }
      free(dent);
    }

    free(namelist);
  }

  Entry *fout = NULL;
  filterEntries(&entries, &fout, "gcc");
  printEntries(entries);

  destroyEntries(allocator, fout);
  destroyEntries(allocator, entries);

  exit(EXIT_SUCCESS);
}
