/* Copyright (C) 2022 Daniel Forde - All Rights Reserved
 * You may use, distribute and modify this code under the
 * terms of the MIT license.
 *
 * You should have received a copy of the MIT license with this file.
 * If not, please write to: <daniel.forde001 at gmail dot com>,
 * or visit: https://github.com/deforde/tmenu
 */
#ifndef ENTRY_H
#define ENTRY_H

#include <stdbool.h>
#include <stddef.h>

#include "allocator.h"

typedef struct Entry Entry;
struct Entry {
  Entry *prev;
  Entry *next;
  char *name;
  char path[];
};

typedef struct EntryList {
  Entry *head;
  Entry *tail;
  size_t len;
} EntryList;

Entry *entryCreate(const Allocator *allocator, const char *s);
void entryDestroy(const Allocator *allocator, Entry *e);

EntryList entrylistInit(const Allocator *allocator);
void entrylistClear(EntryList *l);
void entrylistAppend(EntryList *l, Entry *e);
void entrylistExtend(EntryList *l, EntryList m);
void entrylistRemove(EntryList *l, Entry *e);
bool entrylistAppendUnique(EntryList *l, Entry *e);
void entrylistDestroy(const Allocator *allocator, EntryList *l);
void entrylistPrint(EntryList l);
void entrylistFilter(EntryList *l, EntryList *fout, const char *s);

#endif // ENTRY_H
