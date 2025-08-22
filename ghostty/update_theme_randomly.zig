const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Get dotfiles root path
    const exe_path = try std.fs.selfExePathAlloc(allocator);

    const dotfiles_root = blk: {
        var path = try allocator.dupe(u8, exe_path);
        var i = path.len;
        while (i > 0) {
            i -= 1;
            if (path[i] == '/') {
                if (std.mem.endsWith(u8, path[0..i], "/ghostty")) {
                    path[i - 8] = 0; // null terminate before "/ghostty"
                    break :blk try allocator.dupe(u8, path[0 .. i - 8]);
                }
            }
        }
        return error.CouldNotFindDotfilesRoot;
    };

    // Set random seed if provided as command line argument
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

    // Get available themes from ghostty
    const themes = try getAvailableThemes(allocator);

    // Get favorites file path
    const favorites_file = try std.fmt.allocPrint(allocator, "{s}/ghostty/favorites.txt", .{dotfiles_root});

    var new_theme: []const u8 = undefined;
    var selected_from_favorites = false;

    // Use favorites 50% of the time if favorites file exists and has content
    if (std.fs.cwd().access(favorites_file, .{})) |_| {
        if (prng.random().float(f32) < 0.5) {
            const favorites = getFavorites(allocator, favorites_file) catch |err| switch (err) {
                error.FileNotFound => ArrayList([]const u8){},
                else => return err,
            };

            if (favorites.items.len > 0) {
                const index = prng.random().uintLessThan(usize, favorites.items.len);
                new_theme = try allocator.dupe(u8, favorites.items[index]);
                selected_from_favorites = true;
            } else {
                const index = prng.random().uintLessThan(usize, themes.items.len);
                new_theme = try allocator.dupe(u8, themes.items[index]);
            }
        } else {
            const index = prng.random().uintLessThan(usize, themes.items.len);
            new_theme = try allocator.dupe(u8, themes.items[index]);
        }
    } else |_| {
        const index = prng.random().uintLessThan(usize, themes.items.len);
        new_theme = try allocator.dupe(u8, themes.items[index]);
    }

    // Log selection method
    const log_cmd = if (selected_from_favorites)
        try std.fmt.allocPrint(allocator, "source {s}/lib/logger.sh && info 'Selected from favorites'", .{dotfiles_root})
    else
        try std.fmt.allocPrint(allocator, "source {s}/lib/logger.sh && info 'Selected from all themes'", .{dotfiles_root});
    _ = try executeCommand(allocator, &.{ "sh", "-c", log_cmd });

    // Update config file
    const config_file = try std.fmt.allocPrint(allocator, "{s}/ghostty/config", .{dotfiles_root});

    try updateConfigFile(allocator, config_file, new_theme);

    // Log success
    const success_cmd = try std.fmt.allocPrint(allocator, "source {s}/lib/logger.sh && success 'Theme updated to: {s}'", .{ dotfiles_root, new_theme });
    _ = try executeCommand(allocator, &.{ "sh", "-c", success_cmd });
}

fn getAvailableThemes(allocator: Allocator) !ArrayList([]const u8) {
    const result = try executeCommand(allocator, &.{ "ghostty", "+list-themes" });

    var themes = ArrayList([]const u8){};
    var lines = std.mem.splitSequence(u8, result.stdout, "\n");

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        // Remove " (builtin)" or " (user)" suffix if present
        var theme_name = line;
        if (std.mem.indexOf(u8, line, " (")) |index| {
            theme_name = line[0..index];
        }

        try themes.append(allocator, try allocator.dupe(u8, theme_name));
    }

    return themes;
}

fn getFavorites(allocator: Allocator, favorites_file: []const u8) !ArrayList([]const u8) {
    const file = std.fs.cwd().openFile(favorites_file, .{}) catch |err| switch (err) {
        error.FileNotFound => return ArrayList([]const u8){},
        else => return err,
    };
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);

    var favorites = ArrayList([]const u8){};
    var lines = std.mem.splitSequence(u8, content, "\n");

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r\n");
        if (trimmed.len > 0) {
            try favorites.append(allocator, try allocator.dupe(u8, trimmed));
        }
    }

    return favorites;
}

fn updateConfigFile(allocator: Allocator, config_file: []const u8, new_theme: []const u8) !void {
    const file = std.fs.cwd().openFile(config_file, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            // Create new config file with just the theme
            const new_file = try std.fs.cwd().createFile(config_file, .{});
            defer new_file.close();
            const content = try std.fmt.allocPrint(allocator, "theme = {s}\n", .{new_theme});
            try new_file.writeAll(content);
            return;
        },
        else => return err,
    };
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);

    var new_content = ArrayList(u8){};

    var updated = false;
    var lines = std.mem.splitSequence(u8, content, "\n");
    var first_line = true;

    while (lines.next()) |line| {
        if (!first_line) {
            try new_content.append(allocator, '\n');
        }
        first_line = false;

        if (std.mem.startsWith(u8, std.mem.trim(u8, line, " \t"), "theme")) {
            // Replace existing theme line
            const theme_line = try std.fmt.allocPrint(allocator, "theme = {s}", .{new_theme});
            try new_content.appendSlice(allocator, theme_line);
            updated = true;
        } else {
            try new_content.appendSlice(allocator, line);
        }
    }

    // Append theme if not found in existing config
    if (!updated) {
        if (new_content.items.len > 0) {
            try new_content.append(allocator, '\n');
        }
        const theme_line = try std.fmt.allocPrint(allocator, "theme = {s}", .{new_theme});
        try new_content.appendSlice(allocator, theme_line);
    }

    // Write updated configuration
    const new_file = try std.fs.cwd().createFile(config_file, .{});
    defer new_file.close();
    try new_file.writeAll(new_content.items);
}

const CommandResult = struct {
    stdout: []const u8,
    stderr: []const u8,
    exit_code: u8,
};

fn executeCommand(allocator: Allocator, argv: []const []const u8) !CommandResult {
    var child = std.process.Child.init(argv, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();

    var stdout = ArrayList(u8){};
    var stderr = ArrayList(u8){};

    try child.collectOutput(allocator, &stdout, &stderr, 1024 * 1024);
    const term = try child.wait();

    const exit_code: u8 = switch (term) {
        .Exited => |code| @intCast(code),
        else => 1,
    };

    return CommandResult{
        .stdout = try stdout.toOwnedSlice(allocator),
        .stderr = try stderr.toOwnedSlice(allocator),
        .exit_code = exit_code,
    };
}
