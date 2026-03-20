const std = @import("std");

pub fn getFavorites(allocator: std.mem.Allocator, favorites_file: []const u8) !std.ArrayList([]const u8) {
    const content = std.fs.cwd().readFileAlloc(allocator, favorites_file, 1024 * 1024) catch |err| switch (err) {
        error.FileNotFound => return std.ArrayList([]const u8){},
        else => return err,
    };

    var favorites = std.ArrayList([]const u8){};
    errdefer favorites.deinit(allocator);

    var lines = std.mem.splitScalar(u8, content, '\n');

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len > 0) {
            try favorites.append(allocator, trimmed);
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
