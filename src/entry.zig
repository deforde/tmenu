// Copyright (C) 2022 Daniel Forde - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.
//
// You should have received a copy of the MIT license with this file.
// If not, please write to: <daniel.forde001 at gmail dot com>,
// or visit: https://github.com/deforde/tmenu

const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Entry = struct {
    prev: ?*Entry = null,
    next: ?*Entry = null,
    name: ?[:0]u8 = null,
    path: ?[:0]u8 = null,
    allocator: *const Allocator,

    pub fn create(allocator: *const Allocator, s: []const u8) !*Entry {
        var e = try allocator.create(Entry);
        e.* = Entry{ .allocator = allocator };
        e.path = try allocator.allocSentinel(u8, s.len, 0);
        std.mem.copy(u8, e.path.?, s);
        const pos = std.mem.lastIndexOf(u8, e.path.?, "/");
        if (pos != null) {
            e.name = e.path.?[pos.? + 1 ..];
        } else {
            e.name = e.path;
        }
        return e;
    }

    pub fn destroy(self: *Entry) void {
        if (self.path != null) {
            self.allocator.free(self.path.?);
        }
        self.allocator.destroy(self);
    }
};

pub const EntryList = struct {
    head: ?*Entry = null,
    tail: ?*Entry = null,
    len: usize = 0,

    pub fn append(self: *EntryList, e: *Entry) void {
        e.prev = self.tail;
        if (self.head == null) {
            self.head = e;
        }
        if (self.tail != null) {
            self.tail.?.next = e;
        }
        self.tail = e;
        self.len += 1;
    }

    pub fn remove(self: *EntryList, e: *Entry) void {
        var prev = e.prev;
        var next = e.next;
        if (prev != null) {
            prev.?.next = next;
        }
        if (next != null) {
            next.?.prev = prev;
        }
        e.prev = null;
        e.next = null;
        if (e == self.head) {
            self.head = next;
        }
        if (e == self.tail) {
            self.tail = prev;
        }
        self.len -= 1;
    }

    pub fn clear(self: *EntryList) void {
        self.head = null;
        self.tail = null;
        self.len = 0;
    }

    pub fn destroy(self: *EntryList) void {
        var e = self.head;
        while (e != null) {
            const tmp = e.?.next;
            e.?.destroy();
            e = tmp;
        }
        self.clear();
    }

    pub fn print(self: *EntryList) void {
        var e = self.head;
        while (e != null) : (e = e.?.next) {
            std.debug.print("{s}\n", .{e.?.name.?});
        }
    }

    pub fn appendUnique(self: *EntryList, e: *Entry) bool {
        var ext = self.head;
        while (ext != null) : (ext = ext.?.next) {
            if (std.mem.eql(u8, ext.?.name.?, e.name.?)) {
                return false;
            }
        }
        self.append(e);
        return true;
    }

    pub fn extend(self: *EntryList, l: EntryList) void {
        if (l.head == null or l.tail == null) {
            return;
        }
        self.append(l.head.?);
        self.tail = l.tail;
        self.len += l.len - 1;
    }

    pub fn filter(self: *EntryList, fout: *EntryList, s: []const u8) void {
        if (s.len == 0) {
            return;
        }
        var e = self.head;
        while (e != null) {
            const idx = std.mem.indexOf(u8, e.?.name.?, s);
            if (idx == null) {
                const tmp = e.?.next;
                self.remove(e.?);
                fout.append(e.?);
                e = tmp;
                continue;
            }
            e = e.?.next;
        }
    }

    pub fn create(allocator: *const Allocator) !EntryList {
        var l = EntryList{};

        const env_path = std.os.getenv("PATH").?;

        var dir_paths = std.mem.tokenize(u8, env_path, ":");
        while (dir_paths.next()) |dir_path| {
            var dir = std.fs.openIterableDirAbsolute(dir_path, .{}) catch continue;
            defer dir.close();
            var it = dir.iterate();
            while (try it.next()) |dir_entry| {
                if ((dir_entry.kind == std.fs.File.Kind.File or dir_entry.kind == std.fs.File.Kind.SymLink) and !std.mem.eql(u8, dir_entry.name, "tmenu")) {
                    const realpath = try std.fmt.allocPrint(allocator.*, "{s}/{s}", .{ dir_path, dir_entry.name });
                    defer allocator.free(realpath);
                    var file = std.fs.openFileAbsolute(realpath, .{}) catch continue;
                    defer file.close();
                    var fstat = try std.fs.File.stat(file);
                    if (fstat.mode & std.os.linux.S.IXUSR != 0) {
                        var e = try Entry.create(allocator, realpath);
                        if (!l.appendUnique(e)) {
                            e.destroy();
                        }
                    }
                }
            }
        }

        return l;
    }
};
