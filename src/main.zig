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
});

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var entries = try EntryList.create(&allocator);
    defer entries.destroy();

    const select = try runMenu(allocator, &entries);
    if (select != null) {
        _ = c.execl(select.?.path.?.ptr, select.?.name.?.ptr, c.NULL);
    }
}
