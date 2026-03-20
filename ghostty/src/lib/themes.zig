const std = @import("std");

pub fn getCurrentTheme(allocator: std.mem.Allocator, dir: std.fs.Dir, config_file: []const u8) ![]const u8 {
    const file = try dir.openFile(config_file, .{});
    defer file.close();

    var buf: [4096]u8 = undefined;
    var r = file.reader(&buf);

    while (try r.interface.takeDelimiter('\n')) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (std.mem.startsWith(u8, trimmed, "theme")) {
            if (std.mem.indexOf(u8, trimmed, "=")) |eq_index| {
                const theme_part = std.mem.trim(u8, trimmed[eq_index + 1 ..], " \t");
                if (theme_part.len > 0) {
                    return try allocator.dupe(u8, theme_part);
                }
            }
        }
    }

    return error.ThemeNotFound;
}

pub fn getAvailableThemes(allocator: std.mem.Allocator) !std.ArrayList([]const u8) {
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "ghostty", "+list-themes" },
    });
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    var themes = std.ArrayList([]const u8){};
    errdefer {
        for (themes.items) |item| allocator.free(item);
        themes.deinit(allocator);
    }

    var lines = std.mem.splitScalar(u8, result.stdout, '\n');

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        const theme_name = if (std.mem.indexOf(u8, line, " (")) |index|
            line[0..index]
        else
            line;

        try themes.append(allocator, try allocator.dupe(u8, theme_name));
    }

    return themes;
}

test "getCurrentTheme: FileNotFound when file missing" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try std.testing.expectError(
        error.FileNotFound,
        getCurrentTheme(std.testing.allocator, tmp.dir, "config.symlink"),
    );
}

test "getCurrentTheme: ThemeNotFound when no theme line" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    {
        const f = try tmp.dir.createFile("config.symlink", .{});
        defer f.close();
        try f.writeAll("font-size = 16\n");
    }
    try std.testing.expectError(
        error.ThemeNotFound,
        getCurrentTheme(std.testing.allocator, tmp.dir, "config.symlink"),
    );
}

test "getCurrentTheme: returns owned theme name" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    {
        const f = try tmp.dir.createFile("config.symlink", .{});
        defer f.close();
        try f.writeAll("theme = Test Theme\n");
    }
    const theme = try getCurrentTheme(std.testing.allocator, tmp.dir, "config.symlink");
    defer std.testing.allocator.free(theme);
    try std.testing.expectEqualStrings("Test Theme", theme);
}

test "getCurrentTheme: OOM at every allocation point" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    {
        const f = try tmp.dir.createFile("config.symlink", .{});
        defer f.close();
        try f.writeAll("theme = Test Theme\n");
    }
    var fail_index: usize = 0;
    while (true) : (fail_index += 1) {
        var fa = std.testing.FailingAllocator.init(std.testing.allocator, .{ .fail_index = fail_index });
        const theme = getCurrentTheme(fa.allocator(), tmp.dir, "config.symlink") catch |err| switch (err) {
            error.OutOfMemory => continue,
            else => return err,
        };
        fa.allocator().free(theme);
        break;
    }
}

test "getAvailableThemes: OOM at every allocation point" {
    var fail_index: usize = 0;
    while (true) : (fail_index += 1) {
        var fa = std.testing.FailingAllocator.init(std.testing.allocator, .{ .fail_index = fail_index });
        var themes = getAvailableThemes(fa.allocator()) catch |err| switch (err) {
            error.OutOfMemory => continue,
            // Ghostty may not be installed in the test environment.
            else => {
                std.log.info("skipping getAvailableThemes OOM test: {s}", .{@errorName(err)});
                break;
            },
        };
        for (themes.items) |item| fa.allocator().free(item);
        themes.deinit(fa.allocator());
        break;
    }
}
