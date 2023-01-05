// Copyright (C) 2022 Daniel Forde - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.
//
// You should have received a copy of the MIT license with this file.
// If not, please write to: <daniel.forde001 at gmail dot com>,
// or visit: https://github.com/deforde/tmenu

const std = @import("std");
const Allocator = std.mem.Allocator;

const c = @cImport({
    @cInclude("ctype.h");
    @cInclude("menu.h");
    @cInclude("ncurses.h");
});

const Entry = @import("entry.zig").Entry;
const EntryList = @import("entry.zig").EntryList;

fn check(res: c_int) !void {
    if (res == c.ERR) {
        return error.CursesError;
    }
}

const Menu = struct {
    ncmenu: *c.MENU,
    ncwin: *c.WINDOW,
    items: []?*c.ITEM,
    allocator: *const Allocator,

    fn buildItemList(entries: EntryList, allocator: Allocator) ![]?*c.ITEM {
        var items = try allocator.alloc(?*c.ITEM, entries.len + 2);
        var i: usize = 0;
        var e = entries.head;
        while (e != null) : (e = e.?.next) {
            items[i] = c.new_item(e.?.name.?.ptr, null);
            try check(c.set_item_userptr(items[i], e.?));
            i += 1;
        }
        items[i] = c.new_item(" ", null);
        items[i + 1] = null;
        return items;
    }

    fn destroyItemList(items: []?*c.ITEM, allocator: Allocator) !void {
        for (items) |item| {
            try check(c.free_item(item));
        }
        allocator.free(items);
    }

    pub fn create(allocator: *const Allocator, entries: EntryList) !Menu {
        var items = try buildItemList(entries, allocator.*);

        _ = c.initscr();
        try check(c.cbreak());
        try check(c.noecho());
        try check(c.keypad(c.stdscr, true));

        var ncmenu = c.new_menu(@ptrCast([*c][*c]c.ITEM, &items[0]));

        var nrows: c_int = c.getmaxy(c.stdscr);
        var ncols: c_int = c.getmaxx(c.stdscr);
        var nrows_win: c_int = nrows - 3;
        var ncols_win: c_int = ncols - 2;
        var ncwin = c.newwin(nrows_win, ncols_win, 1, 2);
        try check(c.keypad(ncwin, false));

        try check(c.set_menu_mark(ncmenu, ""));
        try check(c.set_menu_win(ncmenu, ncwin));
        try check(c.set_menu_sub(ncmenu, c.derwin(ncwin, nrows_win, ncols_win, 0, 0)));
        try check(c.mvprintw(c.LINES - 2, 0, "F1 to exit"));
        try check(c.move(0, 0));
        try check(c.refresh());

        try check(c.post_menu(ncmenu));
        try check(c.wrefresh(ncwin));

        return Menu{
            .ncmenu = ncmenu,
            .ncwin = ncwin,
            .items = items,
            .allocator = allocator,
        };
    }

    pub fn destroy(self: *Menu) void {
        check(c.unpost_menu(self.ncmenu)) catch {};
        check(c.free_menu(self.ncmenu)) catch {};
        check(c.endwin()) catch {};
        destroyItemList(self.items, self.allocator.*) catch {};
    }

    pub fn addChar(self: *Menu, ch: c_int) !void {
        _ = self;
        try check(c.addch(@intCast(c_uint, ch)));
    }

    pub fn deleteChar(self: *Menu) !void {
        _ = self;
        const x = c.getcurx(c.stdscr);
        if (x > 0) {
            try check(c.move(0, @intCast(c_int, x - 1)));
            try check(c.clrtoeol());
        }
    }

    pub fn updateItemList(self: *Menu, entries: EntryList) !void {
        var new_items = try buildItemList(entries, self.allocator.*);
        try check(c.unpost_menu(self.ncmenu));
        try check(c.set_menu_items(self.ncmenu, @ptrCast([*c][*c]c.ITEM, &new_items[0])));
        try destroyItemList(self.items, self.allocator.*);
        self.items = new_items;
        try check(c.post_menu(self.ncmenu));
    }

    pub fn moveUp(self: *Menu) !void {
        try check(c.menu_driver(self.ncmenu, c.REQ_UP_ITEM));
    }

    pub fn moveDown(self: *Menu) !void {
        try check(c.menu_driver(self.ncmenu, c.REQ_DOWN_ITEM));
    }

    pub fn getCurrentSelection(self: *Menu) ?*Entry {
        const usr_ptr = c.item_userptr(c.current_item(self.ncmenu));
        if (usr_ptr != null) {
            return @ptrCast(*Entry, @alignCast(8, usr_ptr.?));
        }
        return null;
    }

    pub fn refresh(self: *Menu) !void {
        try check(c.wrefresh(self.ncwin));
    }
};

pub fn runMenu(allocator: Allocator, entries: *EntryList) !?*Entry {
    var fout = EntryList{};
    defer {
        entries.extend(fout);
        fout.clear();
    }

    var efilter = [_]u8{0} ** std.os.PATH_MAX;
    var efilter_idx: usize = 0;

    var menu = try Menu.create(&allocator, entries.*);
    defer menu.destroy();

    var ch: c_int = 0;
    while (true) {
        ch = c.getch();
        switch (ch) {
            c.KEY_DOWN => {
                try menu.moveDown();
            },
            c.KEY_UP => {
                try menu.moveUp();
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
                    entries.sort();
                    try menu.deleteChar();
                    try menu.updateItemList(entries.*);
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
                    entries.sort();
                    try menu.addChar(ch);
                    try menu.updateItemList(entries.*);
                }
            },
        }
        try menu.refresh();
    }

    return null;
}
