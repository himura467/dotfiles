const std = @import("std");

pub fn getFavorites(allocator: std.mem.Allocator, dir: std.fs.Dir, favorites_file: []const u8) !std.ArrayList([]const u8) {
    const file = try dir.openFile(favorites_file, .{});
    defer file.close();

    var favorites = std.ArrayList([]const u8){};
    errdefer {
        for (favorites.items) |item| allocator.free(item);
        favorites.deinit(allocator);
    }

    var buf: [4096]u8 = undefined;
    var r = file.reader(&buf);

    while (try r.interface.takeDelimiter('\n')) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len > 0) {
            try favorites.append(allocator, try allocator.dupe(u8, trimmed));
        }
    }

    return favorites;
}

pub fn setFavorites(dir: std.fs.Dir, favorites_file: []const u8, favorites: []const []const u8) !void {
    const file = try dir.createFile(favorites_file, .{});
    defer file.close();

    var buf: [4096]u8 = undefined;
    var w = file.writer(&buf);

    for (favorites) |favorite| {
        try w.interface.print("{s}\n", .{favorite});
    }

    try w.interface.flush();
}

test "getFavorites: FileNotFound when file missing" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try std.testing.expectError(
        error.FileNotFound,
        getFavorites(std.testing.allocator, tmp.dir, "favorites.txt"),
    );
}

test "getFavorites: returns owned entries" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    {
        const f = try tmp.dir.createFile("favorites.txt", .{});
        defer f.close();
        try f.writeAll("Theme A\nTheme B\n");
    }
    var list = try getFavorites(std.testing.allocator, tmp.dir, "favorites.txt");
    defer {
        for (list.items) |item| std.testing.allocator.free(item);
        list.deinit(std.testing.allocator);
    }
    try std.testing.expectEqual(@as(usize, 2), list.items.len);
    try std.testing.expectEqualStrings("Theme A", list.items[0]);
    try std.testing.expectEqualStrings("Theme B", list.items[1]);
}

test "getFavorites: OOM at every allocation point" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    {
        const f = try tmp.dir.createFile("favorites.txt", .{});
        defer f.close();
        try f.writeAll("Theme A\nTheme B\n");
    }
    var fail_index: usize = 0;
    while (true) : (fail_index += 1) {
        var fa = std.testing.FailingAllocator.init(std.testing.allocator, .{ .fail_index = fail_index });
        var list = getFavorites(fa.allocator(), tmp.dir, "favorites.txt") catch |err| switch (err) {
            error.OutOfMemory => continue,
            else => return err,
        };
        for (list.items) |item| fa.allocator().free(item);
        list.deinit(fa.allocator());
        break;
    }
}

test "setFavorites: writes entries to file" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const favorites = [_][]const u8{ "Theme A", "Theme B" };
    try setFavorites(tmp.dir, "favorites.txt", &favorites);
    const content = try tmp.dir.readFileAlloc(std.testing.allocator, "favorites.txt", 1024);
    defer std.testing.allocator.free(content);
    try std.testing.expectEqualStrings("Theme A\nTheme B\n", content);
}
