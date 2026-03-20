const std = @import("std");
const lib = @import("lib");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const dotfiles_root = try lib.findDotfilesRoot(&path_buf);

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

    const favorites_file = try std.fmt.allocPrint(allocator, "{s}/ghostty/favorites.txt", .{dotfiles_root});
    const favorites = try lib.getFavorites(allocator, favorites_file);

    const themes = try lib.getAvailableThemes(allocator);

    var new_theme: []const u8 = undefined;

    if (favorites.items.len > 0 and prng.random().float(f32) < 0.5) {
        const index = prng.random().uintLessThan(usize, favorites.items.len);
        new_theme = favorites.items[index];
    } else {
        const index = prng.random().uintLessThan(usize, themes.items.len);
        new_theme = themes.items[index];
    }

    const config_file = try std.fmt.allocPrint(allocator, "{s}/ghostty/config.symlink", .{dotfiles_root});
    try lib.updateTheme(allocator, config_file, new_theme);
}
