/* Copyright (C) 2022 Daniel Forde - All Rights Reserved
 * You may use, distribute and modify this code under the
 * terms of the MIT license.
 *
 * You should have received a copy of the MIT license with this file.
 * If not, please write to: <daniel.forde001 at gmail dot com>,
 * or visit: https://github.com/deforde/tmenu
 */
#include <stdlib.h>
#include <string.h>

#include "allocator.h"
#include "entry.h"

int main(void) {
  EntryList entries = entrylistInit(DBG_ALLOCATOR);

  EntryList fout = {
      .head = NULL,
      .tail = NULL,
  };
  entrylistFilter(&entries, &fout, "gcc");

  entrylistPrint(entries);

  entrylistExtend(&entries, fout);
  fout.head = NULL;
  fout.tail = NULL;

  entrylistDestroy(DBG_ALLOCATOR, &entries);

  exit(EXIT_SUCCESS);
}
