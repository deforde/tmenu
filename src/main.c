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

typedef struct EntryList {
  Entry *head;
  Entry *tail;
} EntryList;

// func decls

static void *dbgalloc(size_t sz);
static void dbgfree(void *p);

static Entry *createEntry(const Allocator *allocator, const char *s);
static void destroyEntry(const Allocator *allocator, Entry *e);
static void appendEntry(EntryList *l, Entry *e);
static void removeEntry(EntryList *l, Entry *e);
static bool appendUniqueEntry(EntryList *l, Entry *e);
static void destroyEntries(const Allocator *allocator, EntryList *l);
static void printEntries(EntryList l);
static void filterEntries(EntryList *l, EntryList *fout, const char *s);

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

void appendEntry(EntryList *l, Entry *e) {
  e->prev = l->tail;
  if (!l->head) {
    l->head = e;
  }
  if (!l->tail) {
    l->tail = e;
  } else {
    l->tail->next = e;
    l->tail = e;
  }
}

bool appendUniqueEntry(EntryList *l, Entry *e) {
  for (Entry *p = l->head; p; p = p->next) {
    if (strlen(p->name) == strlen(e->name) && strcmp(p->name, e->name) == 0) {
      return false;
    }
  }
  appendEntry(l, e);
  return true;
}

void removeEntry(EntryList *l, Entry *e) {
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
  if (e == l->head) {
    l->head = next;
  } else if (e == l->tail) {
    l->tail = prev;
  }
}

void destroyEntries(const Allocator *allocator, EntryList *l) {
  for (Entry *e = l->head; e;) {
    Entry *tmp = e->next;
    destroyEntry(allocator, e);
    e = tmp;
  }
  l->head = NULL;
  l->tail = NULL;
}

void printEntries(EntryList l) {
  for (Entry *e = l.head; e; e = e->next) {
    printf("%s\n", e->name);
  }
}

void filterEntries(EntryList *l, EntryList *fout, const char *s) {
  for (Entry *e = l->head; e;) {
    if(!strstr(e->name, s)) {
      Entry *tmp = e->next;
      removeEntry(l, e);
      appendEntry(fout, e);
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
  EntryList entries = {
    .head = NULL,
    .tail = NULL,
  };

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
          if (!appendUniqueEntry(&entries, e)) {
            destroyEntry(allocator, e);
          }
        }
      }
      free(dent);
    }

    free(namelist);
  }

  EntryList fout = {
    .head = NULL,
    .tail = NULL,
  };
  filterEntries(&entries, &fout, "gcc");
  printEntries(entries);

  destroyEntries(allocator, &fout);
  destroyEntries(allocator, &entries);

  exit(EXIT_SUCCESS);
}
