const std = @import("std");

pub fn updateTheme(allocator: std.mem.Allocator, dir: std.fs.Dir, config_file: []const u8, new_theme: []const u8) !void {
    var aw = std.Io.Writer.Allocating.init(allocator);
    defer aw.deinit();

    var updated = false;

    const file_or_null = dir.openFile(config_file, .{}) catch |err| switch (err) {
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

    const file = try dir.createFile(config_file, .{});
    defer file.close();
    try file.writeAll(aw.written());
}

test "updateTheme: creates config file when none exists" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try updateTheme(std.testing.allocator, tmp.dir, "config.symlink", "Test Theme");
    const content = try tmp.dir.readFileAlloc(std.testing.allocator, "config.symlink", 1024);
    defer std.testing.allocator.free(content);
    try std.testing.expectEqualStrings("theme = Test Theme\n", content);
}

test "updateTheme: replaces theme in existing config" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    {
        const f = try tmp.dir.createFile("config.symlink", .{});
        defer f.close();
        try f.writeAll("font-size = 16\ntheme = Old Theme\n");
    }
    try updateTheme(std.testing.allocator, tmp.dir, "config.symlink", "New Theme");
    const content = try tmp.dir.readFileAlloc(std.testing.allocator, "config.symlink", 1024);
    defer std.testing.allocator.free(content);
    try std.testing.expectEqualStrings("font-size = 16\ntheme = New Theme\n", content);
}

test "updateTheme: OOM at every allocation point" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    {
        const f = try tmp.dir.createFile("config.symlink", .{});
        defer f.close();
        try f.writeAll("theme = Theme A\n");
    }
    var fail_index: usize = 0;
    while (true) : (fail_index += 1) {
        var fa = std.testing.FailingAllocator.init(std.testing.allocator, .{ .fail_index = fail_index });
        updateTheme(fa.allocator(), tmp.dir, "config.symlink", "Theme B") catch |err| switch (err) {
            error.OutOfMemory => continue,
            else => return err,
        };
        break;
    }
}
