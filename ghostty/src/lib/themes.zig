const std = @import("std");

pub fn getCurrentTheme(allocator: std.mem.Allocator, config_file: []const u8) ![]const u8 {
    const content = std.fs.cwd().readFileAlloc(allocator, config_file, 1024 * 1024) catch |err| switch (err) {
        error.FileNotFound => return error.GhosttyConfigNotFound,
        else => return err,
    };

    var lines = std.mem.splitScalar(u8, content, '\n');

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (std.mem.startsWith(u8, trimmed, "theme")) {
            if (std.mem.indexOf(u8, trimmed, "=")) |eq_index| {
                const theme_part = std.mem.trim(u8, trimmed[eq_index + 1 ..], " \t");
                if (theme_part.len > 0) {
                    return theme_part;
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

    var themes = std.ArrayList([]const u8){};
    errdefer themes.deinit(allocator);

    var lines = std.mem.splitScalar(u8, result.stdout, '\n');

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        const theme_name = if (std.mem.indexOf(u8, line, " (")) |index|
            line[0..index]
        else
            line;

        try themes.append(allocator, theme_name);
    }

    return themes;
}
