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
    @cInclude("stdio.h");
    @cInclude("termios.h");
    @cInclude("unistd.h");
});

const Entry = @import("entry.zig").Entry;
const EntryList = @import("entry.zig").EntryList;

fn check(res: c_int) !void {
    if (res == c.ERR) {
        return error.CursesError;
    }
}

const FullscreenMenu = struct {
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

    pub fn create(allocator: *const Allocator, entries: EntryList) !FullscreenMenu {
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

        return FullscreenMenu{
            .ncmenu = ncmenu,
            .ncwin = ncwin,
            .items = items,
            .allocator = allocator,
        };
    }

    pub fn destroy(self: *FullscreenMenu) void {
        check(c.unpost_menu(self.ncmenu)) catch {};
        check(c.free_menu(self.ncmenu)) catch {};
        check(c.endwin()) catch {};
        destroyItemList(self.items, self.allocator.*) catch {};
    }

    pub fn addChar(self: *FullscreenMenu, ch: c_int) !void {
        _ = self;
        try check(c.addch(@intCast(c_uint, ch)));
    }

    pub fn deleteChar(self: *FullscreenMenu) !void {
        _ = self;
        const x = c.getcurx(c.stdscr);
        if (x > 0) {
            try check(c.move(0, @intCast(c_int, x - 1)));
            try check(c.clrtoeol());
        }
    }

    pub fn updateItemList(self: *FullscreenMenu, entries: EntryList) !void {
        var new_items = try buildItemList(entries, self.allocator.*);
        try check(c.unpost_menu(self.ncmenu));
        try check(c.set_menu_items(self.ncmenu, @ptrCast([*c][*c]c.ITEM, &new_items[0])));
        try destroyItemList(self.items, self.allocator.*);
        self.items = new_items;
        try check(c.post_menu(self.ncmenu));
    }

    pub fn moveUp(self: *FullscreenMenu) !void {
        try check(c.menu_driver(self.ncmenu, c.REQ_UP_ITEM));
    }

    pub fn moveDown(self: *FullscreenMenu) !void {
        try check(c.menu_driver(self.ncmenu, c.REQ_DOWN_ITEM));
    }

    pub fn getCurrentSelection(self: *FullscreenMenu) ?*Entry {
        const usr_ptr = c.item_userptr(c.current_item(self.ncmenu));
        if (usr_ptr != null) {
            return @ptrCast(*Entry, @alignCast(8, usr_ptr.?));
        }
        return null;
    }

    pub fn refresh(self: *FullscreenMenu) !void {
        try check(c.wrefresh(self.ncwin));
    }
};

