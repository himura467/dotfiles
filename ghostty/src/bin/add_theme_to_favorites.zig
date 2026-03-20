const std = @import("std");
const lib = @import("lib");

fn stringLessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.lessThan(u8, lhs, rhs);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var dotfiles_dir = try lib.findDotfilesRoot();
    defer dotfiles_dir.close();
    var ghostty_dir = try dotfiles_dir.openDir("ghostty", .{});
    defer ghostty_dir.close();

    const current_theme = lib.getCurrentTheme(allocator, ghostty_dir, "config.symlink") catch |err| switch (err) {
        error.GhosttyConfigNotFound, error.ThemeNotFound => {
            std.process.exit(1);
        },
        else => return err,
    };

    var favorites = try lib.getFavorites(allocator, ghostty_dir, "favorites.txt");

    for (favorites.items) |theme| {
        if (std.mem.eql(u8, theme, current_theme)) {
            return;
        }
    }

    try favorites.append(allocator, current_theme);

    std.mem.sort([]const u8, favorites.items, {}, stringLessThan);

    try lib.setFavorites(ghostty_dir, "favorites.txt", favorites.items);
}
