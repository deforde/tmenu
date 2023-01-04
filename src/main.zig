const std = @import("std");

const Entry = @import("entry.zig").Entry;
const EntryList = @import("entry.zig").EntryList;
const runMenu = @import("menu.zig").runMenu;

const c = @cImport({
    @cInclude("unistd.h");
});

pub fn main() anyerror!void {
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
