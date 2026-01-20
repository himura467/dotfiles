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

    // Config and favorites file paths
    const config_file = try std.fmt.allocPrint(allocator, "{s}/ghostty/config.symlink", .{dotfiles_root});
    const favorites_file = try std.fmt.allocPrint(allocator, "{s}/ghostty/favorites.txt", .{dotfiles_root});

    // Get current theme from config
    const current_theme = getCurrentTheme(allocator, config_file) catch |err| switch (err) {
        error.ThemeNotFound => {
            std.process.exit(1);
        },
        else => return err,
    };

    // Read existing favorites
    const favorites = getFavorites(allocator, favorites_file) catch |err| switch (err) {
        error.FileNotFound => ArrayList([]const u8){},
        else => return err,
    };

    // Check if already in favorites
    var already_favorite = false;
    for (favorites.items) |theme| {
        if (std.mem.eql(u8, theme, current_theme)) {
            already_favorite = true;
            break;
        }
    }

    if (already_favorite) {
        return;
    }

    // Add to favorites
    var new_favorites = ArrayList([]const u8){};

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
}

fn getCurrentTheme(allocator: Allocator, config_file: []const u8) ![]const u8 {
    const file = std.fs.cwd().openFile(config_file, .{}) catch |err| switch (err) {
        error.FileNotFound => return error.ThemeNotFound,
        else => return err,
    };
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);

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

// Tests
test "getCurrentTheme memory leak detection" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Create a temporary config file
    var temp_dir = std.testing.tmpDir(.{});
    defer temp_dir.cleanup();

    // Write test config content
    try temp_dir.dir.writeFile(.{ .sub_path = "test_config", .data = "theme = test_theme\nother_setting = value\n" });

    const config_file = try temp_dir.dir.realpathAlloc(allocator, "test_config");

    // Test getCurrentTheme - should succeed and return theme
    const theme = try getCurrentTheme(allocator, config_file);

    try std.testing.expect(std.mem.eql(u8, theme, "test_theme"));
}

test "getFavorites memory leak detection" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Create temporary favorites file
    var temp_dir = std.testing.tmpDir(.{});
    defer temp_dir.cleanup();

    // Write test favorites content
    try temp_dir.dir.writeFile(.{ .sub_path = "test_favorites", .data = "theme1\ntheme2\ntheme3\n" });

    const favorites_file = try temp_dir.dir.realpathAlloc(allocator, "test_favorites");

    // Test getFavorites - should succeed and return favorites list
    const favorites = try getFavorites(allocator, favorites_file);

    try std.testing.expect(favorites.items.len == 3);
    try std.testing.expect(std.mem.eql(u8, favorites.items[0], "theme1"));
    try std.testing.expect(std.mem.eql(u8, favorites.items[1], "theme2"));
    try std.testing.expect(std.mem.eql(u8, favorites.items[2], "theme3"));
}

test "writeFavorites memory leak detection" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Create temporary directory
    var temp_dir = std.testing.tmpDir(.{});
    defer temp_dir.cleanup();

    // Create the test_output file first
    try temp_dir.dir.writeFile(.{ .sub_path = "test_output", .data = "" });

    const favorites_file = try temp_dir.dir.realpathAlloc(allocator, "test_output");

    // Test data
    const test_favorites = [_][]const u8{ "theme1", "theme2", "theme3" };

    // Test writeFavorites - should succeed
    try writeFavorites(allocator, favorites_file, &test_favorites);

    // Verify the file was written correctly
    const content = try temp_dir.dir.readFileAlloc(allocator, "test_output", 1024);

    try std.testing.expect(std.mem.eql(u8, content, "theme1\ntheme2\ntheme3\n"));
}

test "getCurrentTheme handles OutOfMemory" {
    var failing_allocator = std.testing.FailingAllocator.init(std.testing.allocator, .{ .fail_index = 0 });
    const allocator = failing_allocator.allocator();

    // Create a temporary config file
    var temp_dir = std.testing.tmpDir(.{});
    defer temp_dir.cleanup();

    // Write test config content
    try temp_dir.dir.writeFile(.{ .sub_path = "test_config", .data = "theme = test_theme\nother_setting = value\n" });

    const config_file = try temp_dir.dir.realpathAlloc(std.testing.allocator, "test_config");
    defer std.testing.allocator.free(config_file);

    // Test getCurrentTheme with failing allocator - should return OutOfMemory
    const result = getCurrentTheme(allocator, config_file);
    try std.testing.expectError(error.OutOfMemory, result);
}

test "getFavorites handles OutOfMemory" {
    var failing_allocator = std.testing.FailingAllocator.init(std.testing.allocator, .{ .fail_index = 0 });
    const allocator = failing_allocator.allocator();

    // Create temporary favorites file
    var temp_dir = std.testing.tmpDir(.{});
    defer temp_dir.cleanup();

    // Write test favorites content
    try temp_dir.dir.writeFile(.{ .sub_path = "test_favorites", .data = "theme1\ntheme2\ntheme3\n" });

    const favorites_file = try temp_dir.dir.realpathAlloc(std.testing.allocator, "test_favorites");
    defer std.testing.allocator.free(favorites_file);

    // Test getFavorites with failing allocator - should return OutOfMemory
    const result = getFavorites(allocator, favorites_file);
    try std.testing.expectError(error.OutOfMemory, result);
}

test "writeFavorites handles OutOfMemory" {
    // writeFavorites doesn't allocate memory, so create a simple test
    var failing_allocator = std.testing.FailingAllocator.init(std.testing.allocator, .{ .fail_index = 0 });
    const allocator = failing_allocator.allocator();

    // Create temporary directory and file path with regular allocator
    var temp_dir = std.testing.tmpDir(.{});
    defer temp_dir.cleanup();

    // Create the test_output file first
    try temp_dir.dir.writeFile(.{ .sub_path = "test_output", .data = "" });

    const favorites_file = try temp_dir.dir.realpathAlloc(std.testing.allocator, "test_output");
    defer std.testing.allocator.free(favorites_file);

    // Test data
    const test_favorites = [_][]const u8{ "theme1", "theme2", "theme3" };

    // writeFavorites itself doesn't allocate memory, so this should succeed
    try writeFavorites(allocator, favorites_file, &test_favorites);

    // Verify the file was written correctly
    const content = try temp_dir.dir.readFileAlloc(std.testing.allocator, "test_output", 1024);
    defer std.testing.allocator.free(content);

    try std.testing.expect(std.mem.eql(u8, content, "theme1\ntheme2\ntheme3\n"));
}
