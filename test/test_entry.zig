// Copyright (C) 2022 Daniel Forde - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.
//
// You should have received a copy of the MIT license with this file.
// If not, please write to: <daniel.forde001 at gmail dot com>,
// or visit: https://github.com/deforde/tmenu

const std = @import("std");
const Entry = @import("entry").Entry;
const EntryList = @import("entry").EntryList;

test "entry_create_destroy_2" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var e = try Entry.create(&allocator, "test");
    defer e.destroy();
}

test "entry_content_1" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var e = try Entry.create(&allocator, "test");
    defer e.destroy();

    try std.testing.expect(e.path != null);
    try std.testing.expect(e.name != null);
    try std.testing.expectEqualStrings("test", e.path.?);
    try std.testing.expectEqualStrings("test", e.name.?);
}

test "entry_content_2" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var e = try Entry.create(&allocator, "/path/to/test");
    defer e.destroy();

    try std.testing.expect(e.path != null);
    try std.testing.expect(e.name != null);
    try std.testing.expectEqualStrings("/path/to/test", e.path.?);
    try std.testing.expectEqualStrings("test", e.name.?);
}

test "entry_list_append" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var e1 = try Entry.create(&allocator, "/path/to/test1");

    var e2 = try Entry.create(&allocator, "/other/path/to/test2");

    var l = EntryList{};
    defer l.destroy();

    l.append(e1);

    try std.testing.expectEqual(@as(usize, 1), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.head.?.path != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.head == l.tail);
    try std.testing.expectEqualStrings("/path/to/test1", l.head.?.path.?);
    try std.testing.expectEqualStrings("test1", l.head.?.name.?);

    l.append(e2);

    try std.testing.expectEqual(@as(usize, 2), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.head.?.path != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.tail != null);
    try std.testing.expect(l.tail.?.path != null);
    try std.testing.expect(l.tail.?.name != null);
    try std.testing.expect(l.head != l.tail);
    try std.testing.expectEqualStrings("/path/to/test1", l.head.?.path.?);
    try std.testing.expectEqualStrings("test1", l.head.?.name.?);
    try std.testing.expectEqualStrings("/other/path/to/test2", l.tail.?.path.?);
    try std.testing.expectEqualStrings("test2", l.tail.?.name.?);
}

test "entry_list_append_remove_1" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var e1 = try Entry.create(&allocator, "/path/to/test1");
    defer e1.destroy();

    var e2 = try Entry.create(&allocator, "/other/path/to/test2");
    defer e2.destroy();

    var l = EntryList{};
    defer l.destroy();

    l.append(e1);

    try std.testing.expectEqual(@as(usize, 1), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.head.?.path != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.head == l.tail);
    try std.testing.expectEqualStrings("/path/to/test1", l.head.?.path.?);
    try std.testing.expectEqualStrings("test1", l.head.?.name.?);

    l.append(e2);

    try std.testing.expectEqual(@as(usize, 2), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.head.?.path != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.tail != null);
    try std.testing.expect(l.tail.?.path != null);
    try std.testing.expect(l.tail.?.name != null);
    try std.testing.expect(l.head != l.tail);
    try std.testing.expectEqualStrings("/path/to/test1", l.head.?.path.?);
    try std.testing.expectEqualStrings("test1", l.head.?.name.?);
    try std.testing.expectEqualStrings("/other/path/to/test2", l.tail.?.path.?);
    try std.testing.expectEqualStrings("test2", l.tail.?.name.?);

    l.remove(e2);

    try std.testing.expectEqual(@as(usize, 1), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.head.?.path != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.head == l.tail);
    try std.testing.expectEqualStrings("/path/to/test1", l.head.?.path.?);
    try std.testing.expectEqualStrings("test1", l.head.?.name.?);

    l.remove(e1);

    try std.testing.expectEqual(@as(usize, 0), l.len);
    try std.testing.expect(l.head == null);
    try std.testing.expect(l.tail == null);
}

