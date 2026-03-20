const std = @import("std");

pub fn getCurrentTheme(allocator: std.mem.Allocator, config_file: []const u8) ![]const u8 {
    const file = std.fs.cwd().openFile(config_file, .{}) catch |err| switch (err) {
        error.FileNotFound => return error.GhosttyConfigNotFound,
        else => return err,
    };
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
