#ifndef ENTRY_H
#define ENTRY_H

#include <stdbool.h>

#include "allocator.h"

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

Entry *entryCreate(const Allocator *allocator, const char *s);
void entryDestroy(const Allocator *allocator, Entry *e);

void entrylistAppend(EntryList *l, Entry *e);
void entrylistExtend(EntryList *l, EntryList m);
void entrylistRemove(EntryList *l, Entry *e);
bool entrylistAppendUnique(EntryList *l, Entry *e);
void entrylistDestroy(const Allocator *allocator, EntryList *l);
void entrylistPrint(EntryList l);
void entrylistFilter(EntryList *l, EntryList *fout, const char *s);

#endif // ENTRY_H
