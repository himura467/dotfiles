const std = @import("std");

pub fn getFavorites(allocator: std.mem.Allocator, favorites_file: []const u8) !std.ArrayList([]const u8) {
    const content = std.fs.cwd().readFileAlloc(allocator, favorites_file, 1024 * 1024) catch |err| switch (err) {
        error.FileNotFound => return std.ArrayList([]const u8).init(allocator),
        else => return err,
    };

    var favorites = std.ArrayList([]const u8).init(allocator);
    errdefer favorites.deinit();

    var lines = std.mem.splitScalar(u8, content, '\n');

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len > 0) {
            try favorites.append(trimmed);
        }
    }

    return favorites;
}
