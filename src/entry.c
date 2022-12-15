#include "entry.h"

#include <assert.h>
#include <stdio.h>
#include <string.h>

Entry *entryCreate(const Allocator *allocator, const char *s) {
  size_t nm_len = strlen(s) + 1;
  size_t sz = sizeof(Entry) + nm_len;
  Entry *e = allocator->alloc(sz);
  if (e) {
    strncpy(e->name, s, nm_len);
    assert(e->name[nm_len - 1] == 0); // TODO: add proper error-checking
  }
  return e;
}

void entryDestroy(const Allocator *allocator, Entry *e) { allocator->free(e); }

void entrylistAppend(EntryList *l, Entry *e) {
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

void entrylistExtend(EntryList *l, EntryList m) {
  if (l->tail) {
    l->tail->next = m.head;
  }
  l->tail = m.tail;
}

bool entrylistAppendUnique(EntryList *l, Entry *e) {
  for (Entry *p = l->head; p; p = p->next) {
    if (strlen(p->name) == strlen(e->name) && strcmp(p->name, e->name) == 0) {
      return false;
    }
  }
  entrylistAppend(l, e);
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
  } else if (e == l->tail) {
    l->tail = prev;
  }
}

void entrylistDestroy(const Allocator *allocator, EntryList *l) {
  for (Entry *e = l->head; e;) {
    Entry *tmp = e->next;
    entryDestroy(allocator, e);
    e = tmp;
  }
  l->head = NULL;
  l->tail = NULL;
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
