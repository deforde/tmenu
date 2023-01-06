// Copyright (C) 2022 Daniel Forde - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.
//
// You should have received a copy of the MIT license with this file.
// If not, please write to: <daniel.forde001 at gmail dot com>,
// or visit: https://github.com/deforde/tmenu

const std = @import("std");

const Entry = @import("entry.zig").Entry;
const EntryList = @import("entry.zig").EntryList;
const runMenu = @import("menu.zig").runMenu;

const c = @cImport({
    @cInclude("unistd.h");
    @cInclude("stdio.h");
    @cInclude("termios.h");
    @cInclude("ctype.h");
});

fn enableTermRaw() c.termios {
    var orig = c.termios{
        .c_iflag = 0,
        .c_oflag = 0,
        .c_cflag = 0,
        .c_lflag = 0,
        .c_line = 0,
        .c_cc = undefined,
        .c_ispeed = 0,
        .c_ospeed = 0,
    };
    _ = c.tcgetattr(c.STDIN_FILENO, &orig);

    var new = orig;
    new.c_iflag &= ~@intCast(c_uint, (c.IXON | c.ICRNL | c.BRKINT | c.INPCK | c.ISTRIP));
    new.c_oflag &= ~@intCast(c_uint, c.OPOST);
    new.c_cflag |= c.CS8;
    new.c_lflag &= ~@intCast(c_uint, (c.ECHO | c.ICANON | c.ISIG | c.IEXTEN));
    _ = c.tcsetattr(c.STDIN_FILENO, c.TCSAFLUSH, &new);

    return orig;
}

fn resetTerm(term: c.termios) void {
    _ = c.tcsetattr(c.STDIN_FILENO, c.TCSAFLUSH, &term);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var entries = try EntryList.create(&allocator);
    defer entries.destroy();

    // const select = try runMenu(allocator, &entries);
    // if (select != null) {
    //     _ = c.execl(select.?.path.?.ptr, select.?.name.?.ptr, c.NULL);
    // }

    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    var i: usize = 0;
    var e = entries.head;
    while (i < 10 and e != null) : (i += 1) {
        try stdout.print("{s}\r\n", .{e.?.name.?});
        e = e.?.next;
    }

    const orig = enableTermRaw();
    defer resetTerm(orig);

    // var buf: [*c]u8 = undefined;
    // _ = c.setvbuf(c.stdin, buf, c._IONBF, 128);
    var ch: u8 = 0;
    while (ch != 'q') : (ch = try stdin.readByte()) {
        if (c.isgraph(@intCast(c_int, ch)) != 0) {
            try stdout.print("you entered: {} ({c})\r\n", .{ ch, ch });
        } else {
            try stdout.print("you entered: {}\r\n", .{ch});
        }
        // try stdout.writeAll("you entered: ");
        // try stdout.writeAll(&[_]u8{ ch, '\r', '\n' });
    }
}
