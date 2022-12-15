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

#include <dirent.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <ncurses.h>

#include "allocator.h"
#include "entry.h"

int main(void) {
  char *path = getenv("PATH");
  if (path == NULL) {
    printf("Failed to get the environment variable: 'PATH'\n");
    exit(EXIT_FAILURE);
  }

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
          Entry *e = entryCreate(DBG_ALLOCATOR, dent->d_name);
          if (e == NULL) {
            printf("Failed to allocate memory for entry\n");
            exit(EXIT_FAILURE);
          }
          if (!entrylistAppendUnique(&entries, e)) {
            entryDestroy(DBG_ALLOCATOR, e);
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
  entrylistFilter(&entries, &fout, "gcc");

  entrylistPrint(entries);

  entrylistExtend(&entries, fout);
  fout.head = NULL;
  fout.tail = NULL;

  entrylistDestroy(DBG_ALLOCATOR, &entries);

  exit(EXIT_SUCCESS);
}
