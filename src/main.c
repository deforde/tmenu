/* Copyright (C) 2022 Daniel Forde - All Rights Reserved
 * You may use, distribute and modify this code under the
 * terms of the MIT license.
 *
 * You should have received a copy of the MIT license with this file.
 * If not, please write to: <daniel.forde001 at gmail dot com>,
 * or visit: https://github.com/deforde/tmenu
 */
#include <assert.h>
#include <ctype.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

#include "allocator.h"
#include "entry.h"

#include <getopt.h>
#include <linux/limits.h>
#include <menu.h>
#include <ncurses.h>
#include <unistd.h>

static void usage(void) {
  puts("Usage: tmenu [options]\n"
       "Options:\n"
       "    -h         Display usage message.");
}

static void buildItemList(ITEM ***pitems, EntryList entries) {
  ITEM **items = *pitems;
  ITEM **tmp = realloc(items, (entries.len + 1) * sizeof(ITEM *));
  assert(tmp); // TODO: error checking
  items = tmp;
  size_t i = 0;
  for (Entry *e = entries.head; e; e = e->next) {
    items[i] = new_item(e->name, NULL);
    set_item_userptr(items[i], e);
    i++;
  }
  items[i] = NULL;
  *pitems = items;
}

static void destroyItemList(ITEM **items) {
  for (size_t i = 0; items[i]; i++) {
    free_item(items[i]);
  }
  free(items);
}

static void updateItemList(EntryList entries, ITEM ***pitems, MENU *menu) {
  ITEM **new_items = NULL;
  buildItemList(&new_items, entries);
  unpost_menu(menu);
  set_menu_items(menu, new_items);
  destroyItemList(*pitems);
  *pitems = new_items;
  post_menu(menu);
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

  char filter[PATH_MAX] = {0};
  size_t filter_idx = 0;

  EntryList entries = entrylistInit(DBG_ALLOCATOR);
  EntryList fout = {
      .head = NULL,
      .tail = NULL,
  };

  initscr();
  cbreak();
  noecho();
  keypad(stdscr, true);

  int nrows = 0;
  int ncols = 0;
  getmaxyx(stdscr, nrows, ncols);

  ITEM **items = NULL;
  buildItemList(&items, entries);

  MENU *menu = new_menu(items);

  int nrows_win = nrows - 3;
  int ncols_win = ncols - 2;
  WINDOW *win = newwin(nrows_win, ncols_win, 1, 2);
  keypad(win, true);

  set_menu_mark(menu, "");
  set_menu_win(menu, win);
  set_menu_sub(menu, derwin(win, nrows_win, ncols_win, 0, 0));
  mvprintw(LINES - 2, 0, "q to exit");
  move(0, 0);
  refresh();

  post_menu(menu);
  wrefresh(win);

  Entry *select = NULL;
  int c = 0;
  while ((c = getch()) != 'q') {
    switch (c) {
    case KEY_DOWN:
      menu_driver(menu, REQ_DOWN_ITEM);
      break;
    case KEY_UP:
      menu_driver(menu, REQ_UP_ITEM);
      break;
    case '\n':
      select = item_userptr(current_item(menu));
      goto end;
    case KEY_BACKSPACE:
      if (filter_idx > 0) {
        filter[--filter_idx] = 0;
        move(0, filter_idx);
        clrtoeol();
        entrylistExtend(&entries, fout);
        entrylistClear(&fout);
        entrylistFilter(&entries, &fout, filter);
        updateItemList(entries, &items, menu);
      }
      break;
    default:
      if (isgraph(c)) {
        addch(c);
        filter[filter_idx++] = (char)c;
        entrylistFilter(&entries, &fout, filter);
        updateItemList(entries, &items, menu);
      }
      break;
    }
    wrefresh(win);
  }

end:
  unpost_menu(menu);
  free_menu(menu);
  destroyItemList(items);
  endwin();

  if (select) {
    execl(select->path, select->name, NULL);
  }

  entrylistExtend(&entries, fout);
  fout.head = NULL;
  fout.tail = NULL;
  entrylistDestroy(DBG_ALLOCATOR, &entries);

  exit(EXIT_SUCCESS);
}
