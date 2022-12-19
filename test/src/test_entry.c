#include "test_entry.h"

#include <unity.h>

#include "entry.h"

void testEntryBasic(void) {
  EntryList entries = {
      .head = NULL,
      .tail = NULL,
  };

  Entry *e = entryCreate(DBG_ALLOCATOR, "test_name");
  TEST_ASSERT_NOT_NULL(e);
  TEST_ASSERT(entrylistAppendUnique(&entries, e));
  TEST_ASSERT_EQUAL_PTR(entries.head, entries.tail);
  TEST_ASSERT_EQUAL_STRING(entries.head->name, "test_name");
  entrylistDestroy(DBG_ALLOCATOR, &entries);

  e = entryCreate(DBG_ALLOCATOR, "test_name_1");
  TEST_ASSERT_NOT_NULL(e);
  TEST_ASSERT(entrylistAppendUnique(&entries, e));

  e = entryCreate(DBG_ALLOCATOR, "test_name_2");
  Entry *tmp = e;
  TEST_ASSERT_NOT_NULL(e);
  TEST_ASSERT(entrylistAppendUnique(&entries, e));
  TEST_ASSERT_NOT_EQUAL(entries.head, entries.tail);
  TEST_ASSERT_EQUAL_STRING(entries.head->name, "test_name_1");
  TEST_ASSERT_EQUAL_STRING(entries.tail->name, "test_name_2");
  TEST_ASSERT_EQUAL_PTR(entries.head->next, entries.tail);
  TEST_ASSERT_EQUAL_PTR(entries.tail->prev, entries.head);

  e = entryCreate(DBG_ALLOCATOR, "test_name_3");
  TEST_ASSERT_NOT_NULL(e);
  TEST_ASSERT(entrylistAppendUnique(&entries, e));
  TEST_ASSERT_EQUAL_STRING(entries.tail->name, "test_name_3");
  TEST_ASSERT_EQUAL_PTR(entries.head->next->next, entries.tail);

  e = entryCreate(DBG_ALLOCATOR, "test_name_2");
  TEST_ASSERT_NOT_NULL(e);
  TEST_ASSERT(!entrylistAppendUnique(&entries, e));
  entryDestroy(DBG_ALLOCATOR, e);

  entrylistRemove(&entries, tmp);
  TEST_ASSERT_NOT_EQUAL(entries.head, entries.tail);
  TEST_ASSERT_EQUAL_STRING(entries.head->name, "test_name_1");
  TEST_ASSERT_EQUAL_STRING(entries.tail->name, "test_name_3");
  TEST_ASSERT_EQUAL_PTR(entries.head->next, entries.tail);
  TEST_ASSERT_EQUAL_PTR(entries.tail->prev, entries.head);
  entrylistRemove(&entries, tmp);
  entryDestroy(DBG_ALLOCATOR, tmp);

  entrylistDestroy(DBG_ALLOCATOR, &entries);
  TEST_ASSERT_EQUAL_PTR(entries.head, NULL);
  TEST_ASSERT_EQUAL_PTR(entries.tail, NULL);

  Entry *arr[] = {NULL, NULL, NULL};
  arr[0] = entryCreate(DBG_ALLOCATOR, "test_name_1");
  TEST_ASSERT_NOT_NULL(arr[0]);
  TEST_ASSERT(entrylistAppendUnique(&entries, arr[0]));

  arr[1] = entryCreate(DBG_ALLOCATOR, "test_name_2");
  TEST_ASSERT_NOT_NULL(arr[1]);
  TEST_ASSERT(entrylistAppendUnique(&entries, arr[1]));

  arr[2] = entryCreate(DBG_ALLOCATOR, "test_name_3");
  TEST_ASSERT_NOT_NULL(arr[2]);
  TEST_ASSERT(entrylistAppendUnique(&entries, arr[2]));

  entrylistRemove(&entries, arr[1]);
  entrylistRemove(&entries, arr[0]);
  entrylistRemove(&entries, arr[2]);
  TEST_ASSERT_EQUAL_PTR(entries.head, NULL);
  TEST_ASSERT_EQUAL_PTR(entries.tail, NULL);

  TEST_ASSERT(entrylistAppendUnique(&entries, arr[0]));
  TEST_ASSERT(entrylistAppendUnique(&entries, arr[1]));
  TEST_ASSERT(entrylistAppendUnique(&entries, arr[2]));

  EntryList fout = {
    .head = NULL,
    .tail = NULL,
  };
  entrylistFilter(&entries, &fout, "name_3");
  TEST_ASSERT_EQUAL_PTR(entries.head, entries.tail);
  TEST_ASSERT_EQUAL_STRING(entries.head->name, "test_name_3");
  TEST_ASSERT_NOT_EQUAL(fout.head, fout.tail);
  TEST_ASSERT_EQUAL_STRING(fout.head->name, "test_name_1");
  TEST_ASSERT_EQUAL_STRING(fout.tail->name, "test_name_2");
  TEST_ASSERT_EQUAL_PTR(fout.head->next, fout.tail);
  TEST_ASSERT_EQUAL_PTR(fout.tail->prev, fout.head);

  entrylistExtend(&entries, fout);
  TEST_ASSERT_EQUAL_STRING(entries.tail->name, "test_name_2");

  entrylistDestroy(DBG_ALLOCATOR, &entries);
}