test "entry_list_append_remove_2" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var e1 = try Entry.create(&allocator, "/path/to/test1");
    defer e1.destroy();

    var e2 = try Entry.create(&allocator, "/other/path/to/test2");
    defer e2.destroy();

    var l = EntryList{};
    defer l.destroy();

    l.append(e1);

    try std.testing.expectEqual(@as(usize, 1), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.head.?.path != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.head == l.tail);
    try std.testing.expectEqualStrings("/path/to/test1", l.head.?.path.?);
    try std.testing.expectEqualStrings("test1", l.head.?.name.?);

    l.append(e2);

    try std.testing.expectEqual(@as(usize, 2), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.head.?.path != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.tail != null);
    try std.testing.expect(l.tail.?.path != null);
    try std.testing.expect(l.tail.?.name != null);
    try std.testing.expect(l.head != l.tail);
    try std.testing.expectEqualStrings("/path/to/test1", l.head.?.path.?);
    try std.testing.expectEqualStrings("test1", l.head.?.name.?);
    try std.testing.expectEqualStrings("/other/path/to/test2", l.tail.?.path.?);
    try std.testing.expectEqualStrings("test2", l.tail.?.name.?);

    l.remove(e1);

    try std.testing.expectEqual(@as(usize, 1), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.head.?.path != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.head == l.tail);
    try std.testing.expectEqualStrings("/other/path/to/test2", l.tail.?.path.?);
    try std.testing.expectEqualStrings("test2", l.tail.?.name.?);

    l.remove(e2);

    try std.testing.expectEqual(@as(usize, 0), l.len);
    try std.testing.expect(l.head == null);
    try std.testing.expect(l.tail == null);
}

test "entry_list_append_remove_3" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var e1 = try Entry.create(&allocator, "/path/to/test1");

    var e2 = try Entry.create(&allocator, "/other/path/to/test2");
    defer e2.destroy();

    var e3 = try Entry.create(&allocator, "/yet/another/path/to/test3");

    var l = EntryList{};
    defer l.destroy();

    l.append(e1);

    try std.testing.expectEqual(@as(usize, 1), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.head.?.path != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.head == l.tail);
    try std.testing.expectEqualStrings("/path/to/test1", l.head.?.path.?);
    try std.testing.expectEqualStrings("test1", l.head.?.name.?);

    l.append(e2);

    try std.testing.expectEqual(@as(usize, 2), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.head.?.path != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.tail != null);
    try std.testing.expect(l.tail.?.path != null);
    try std.testing.expect(l.tail.?.name != null);
    try std.testing.expect(l.head != l.tail);
    try std.testing.expectEqualStrings("/path/to/test1", l.head.?.path.?);
    try std.testing.expectEqualStrings("test1", l.head.?.name.?);
    try std.testing.expectEqualStrings("/other/path/to/test2", l.tail.?.path.?);
    try std.testing.expectEqualStrings("test2", l.tail.?.name.?);

    l.append(e3);

    try std.testing.expectEqual(@as(usize, 3), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.head.?.path != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.tail != null);
    try std.testing.expect(l.tail.?.path != null);
    try std.testing.expect(l.tail.?.name != null);
    try std.testing.expect(l.head != l.tail);
    try std.testing.expectEqualStrings("/path/to/test1", l.head.?.path.?);
    try std.testing.expectEqualStrings("test1", l.head.?.name.?);
    try std.testing.expectEqualStrings("/yet/another/path/to/test3", l.tail.?.path.?);
    try std.testing.expectEqualStrings("test3", l.tail.?.name.?);

    l.remove(e2);

    try std.testing.expectEqual(@as(usize, 2), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.head.?.path != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.tail != null);
    try std.testing.expect(l.tail.?.path != null);
    try std.testing.expect(l.tail.?.name != null);
    try std.testing.expect(l.head != l.tail);
    try std.testing.expectEqualStrings("/path/to/test1", l.head.?.path.?);
    try std.testing.expectEqualStrings("test1", l.head.?.name.?);
    try std.testing.expectEqualStrings("/yet/another/path/to/test3", l.tail.?.path.?);
    try std.testing.expectEqualStrings("test3", l.tail.?.name.?);
}

test "entry_list_append_unique" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var e1 = try Entry.create(&allocator, "/path/to/test1");

    var e2 = try Entry.create(&allocator, "/other/path/to/test1");
    defer e2.destroy();

    var l = EntryList{};
    defer l.destroy();

    var res = l.appendUnique(e1);

    try std.testing.expect(res);
    try std.testing.expectEqual(@as(usize, 1), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.head.?.path != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.head == l.tail);
    try std.testing.expectEqualStrings("/path/to/test1", l.head.?.path.?);
    try std.testing.expectEqualStrings("test1", l.head.?.name.?);

    res = l.appendUnique(e2);

    try std.testing.expect(!res);
    try std.testing.expectEqual(@as(usize, 1), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.head.?.path != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.head == l.tail);
    try std.testing.expectEqualStrings("/path/to/test1", l.head.?.path.?);
    try std.testing.expectEqualStrings("test1", l.head.?.name.?);
}

