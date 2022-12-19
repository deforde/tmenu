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

#include <getopt.h>
#include <menu.h>
#include <ncurses.h>
#include <unistd.h>

static void usage(void) {
  puts("Usage: tmenu [options] <filter>\n"
       "Options:\n"
       "    -h         Display usage message.\n"
       "\n"
       "    filter     A string used to filter the application menu.");
}

int main(int argc, char *argv[]) {
  int opt = 0;
  struct option longopts[] = {{"help", no_argument, NULL, 'h'}, {0, 0, 0, 0}};
  while ((opt = getopt_long(argc, argv, "h", longopts, NULL)) != -1) {
    switch (opt) {
    case 'h':
      usage();
      exit(EXIT_SUCCESS);
    case '?':
    case ':':
    default:
      usage();
      exit(EXIT_FAILURE);
    }
  }
  if (optind >= argc) {
    usage();
    exit(EXIT_FAILURE);
  }

  const char *filter = argv[optind];

  EntryList entries = entrylistInit(DBG_ALLOCATOR);
  EntryList fout = {
      .head = NULL,
      .tail = NULL,
  };

  entrylistFilter(&entries, &fout, filter);

  initscr();
  cbreak();
  noecho();
  keypad(stdscr, TRUE);

  ITEM **items = calloc(entries.len + 1, sizeof(ITEM *));
  size_t i = 0;
  for (Entry *e = entries.head; e; e = e->next) {
    items[i] = new_item(e->name, NULL);
    set_item_userptr(items[i], e);
    i++;
  }
  items[i] = NULL;

  MENU *menu = new_menu(items);
  post_menu(menu);
  refresh();

  Entry *select = NULL;
  int c = 0;
  while ((c = getch()) != KEY_F(1)) {
    switch (c) {
    case KEY_DOWN:
      menu_driver(menu, REQ_DOWN_ITEM);
      break;
    case KEY_UP:
      menu_driver(menu, REQ_UP_ITEM);
      break;
    case '\n': {
      select = item_userptr(current_item(menu));
      goto end;
    }
    }
  }

end:
  entrylistExtend(&entries, fout);
  fout.head = NULL;
  fout.tail = NULL;
  entrylistDestroy(DBG_ALLOCATOR, &entries);

  for (size_t j = 0; j < entries.len; j++) {
    free_item(items[j]);
  }
  free_menu(menu);
  endwin();

  if (select) {
    execl(select->path, select->name, NULL);
  }

  exit(EXIT_SUCCESS);
}
