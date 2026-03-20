const std = @import("std");

pub fn updateTheme(allocator: std.mem.Allocator, config_file: []const u8, new_theme: []const u8) !void {
    const content_or_null: ?[]const u8 = std.fs.cwd().readFileAlloc(allocator, config_file, 1024 * 1024) catch |err| switch (err) {
        error.FileNotFound => null,
        else => return err,
    };

    var new_content = std.ArrayList(u8){};
    errdefer new_content.deinit(allocator);
    const writer = new_content.writer(allocator);

    var updated = false;

    if (content_or_null) |content| {
        var lines = std.mem.splitScalar(u8, content, '\n');
        var first_line = true;

        while (lines.next()) |line| {
            if (!first_line) try writer.writeByte('\n');
            first_line = false;

            if (std.mem.startsWith(u8, std.mem.trim(u8, line, " \t\r"), "theme")) {
                try writer.print("theme = {s}", .{new_theme});
                updated = true;
            } else {
                try writer.writeAll(line);
            }
        }
    }

    if (!updated) {
        if (new_content.items.len > 0) try writer.writeByte('\n');
        try writer.print("theme = {s}", .{new_theme});
    }

    const file = try std.fs.cwd().createFile(config_file, .{});
    defer file.close();
    try file.writeAll(new_content.items);
}