test "entry_list_extend" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var e1 = try Entry.create(&allocator, "/path/to/test1");
    var e2 = try Entry.create(&allocator, "/other/path/to/test2");
    var e3 = try Entry.create(&allocator, "/yet/another/path/to/test3");
    var e4 = try Entry.create(&allocator, "/running/out/of/ideas/test4");

    var l = EntryList{};
    defer l.destroy();

    var m = EntryList{};

    l.append(e1);
    try std.testing.expectEqual(@as(usize, 1), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.head.?.path != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.head == l.tail);
    try std.testing.expectEqualStrings("/path/to/test1", l.head.?.path.?);
    try std.testing.expectEqualStrings("test1", l.head.?.name.?);

    l.append(e2);
    try std.testing.expectEqual(@as(usize, 2), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.head.?.path != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.tail != null);
    try std.testing.expect(l.tail.?.path != null);
    try std.testing.expect(l.tail.?.name != null);
    try std.testing.expect(l.head != l.tail);
    try std.testing.expectEqualStrings("/path/to/test1", l.head.?.path.?);
    try std.testing.expectEqualStrings("test1", l.head.?.name.?);
    try std.testing.expectEqualStrings("/other/path/to/test2", l.tail.?.path.?);
    try std.testing.expectEqualStrings("test2", l.tail.?.name.?);

    m.append(e3);
    m.append(e4);

    l.extend(m);
    try std.testing.expectEqual(@as(usize, 4), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.head.?.path != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.tail != null);
    try std.testing.expect(l.tail.?.path != null);
    try std.testing.expect(l.tail.?.name != null);
    try std.testing.expect(l.head != l.tail);
    try std.testing.expectEqualStrings("/path/to/test1", l.head.?.path.?);
    try std.testing.expectEqualStrings("test1", l.head.?.name.?);
    try std.testing.expectEqualStrings("/running/out/of/ideas/test4", l.tail.?.path.?);
    try std.testing.expectEqualStrings("test4", l.tail.?.name.?);
}

test "entry_list_filter" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var e1 = try Entry.create(&allocator, "/path/to/test1");
    var e2 = try Entry.create(&allocator, "/other/path/to/none2");
    var e3 = try Entry.create(&allocator, "/yet/another/path/to/test3");
    var e4 = try Entry.create(&allocator, "/running/out/of/ideas/none4");

    var l = EntryList{};
    defer l.destroy();

    _ = l.appendUnique(e1);
    _ = l.appendUnique(e2);
    _ = l.appendUnique(e3);
    _ = l.appendUnique(e4);

    var fout = EntryList{};

    l.filter(&fout, "test");

    try std.testing.expectEqual(@as(usize, 2), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.head.?.path != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.tail != null);
    try std.testing.expect(l.tail.?.path != null);
    try std.testing.expect(l.tail.?.name != null);
    try std.testing.expect(l.head != l.tail);
    try std.testing.expectEqualStrings("/path/to/test1", l.head.?.path.?);
    try std.testing.expectEqualStrings("test1", l.head.?.name.?);
    try std.testing.expectEqualStrings("/yet/another/path/to/test3", l.tail.?.path.?);
    try std.testing.expectEqualStrings("test3", l.tail.?.name.?);

    try std.testing.expectEqual(@as(usize, 2), fout.len);
    try std.testing.expect(fout.head != null);
    try std.testing.expect(fout.head.?.path != null);
    try std.testing.expect(fout.head.?.name != null);
    try std.testing.expect(fout.tail != null);
    try std.testing.expect(fout.tail.?.path != null);
    try std.testing.expect(fout.tail.?.name != null);
    try std.testing.expect(fout.head != fout.tail);
    try std.testing.expectEqualStrings("/other/path/to/none2", fout.head.?.path.?);
    try std.testing.expectEqualStrings("none2", fout.head.?.name.?);
    try std.testing.expectEqualStrings("/running/out/of/ideas/none4", fout.tail.?.path.?);
    try std.testing.expectEqualStrings("none4", fout.tail.?.name.?);

    l.extend(fout);
}

test "entry_list_sort" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit());

    var e1 = try Entry.create(&allocator, "abcd");
    var e2 = try Entry.create(&allocator, "efgh");
    var e3 = try Entry.create(&allocator, "ijkl");
    var e4 = try Entry.create(&allocator, "mnop");

    var l = EntryList{};
    defer l.destroy();

    _ = l.appendUnique(e3);
    _ = l.appendUnique(e2);
    _ = l.appendUnique(e4);
    _ = l.appendUnique(e1);

    l.sort();

    try std.testing.expectEqual(@as(usize, 4), l.len);
    try std.testing.expect(l.head != null);
    try std.testing.expect(l.tail != null);
    try std.testing.expect(l.head.?.name != null);
    try std.testing.expect(l.tail.?.name != null);
    try std.testing.expect(l.head != l.tail);
    try std.testing.expectEqualStrings("abcd", l.head.?.name.?);
    try std.testing.expectEqualStrings("efgh", l.head.?.next.?.name.?);
    try std.testing.expectEqualStrings("ijkl", l.tail.?.prev.?.name.?);
    try std.testing.expectEqualStrings("mnop", l.tail.?.name.?);
}
