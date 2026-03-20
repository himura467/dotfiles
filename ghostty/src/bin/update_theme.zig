const std = @import("std");
const lib = @import("lib");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var dotfiles_dir = try lib.findDotfilesRoot();
    defer dotfiles_dir.close();
    var ghostty_dir = try dotfiles_dir.openDir("ghostty", .{});
    defer ghostty_dir.close();

    var prng = blk: {
        const args = try std.process.argsAlloc(allocator);
        if (args.len > 1) {
            const seed = std.fmt.parseInt(u64, args[1], 10) catch {
                std.debug.print("Invalid seed provided, using time-based seed\n", .{});
                break :blk std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
            };
            break :blk std.Random.DefaultPrng.init(seed);
        } else {
            break :blk std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
        }
    };

    const favorites = lib.getFavorites(allocator, ghostty_dir, "favorites.txt") catch |err| switch (err) {
        error.FileNotFound => std.ArrayList([]const u8){},
        else => return err,
    };
    const themes = try lib.getAvailableThemes(allocator);

    var new_theme: []const u8 = undefined;

    if (favorites.items.len > 0 and prng.random().float(f32) < 0.5) {
        const index = prng.random().uintLessThan(usize, favorites.items.len);
        new_theme = favorites.items[index];
    } else {
        const index = prng.random().uintLessThan(usize, themes.items.len);
        new_theme = themes.items[index];
    }

    try lib.updateTheme(allocator, ghostty_dir, "config.symlink", new_theme);
}
