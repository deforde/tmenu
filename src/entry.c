/* Copyright (C) 2022 Daniel Forde - All Rights Reserved
 * You may use, distribute and modify this code under the
 * terms of the MIT license.
 *
 * You should have received a copy of the MIT license with this file.
 * If not, please write to: <daniel.forde001 at gmail dot com>,
 * or visit: https://github.com/deforde/tmenu
 */
#include "entry.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <dirent.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

Entry *entryCreate(const Allocator *allocator, const char *s) {
  size_t nm_len = strlen(s) + 1;
  size_t sz = sizeof(Entry) + nm_len;
  Entry *e = allocator->alloc(sz);
  if (e) {
    strncpy(e->path, s, nm_len);
    e->name = e->path;
    char *sep = strrchr(e->path, '/');
    if (sep) {
      e->name = ++sep;
      assert(e->name); // TODO: add proper error-checking
    }
    assert(e->path[nm_len - 1] == 0); // TODO: add proper error-checking
  }
  return e;
}

void entryDestroy(const Allocator *allocator, Entry *e) { allocator->free(e); }

EntryList entrylistInit(const Allocator *allocator) {
  EntryList entries = {
      .head = NULL,
      .tail = NULL,
  };

  char *path = getenv("PATH");
  if (path == NULL) {
    printf("Failed to get the environment variable: 'PATH'\n");
    return entries;
  }

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
          goto err;
        } else if (r >= (int)sizeof(realpath)) {
          printf("snprintf: destination buffer too small (actual size: %zu, "
                 "expected: %i)\n",
                 sizeof(realpath), r);
          goto err;
        }

        struct stat sb;
        if (stat(realpath, &sb) == -1) {
          perror("stat");
          goto err;
        }
        if (sb.st_mode & S_IXUSR) {
          // printf("%s\n", dent->d_name);
          Entry *e = entryCreate(allocator, realpath);
          if (e == NULL) {
            printf("Failed to allocate memory for entry\n");
            goto err;
          }
          if (!entrylistAppendUnique(&entries, e)) {
            entryDestroy(allocator, e);
          }
        }
      }

    err:
      free(dent);
    }

    free(namelist);
  }

  return entries;
}

void entrylistAppend(EntryList *l, Entry *e) {
  e->prev = l->tail;
  if (!l->head) {
    l->head = e;
  }
  if (l->tail) {
    l->tail->next = e;
  }
  l->tail = e;
  l->len++;
}

void entrylistExtend(EntryList *l, EntryList m) {
  if (l->tail) {
    l->tail->next = m.head;
  }
  l->tail = m.tail;
  l->len += m.len;
}

bool entrylistAppendUnique(EntryList *l, Entry *e) {
  for (Entry *p = l->head; p; p = p->next) {
    if (strlen(p->name) == strlen(e->name) && strcmp(p->name, e->name) == 0) {
      return false;
    }
  }
  entrylistAppend(l, e);
  l->len++;
  return true;
}

void entrylistRemove(EntryList *l, Entry *e) {
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
  }
  if (e == l->tail) {
    l->tail = prev;
  }
  l->len--;
}

void entrylistDestroy(const Allocator *allocator, EntryList *l) {
  for (Entry *e = l->head; e;) {
    Entry *tmp = e->next;
    entryDestroy(allocator, e);
    e = tmp;
  }
  l->head = NULL;
  l->tail = NULL;
  l->len = 0;
}

void entrylistPrint(EntryList l) {
  for (Entry *e = l.head; e; e = e->next) {
    printf("%s\n", e->name);
  }
}

void entrylistFilter(EntryList *l, EntryList *fout, const char *s) {
  for (Entry *e = l->head; e;) {
    if (!strstr(e->name, s)) {
      Entry *tmp = e->next;
      entrylistRemove(l, e);
      entrylistAppend(fout, e);
      e = tmp;
      continue;
    }
    e = e->next;
  }
}
