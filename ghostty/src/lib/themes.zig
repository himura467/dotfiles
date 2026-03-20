const std = @import("std");

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
