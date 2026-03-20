const std = @import("std");

pub fn getFavorites(allocator: std.mem.Allocator, favorites_file: []const u8) !std.ArrayList([]const u8) {
    const file = std.fs.cwd().openFile(favorites_file, .{}) catch |err| switch (err) {
        error.FileNotFound => return std.ArrayList([]const u8){},
        else => return err,
    };
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

pub fn setFavorites(favorites_file: []const u8, favorites: []const []const u8) !void {
    const file = try std.fs.cwd().createFile(favorites_file, .{});
    defer file.close();

    var buf: [4096]u8 = undefined;
    var w = file.writer(&buf);

    for (favorites) |favorite| {
        try w.interface.print("{s}\n", .{favorite});
    }

    try w.interface.flush();
}