pub fn runFullscreenMenu(allocator: Allocator, entries: *EntryList) !?*Entry {
    var fout = EntryList{};
    defer {
        entries.extend(fout);
        fout.clear();
    }

    var efilter = [_]u8{0} ** std.os.PATH_MAX;
    var efilter_idx: usize = 0;

    var menu = try FullscreenMenu.create(&allocator, entries.*);
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

const LightMenu = struct {
    term: c.termios,
    stdin: std.fs.File.Reader,
    stdout: std.fs.File.Writer,
    height: usize = 10,
    orig_x: usize = 1,
    orig_y: usize = 1,

    fn enableTermRaw() c.termios {
        var term = c.termios{
            .c_iflag = 0,
            .c_oflag = 0,
            .c_cflag = 0,
            .c_lflag = 0,
            .c_line = 0,
            .c_cc = undefined,
            .c_ispeed = 0,
            .c_ospeed = 0,
        };
        _ = c.tcgetattr(c.STDIN_FILENO, &term);

        var new = term;
        new.c_iflag &= ~@intCast(c_uint, (c.IXON | c.ICRNL | c.BRKINT | c.INPCK | c.ISTRIP));
        new.c_oflag &= ~@intCast(c_uint, c.OPOST);
        new.c_cflag |= c.CS8;
        new.c_lflag &= ~@intCast(c_uint, (c.ECHO | c.ICANON | c.ISIG | c.IEXTEN));
        _ = c.tcsetattr(c.STDIN_FILENO, c.TCSAFLUSH, &new);

        return term;
    }

    fn resetTerm(term: c.termios) void {
        _ = c.tcsetattr(c.STDIN_FILENO, c.TCSAFLUSH, &term);
    }

    pub fn create() !LightMenu {
        const stdin = std.io.getStdIn().reader();
        const stdout = std.io.getStdOut().writer();
        const term = enableTermRaw();

        const height: usize = 10;
        var i: usize = 0;
        while (i < height) : (i += 1) {
            try stdout.writeAll("\r\n");
        }

        var ch: u8 = 0;
        try stdout.writeAll("\x1b[6n");
        ch = try stdin.readByte();
        std.debug.assert(ch == 27);
        ch = try stdin.readByte();
        std.debug.assert(ch == '[');
        var tmp = [_]u8{0} ** 128;
        var tmp_idx: usize = 0;
        while (ch != ';') {
            ch = try stdin.readByte();
            tmp[tmp_idx] = ch;
            tmp_idx += 1;
        }
        const orig_y = try std.fmt.parseInt(usize, tmp[0 .. tmp_idx - 1], 10) - height;
        tmp_idx = 0;
        while (ch != 'R') {
            ch = try stdin.readByte();
            tmp[tmp_idx] = ch;
            tmp_idx += 1;
        }
        const orig_x = try std.fmt.parseInt(usize, tmp[0 .. tmp_idx - 1], 10);

        return LightMenu{
            .term = term,
            .stdin = stdin,
            .stdout = stdout,
            .orig_x = orig_x,
            .orig_y = orig_y,
        };
    }

    pub fn destroy(self: *LightMenu) void {
        resetTerm(self.term);
    }

    pub fn clearScreen(self: *LightMenu) !void {
        var tmp = [_]u8{0} ** 128;
        try self.stdout.writeAll(try std.fmt.bufPrint(&tmp, "\x1b[{};{}H", .{ self.orig_y, self.orig_x }));
        try self.stdout.writeAll("\x1b[J");
    }

    pub fn render(self: *LightMenu, entry: ?*Entry, sel_y: usize, efilter: []u8) !void {
        var i: usize = 0;
        var e = entry;
        while (i < self.height) : (i += 1) {
            if (e != null) {
                const is_sel = i == (sel_y - self.orig_y);
                try self.stdout.writeAll("    ");
                if (is_sel) {
                    try self.stdout.writeAll("\x1b[47;30m");
                }
                try self.stdout.print("{s}", .{e.?.name.?});
                if (is_sel) {
                    try self.stdout.writeAll("\x1b[0m");
                }
                e = e.?.next;
            }
            try self.newline();
        }
        try self.stdout.print("\r{s}", .{efilter});
    }

    pub fn readByte(self: *LightMenu) !u8 {
        return try self.stdin.readByte();
    }

    pub fn newline(self: *LightMenu) !void {
        try self.stdout.writeAll("\r\n");
    }

    fn updateSel(self: *LightMenu, cur_head: ?*Entry, sel_y: usize) ?*Entry {
        var pos = sel_y - self.orig_y;
        var i: usize = 0;
        var e = cur_head;
        while (i < pos and e != null) {
            e = e.?.next;
            i += 1;
        }
        return e;
    }

    pub fn run(self: *LightMenu, entries: *EntryList) !?*Entry {
        var fout = EntryList{};
        defer {
            entries.extend(fout);
            fout.clear();
        }

        var efilter = [_]u8{0} ** std.os.PATH_MAX;
        var efilter_idx: usize = 0;

        var cur_head = entries.head;
        var cur_sel = cur_head;
        var sel_y = self.orig_y;

        var ch: u8 = 0;
        while (true) {
            try self.clearScreen();
            try self.render(cur_head, sel_y, efilter[0..efilter_idx]);

            ch = try self.readByte();

            switch (ch) {
                @enumToInt(KEYS.ENT) => {
                    return cur_sel;
                },
                @enumToInt(KEYS.ESC) => {
                    var esc_seq: u16 = 0;
                    var j: u4 = 0;
                    while (j < 2) : (j += 1) {
                        esc_seq |= @intCast(u16, try self.readByte()) << ((1 - j) * 8);
                    }
                    switch (esc_seq) {
                        @enumToInt(KEYS.F1) => {
                            try self.newline();
                            return null;
                        },
                        @enumToInt(KEYS.UP) => {
                            if (sel_y != self.orig_y and cur_sel != null and cur_sel.?.prev != null) {
                                cur_sel = cur_sel.?.prev.?;
                                sel_y -= 1;
                            } else if (cur_head != null and cur_head.?.prev != null) {
                                cur_head = cur_head.?.prev;
                                cur_sel = cur_sel.?.prev.?;
                            }
                        },
                        @enumToInt(KEYS.DWN) => {
                            if (sel_y != (self.orig_y + self.height - 1) and cur_sel.?.next != null) {
                                cur_sel = cur_sel.?.next.?;
                                sel_y += 1;
                            } else if (cur_head != null) {
                                var rem_depth: usize = 0;
                                var e = cur_head;
                                while (e.?.next != null) : (e = e.?.next) {
                                    rem_depth += 1;
                                }
                                if (rem_depth > self.height) {
                                    cur_head = cur_head.?.next;
                                    cur_sel = self.updateSel(cur_head, sel_y);
                                }
                            }
                        },
                        else => {
                            // try self.stdout.print("\r\nunknown escape sequence: {}\r\n", .{esc_seq});
                        },
                    }
                },
                @enumToInt(KEYS.BKSPC) => {
                    if (efilter_idx > 0) {
                        efilter_idx -= 1;
                        efilter[efilter_idx] = 0;
                        entries.extend(fout);
                        fout.clear();
                        entries.filter(&fout, efilter[0..efilter_idx]);
                        entries.sort();
                        cur_head = entries.head;
                        cur_sel = self.updateSel(cur_head, sel_y);
                    }
                },
                else => {
                    if (c.isgraph(@intCast(c_int, ch)) != 0) {
                        efilter[efilter_idx] = @intCast(u8, ch);
                        efilter_idx += 1;
                        entries.filter(&fout, efilter[0..efilter_idx]);
                        entries.sort();
                        cur_head = entries.head;
                        if (sel_y >= (self.orig_y + self.height)) {
                            sel_y = self.orig_y + self.height - 1;
                        }
                        cur_sel = self.updateSel(cur_head, sel_y);
                    }
                    // else {
                    //     try self.stdout.print("\r\nunknown char: {}\r\n", .{ch});
                    // }
                },
            }

            // if (c.isgraph(@intCast(c_int, ch)) != 0) {
            //     try stdout.print("you entered: {} ({c})\r\n", .{ ch, ch });
            // } else {
            //     try stdout.print("you entered: {}\r\n", .{ch});
            // }
            // try stdout.writeAll("you entered: ");
            // try stdout.writeAll(&[_]u8{ ch, '\r', '\n' });
        }

        return cur_sel;
    }
};

const KEYS = enum(u16) {
    ENT = 13,
    ESC = 27,
    F1 = 20304,
    BKSPC = 127,
    UP = 23361,
    DWN = 23362,
};

pub fn runLightMenu(entries: *EntryList) !?*Entry {
    var menu = try LightMenu.create();
    defer menu.destroy();
    return menu.run(entries);
}
