const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Get dotfiles root path
    const exe_path = try std.fs.selfExePathAlloc(allocator);
    defer allocator.free(exe_path);

    const dotfiles_root = blk: {
        var path = try allocator.dupe(u8, exe_path);
        defer allocator.free(path);
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
    defer allocator.free(dotfiles_root);

    // Config and favorites file paths
    const config_file = try std.fmt.allocPrint(allocator, "{s}/ghostty/config", .{dotfiles_root});
    defer allocator.free(config_file);
    const favorites_file = try std.fmt.allocPrint(allocator, "{s}/ghostty/favorites.txt", .{dotfiles_root});
    defer allocator.free(favorites_file);

    // Get current theme from config
    const current_theme = getCurrentTheme(allocator, config_file) catch |err| switch (err) {
        error.ThemeNotFound => {
            const error_cmd = try std.fmt.allocPrint(allocator, "source {s}/lib/logger.sh && error 'No theme found in config'", .{dotfiles_root});
            defer allocator.free(error_cmd);
            const error_result = try executeCommand(allocator, &.{ "sh", "-c", error_cmd });
            defer allocator.free(error_result.stdout);
            defer allocator.free(error_result.stderr);
            std.process.exit(1);
        },
        else => return err,
    };
    defer allocator.free(current_theme);

    // Read existing favorites
    var favorites = getFavorites(allocator, favorites_file) catch |err| switch (err) {
        error.FileNotFound => ArrayList([]const u8){},
        else => return err,
    };
    defer {
        for (favorites.items) |favorite| {
            allocator.free(favorite);
        }
        favorites.deinit(allocator);
    }

    // Check if already in favorites
    var already_favorite = false;
    for (favorites.items) |theme| {
        if (std.mem.eql(u8, theme, current_theme)) {
            already_favorite = true;
            break;
        }
    }

    if (already_favorite) {
        const info_cmd = try std.fmt.allocPrint(allocator, "source {s}/lib/logger.sh && info 'Theme \"{s}\" is already in favorites'", .{ dotfiles_root, current_theme });
        defer allocator.free(info_cmd);
        const info_result = try executeCommand(allocator, &.{ "sh", "-c", info_cmd });
        defer allocator.free(info_result.stdout);
        defer allocator.free(info_result.stderr);
        return;
    }

    // Add to favorites
    var new_favorites = ArrayList([]const u8){};
    defer {
        for (new_favorites.items) |favorite| {
            allocator.free(favorite);
        }
        new_favorites.deinit(allocator);
    }

    // Copy existing favorites
    for (favorites.items) |favorite| {
        try new_favorites.append(allocator, try allocator.dupe(u8, favorite));
    }

    // Add current theme
    try new_favorites.append(allocator, try allocator.dupe(u8, current_theme));

    // Sort favorites
    std.mem.sort([]const u8, new_favorites.items, {}, stringLessThan);

    // Write updated favorites
    try writeFavorites(allocator, favorites_file, new_favorites.items);

    // Log success
    const success_cmd = try std.fmt.allocPrint(allocator, "source {s}/lib/logger.sh && success 'Added \"{s}\" to favorites'", .{ dotfiles_root, current_theme });
    defer allocator.free(success_cmd);
    const success_result = try executeCommand(allocator, &.{ "sh", "-c", success_cmd });
    defer allocator.free(success_result.stdout);
    defer allocator.free(success_result.stderr);
}

fn getCurrentTheme(allocator: Allocator, config_file: []const u8) ![]const u8 {
    const file = std.fs.cwd().openFile(config_file, .{}) catch |err| switch (err) {
        error.FileNotFound => return error.ThemeNotFound,
        else => return err,
    };
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    var lines = std.mem.splitSequence(u8, content, "\n");

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (std.mem.startsWith(u8, trimmed, "theme")) {
            // Look for "theme = theme_name" pattern
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

fn getFavorites(allocator: Allocator, favorites_file: []const u8) !ArrayList([]const u8) {
    const file = std.fs.cwd().openFile(favorites_file, .{}) catch |err| switch (err) {
        error.FileNotFound => return ArrayList([]const u8){},
        else => return err,
    };
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

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

fn writeFavorites(_: Allocator, favorites_file: []const u8, favorites: []const []const u8) !void {
    const file = try std.fs.cwd().createFile(favorites_file, .{});
    defer file.close();

    for (favorites) |favorite| {
        try file.writeAll(favorite);
        try file.writeAll("\n");
    }
}

fn stringLessThan(context: void, lhs: []const u8, rhs: []const u8) bool {
    _ = context;
    return std.mem.order(u8, lhs, rhs) == .lt;
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
    defer stdout.deinit(allocator);
    var stderr = ArrayList(u8){};
    defer stderr.deinit(allocator);

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
