const std = @import("std");
const Allocator = std.mem.Allocator;

const c = @cImport({
    @cInclude("ctype.h");
    @cInclude("unistd.h");
    @cInclude("menu.h");
    @cInclude("ncurses.h");
});

const Entry = @import("entry.zig").Entry;
const EntryList = @import("entry.zig").EntryList;

fn buildItemList(entries: EntryList, allocator: Allocator) anyerror![]?*c.ITEM {
    var items = try allocator.alloc(?*c.ITEM, entries.len + 2);
    var i: usize = 0;
    var e = entries.head;
    while (e != null) : (e = e.?.next) {
        items[i] = c.new_item(e.?.name.?.ptr, null);
        _ = c.set_item_userptr(items[i], e.?);
        i += 1;
    }
    items[i] = c.new_item(" ", null);
    items[i + 1] = null;
    return items;
}

fn destroyItemList(items: []?*c.ITEM, allocator: Allocator) void {
    for (items) |item| {
        _ = c.free_item(item);
    }
    allocator.free(items);
}

fn updateItemList(entries: EntryList, allocator: Allocator, pitems: *[]?*c.ITEM, menu: *c.MENU) anyerror!void {
    var new_items = try buildItemList(entries, allocator);
    _ = c.unpost_menu(menu);
    _ = c.set_menu_items(menu, @ptrCast([*c][*c]c.ITEM, &new_items[0]));
    destroyItemList(pitems.*, allocator);
    pitems.* = new_items;
    _ = c.post_menu(menu);
}

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var entries = try EntryList.create(allocator);
    defer entries.destroy(allocator);

    var fout = EntryList{};
    defer fout.destroy(allocator);

    var efilter = [_]u8{0} ** std.os.PATH_MAX;
    var efilter_idx: usize = 0;

    _ = c.initscr();
    _ = c.cbreak();
    _ = c.noecho();
    _ = c.keypad(c.stdscr, true);

    var items = try buildItemList(entries, allocator);
    defer destroyItemList(items, allocator);

    var menu = c.new_menu(@ptrCast([*c][*c]c.ITEM, &items[0]));

    var nrows: c_int = c.getmaxy(c.stdscr);
    var ncols: c_int = c.getmaxx(c.stdscr);
    var nrows_win: c_int = nrows - 3;
    var ncols_win: c_int = ncols - 2;
    var win = c.newwin(nrows_win, ncols_win, 1, 2);
    _ = c.keypad(win, false);

    _ = c.set_menu_mark(menu, "");
    _ = c.set_menu_win(menu, win);
    _ = c.set_menu_sub(menu, c.derwin(win, nrows_win, ncols_win, 0, 0));
    _ = c.mvprintw(c.LINES - 2, 0, "F1 to exit");
    _ = c.move(0, 0);
    _ = c.refresh();

    _ = c.post_menu(menu);
    _ = c.wrefresh(win);

    var select: ?*Entry = null;
    var ch: c_int = 0;
    while (true) {
        ch = c.getch();
        switch (ch) {
            c.KEY_DOWN => {
                _ = c.menu_driver(menu, c.REQ_DOWN_ITEM);
            },
            c.KEY_UP => {
                _ = c.menu_driver(menu, c.REQ_UP_ITEM);
            },
            '\n' => {
                const usr_ptr = c.item_userptr(c.current_item(menu));
                if (usr_ptr != null) {
                    select = @ptrCast(*Entry, @alignCast(8, usr_ptr.?));
                }
                break;
            },
            c.KEY_BACKSPACE => {
                if (efilter_idx > 0) {
                    efilter_idx -= 1;
                    efilter[efilter_idx] = 0;
                    _ = c.move(0, @intCast(c_int, efilter_idx));
                    _ = c.clrtoeol();
                    entries.extend(fout);
                    fout.clear();
                    entries.filter(&fout, efilter[0..efilter_idx]);
                    try updateItemList(entries, allocator, &items, menu);
                }
            },
            c.KEY_F(1) => {
                break;
            },
            else => {
                if (c.isgraph(ch) != 0) {
                    _ = c.addch(@intCast(c_uint, ch));
                    efilter[efilter_idx] = @intCast(u8, ch);
                    efilter_idx += 1;
                    entries.filter(&fout, efilter[0..efilter_idx]);
                    try updateItemList(entries, allocator, &items, menu);
                }
            },
        }
        _ = c.wrefresh(win);
    }

    _ = c.unpost_menu(menu);
    _ = c.free_menu(menu);
    _ = c.endwin();

    if (select != null) {
        _ = c.execl(select.?.path.?.ptr, select.?.name.?.ptr, c.NULL);
    }
}
