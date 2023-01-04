const std = @import("std");

const Entry = @import("entry.zig").Entry;
const EntryList = @import("entry.zig").EntryList;
const runMenu = @import("menu.zig").runMenu;

const c = @cImport({
    @cInclude("unistd.h");
});

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var entries = try EntryList.create(allocator);
    defer entries.destroy(allocator);

    const select = try runMenu(allocator, &entries);
    if (select != null) {
        _ = c.execl(select.?.path.?.ptr, select.?.name.?.ptr, c.NULL);
    }
}
