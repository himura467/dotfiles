const std = @import("std");

pub fn updateTheme(allocator: std.mem.Allocator, config_file: []const u8, new_theme: []const u8) !void {
    const content_or_null: ?[]const u8 = std.fs.cwd().readFileAlloc(allocator, config_file, 1024 * 1024) catch |err| switch (err) {
        error.FileNotFound => null,
        else => return err,
    };
    defer if (content_or_null) |content| allocator.free(content);

    var aw = std.Io.Writer.Allocating.init(allocator);
    defer aw.deinit();

    var updated = false;

    if (content_or_null) |content| {
        var lines = std.mem.splitScalar(u8, content, '\n');
        var first_line = true;

        while (lines.next()) |line| {
            if (!first_line) try aw.writer.writeByte('\n');
            first_line = false;

            if (std.mem.startsWith(u8, std.mem.trim(u8, line, " \t\r"), "theme")) {
                try aw.writer.print("theme = {s}", .{new_theme});
                updated = true;
            } else {
                try aw.writer.writeAll(line);
            }
        }
    }

    if (!updated) {
        if (aw.written().len > 0) try aw.writer.writeByte('\n');
        try aw.writer.print("theme = {s}", .{new_theme});
    }

    try aw.writer.writeByte('\n');

    const file = try std.fs.cwd().createFile(config_file, .{});
    defer file.close();
    try file.writeAll(aw.written());
}
