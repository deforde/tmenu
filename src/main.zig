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
const runFullscreenMenu = @import("tui.zig").runFullscreenMenu;
const runLightMenu = @import("tui.zig").runLightMenu;

const c = @cImport({
    @cInclude("unistd.h");
});

const VER_MAJ: usize = 0;
const VER_MIN: usize = 1;
const VER_PATCH: usize = 0;

fn usage() !void {
    const usage_msg =
        \\Usage: tmenu [options]
        \\     Options:
        \\         -f, --fullscreen        Run in full screen tui mode.
        \\         -v, --version           Print the version number and exit.
        \\         -h, --help              Print this usage message and exit.
        \\
    ;
    const stdout = std.io.getStdOut().writer();
    try stdout.writeAll(usage_msg);
}

fn reportArgError(arg: []u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Unrecognised argument: \"{s}\"\n", .{arg});
    try usage();
}

fn printVersion() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{}.{}.{}\n", .{ VER_MAJ, VER_MIN, VER_PATCH });
}

pub fn main() !u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var fullscreen = false;

    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.startsWith(u8, arg, "-h")) {
            try usage();
            return 0;
        } else if (std.mem.eql(u8, arg, "--version") or std.mem.startsWith(u8, arg, "-v")) {
            try printVersion();
            return 0;
        } else if (std.mem.eql(u8, arg, "--fullscreen") or std.mem.startsWith(u8, arg, "-f")) {
            fullscreen = true;
        } else {
            try reportArgError(arg);
            return 1;
        }
    }

    var entries = try EntryList.create(&allocator);
    defer entries.destroy();

    const select = blk: {
        if (fullscreen) {
            break :blk try runFullscreenMenu(allocator, &entries);
        }
        break :blk try runLightMenu(&entries);
    };

    if (select != null) {
        _ = c.execl(select.?.path.?.ptr, select.?.name.?.ptr, c.NULL);
    }

    return 0;
}
