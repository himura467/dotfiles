const std = @import("std");

pub fn updateTheme(allocator: std.mem.Allocator, config_file: []const u8, new_theme: []const u8) !void {
    var aw = std.Io.Writer.Allocating.init(allocator);
    defer aw.deinit();

    var updated = false;

    const file_or_null = std.fs.cwd().openFile(config_file, .{}) catch |err| switch (err) {
        error.FileNotFound => null,
        else => return err,
    };

    if (file_or_null) |file| {
        defer file.close();

        var buf: [4096]u8 = undefined;
        var r = file.reader(&buf);
        var first_line = true;

        while (try r.interface.takeDelimiter('\n')) |line| {
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
