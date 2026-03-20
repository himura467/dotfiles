const std = @import("std");
const lib = @import("lib");

fn stringLessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.lessThan(u8, lhs, rhs);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const dotfiles_root = try lib.findDotfilesRoot(&path_buf);

    const config_file = try std.fmt.allocPrint(allocator, "{s}/ghostty/config.symlink", .{dotfiles_root});
    const current_theme = lib.getCurrentTheme(allocator, config_file) catch |err| switch (err) {
        error.GhosttyConfigNotFound, error.ThemeNotFound => {
            std.process.exit(1);
        },
        else => return err,
    };

    const favorites_file = try std.fmt.allocPrint(allocator, "{s}/ghostty/favorites.txt", .{dotfiles_root});
    var favorites = try lib.getFavorites(allocator, favorites_file);

    for (favorites.items) |theme| {
        if (std.mem.eql(u8, theme, current_theme)) {
            return;
        }
    }

    try favorites.append(allocator, current_theme);

    std.mem.sort([]const u8, favorites.items, {}, stringLessThan);

    try lib.setFavorites(favorites_file, favorites.items);
}
