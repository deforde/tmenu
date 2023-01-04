const std = @import("std");
const Allocator = std.mem.Allocator;

const c = @cImport({
    @cInclude("ctype.h");
    @cInclude("menu.h");
    @cInclude("ncurses.h");
});

const Entry = @import("entry.zig").Entry;
const EntryList = @import("entry.zig").EntryList;

const Menu = struct {
    ncmenu: *c.MENU,
    ncwin: *c.WINDOW,
    items: []?*c.ITEM,

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

    pub fn create(allocator: Allocator, entries: EntryList) anyerror!Menu {
        var items = try buildItemList(entries, allocator);

        _ = c.initscr();
        _ = c.cbreak();
        _ = c.noecho();
        _ = c.keypad(c.stdscr, true);

        var ncmenu = c.new_menu(@ptrCast([*c][*c]c.ITEM, &items[0]));

        var nrows: c_int = c.getmaxy(c.stdscr);
        var ncols: c_int = c.getmaxx(c.stdscr);
        var nrows_win: c_int = nrows - 3;
        var ncols_win: c_int = ncols - 2;
        var ncwin = c.newwin(nrows_win, ncols_win, 1, 2);
        _ = c.keypad(ncwin, false);

        _ = c.set_menu_mark(ncmenu, "");
        _ = c.set_menu_win(ncmenu, ncwin);
        _ = c.set_menu_sub(ncmenu, c.derwin(ncwin, nrows_win, ncols_win, 0, 0));
        _ = c.mvprintw(c.LINES - 2, 0, "F1 to exit");
        _ = c.move(0, 0);
        _ = c.refresh();

        _ = c.post_menu(ncmenu);
        _ = c.wrefresh(ncwin);

        return Menu{
            .ncmenu = ncmenu,
            .ncwin = ncwin,
            .items = items,
        };
    }

    pub fn destroy(self: *Menu, allocator: Allocator) void {
        _ = c.unpost_menu(self.ncmenu);
        _ = c.free_menu(self.ncmenu);
        _ = c.endwin();
        defer destroyItemList(self.items, allocator);
    }

    pub fn addChar(self: *Menu, ch: c_int) void {
        _ = self;
        _ = c.addch(@intCast(c_uint, ch));
    }

    pub fn deleteChar(self: *Menu) void {
        const x = c.getcurx(self.ncwin);
        if (x > 0) {
            _ = c.move(0, @intCast(c_int, x - 1));
            _ = c.clrtoeol();
        }
    }

    pub fn updateItemList(self: *Menu, allocator: Allocator, entries: EntryList) anyerror!void {
        var new_items = try buildItemList(entries, allocator);
        _ = c.unpost_menu(self.ncmenu);
        _ = c.set_menu_items(self.ncmenu, @ptrCast([*c][*c]c.ITEM, &new_items[0]));
        destroyItemList(self.items, allocator);
        self.items = new_items;
        _ = c.post_menu(self.ncmenu);
    }

    pub fn moveUp(self: *Menu) void {
        _ = c.menu_driver(self.ncmenu, c.REQ_UP_ITEM);
    }

    pub fn moveDown(self: *Menu) void {
        _ = c.menu_driver(self.ncmenu, c.REQ_DOWN_ITEM);
    }

    pub fn getCurrentSelection(self: *Menu) ?*Entry {
        const usr_ptr = c.item_userptr(c.current_item(self.ncmenu));
        if (usr_ptr != null) {
            return @ptrCast(*Entry, @alignCast(8, usr_ptr.?));
        }
        return null;
    }

    pub fn refresh(self: *Menu) void {
        _ = c.wrefresh(self.ncwin);
    }
};

pub fn runMenu(allocator: Allocator, entries: *EntryList) anyerror!?*Entry {
    var fout = EntryList{};
    defer {
        entries.extend(fout);
        fout.clear();
    }

    var efilter = [_]u8{0} ** std.os.PATH_MAX;
    var efilter_idx: usize = 0;

    var menu = try Menu.create(allocator, entries.*);
    defer menu.destroy(allocator);

    var ch: c_int = 0;
    while (true) {
        ch = c.getch();
        switch (ch) {
            c.KEY_DOWN => {
                menu.moveDown();
            },
            c.KEY_UP => {
                menu.moveUp();
            },
            '\n' => {
                return menu.getCurrentSelection();
            },
            c.KEY_BACKSPACE => {
                if (efilter_idx > 0) {
                    efilter_idx -= 1;
                    efilter[efilter_idx] = 0;
                    entries.extend(fout);
                    fout.clear();
                    entries.filter(&fout, efilter[0..efilter_idx]);
                    menu.deleteChar();
                    try menu.updateItemList(allocator, entries.*);
                }
            },
            c.KEY_F(1) => {
                break;
            },
            else => {
                if (c.isgraph(ch) != 0) {
                    efilter[efilter_idx] = @intCast(u8, ch);
                    efilter_idx += 1;
                    entries.filter(&fout, efilter[0..efilter_idx]);
                    menu.addChar(ch);
                    try menu.updateItemList(allocator, entries.*);
                }
            },
        }
        menu.refresh();
    }

    return null;
}
