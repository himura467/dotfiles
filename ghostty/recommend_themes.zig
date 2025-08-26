const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const HashMap = std.HashMap;

const RGB = struct {
    r: f32,
    g: f32,
    b: f32,
};

const HSL = struct {
    h: f32, // 0-360
    s: f32, // 0-1
    l: f32, // 0-1
};

const ThemeColors = struct {
    background: RGB,
    foreground: RGB,
    palette: [16]RGB,
    cursor_color: RGB,
    selection_background: RGB,
};

const ThemeInfo = struct {
    name: []const u8,
    colors: ThemeColors,
    similarity_score: f32 = 0.0,
};

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
                    path[i - 8] = 0;
                    break :blk try allocator.dupe(u8, path[0 .. i - 8]);
                }
            }
        }
        return error.CouldNotFindDotfilesRoot;
    };

    const favorites_file = try std.fmt.allocPrint(allocator, "{s}/ghostty/favorites.txt", .{dotfiles_root});

    // Read user's favorite themes
    const favorites = getFavorites(allocator, favorites_file) catch |err| switch (err) {
        error.FileNotFound => {
            std.debug.print("No favorites file found. Please add some themes to favorites first.\n", .{});
            std.process.exit(1);
        },
        else => return err,
    };

    if (favorites.items.len == 0) {
        std.debug.print("No favorite themes found. Please add some themes to favorites first.\n", .{});
        std.process.exit(1);
    }

    // Load favorite theme colors
    var favorite_themes = ArrayList(ThemeInfo){};
    for (favorites.items) |theme_name| {
        if (loadTheme(allocator, theme_name)) |theme| {
            try favorite_themes.append(allocator, theme);
        } else |_| {
            std.debug.print("Warning: Could not load theme '{s}'\n", .{theme_name});
        }
    }

    if (favorite_themes.items.len == 0) {
        std.debug.print("Could not load any favorite themes.\n", .{});
        std.process.exit(1);
    }

    // Load all available themes
    var all_themes = ArrayList(ThemeInfo){};
    const themes_dir = "/Applications/Ghostty.app/Contents/Resources/ghostty/themes";
    var themes_iter_dir = std.fs.openDirAbsolute(themes_dir, .{ .iterate = true }) catch |err| {
        std.debug.print("Could not open themes directory: {any}\n", .{err});
        std.process.exit(1);
    };
    defer themes_iter_dir.close();

    var themes_iter = themes_iter_dir.iterate();
    while (try themes_iter.next()) |entry| {
        if (entry.kind == .file) {
            // Skip if this theme is already in favorites
            var is_favorite = false;
            for (favorites.items) |fav_name| {
                if (std.mem.eql(u8, entry.name, fav_name)) {
                    is_favorite = true;
                    break;
                }
            }
            if (is_favorite) continue;

            if (loadTheme(allocator, entry.name)) |theme| {
                try all_themes.append(allocator, theme);
            } else |_| {
                // Skip themes that can't be loaded
            }
        }
    }

    // Calculate similarities and recommend themes
    for (all_themes.items) |*theme| {
        theme.similarity_score = calculateSimilarityToFavorites(theme.colors, favorite_themes.items);
    }

    // Sort by similarity score (highest first)
    std.mem.sort(ThemeInfo, all_themes.items, {}, compareThemesBySimilarity);

    // Print top 10 recommendations
    const num_recommendations = @min(10, all_themes.items.len);
    std.debug.print("Top {d} theme recommendations based on your favorites:\n\n", .{num_recommendations});

    for (all_themes.items[0..num_recommendations], 0..) |theme, i| {
        std.debug.print("{d}. {s} (similarity: {d:.3})\n", .{ i + 1, theme.name, theme.similarity_score });
    }
}

fn getFavorites(allocator: Allocator, favorites_file: []const u8) !ArrayList([]const u8) {
    const file = try std.fs.cwd().openFile(favorites_file, .{});
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

fn loadTheme(allocator: Allocator, theme_name: []const u8) !ThemeInfo {
    const theme_path = try std.fmt.allocPrint(allocator, "/Applications/Ghostty.app/Contents/Resources/ghostty/themes/{s}", .{theme_name});

    const file = try std.fs.cwd().openFile(theme_path, .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);

    var theme_colors = ThemeColors{
        .background = RGB{ .r = 0, .g = 0, .b = 0 },
        .foreground = RGB{ .r = 1, .g = 1, .b = 1 },
        .palette = [_]RGB{RGB{ .r = 0, .g = 0, .b = 0 }} ** 16,
        .cursor_color = RGB{ .r = 1, .g = 1, .b = 1 },
        .selection_background = RGB{ .r = 0.5, .g = 0.5, .b = 0.5 },
    };

    var lines = std.mem.splitSequence(u8, content, "\n");
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len == 0) continue;

        if (std.mem.startsWith(u8, trimmed, "palette = ")) {
            if (parsePaletteLine(trimmed)) |palette_entry| {
                if (palette_entry.index < 16) {
                    theme_colors.palette[palette_entry.index] = palette_entry.color;
                }
            } else |_| {}
        } else if (std.mem.startsWith(u8, trimmed, "background = ")) {
            if (parseColorFromLine(trimmed)) |color| {
                theme_colors.background = color;
            } else |_| {}
        } else if (std.mem.startsWith(u8, trimmed, "foreground = ")) {
            if (parseColorFromLine(trimmed)) |color| {
                theme_colors.foreground = color;
            } else |_| {}
        } else if (std.mem.startsWith(u8, trimmed, "cursor-color = ")) {
            if (parseColorFromLine(trimmed)) |color| {
                theme_colors.cursor_color = color;
            } else |_| {}
        } else if (std.mem.startsWith(u8, trimmed, "selection-background = ")) {
            if (parseColorFromLine(trimmed)) |color| {
                theme_colors.selection_background = color;
            } else |_| {}
        }
    }

    return ThemeInfo{
        .name = try allocator.dupe(u8, theme_name),
        .colors = theme_colors,
    };
}

const PaletteEntry = struct {
    index: usize,
    color: RGB,
};

fn parsePaletteLine(line: []const u8) !PaletteEntry {
    // Format: "palette = INDEX=#RRGGBB"
    const first_eq_pos = std.mem.indexOf(u8, line, "=") orelse return error.InvalidFormat;
    const hash_pos = std.mem.indexOf(u8, line, "#") orelse return error.InvalidFormat;

    const middle_part = std.mem.trim(u8, line[first_eq_pos + 1 .. hash_pos], " \t");
    // Remove trailing = if present
    const index_str = if (std.mem.endsWith(u8, middle_part, "="))
        middle_part[0 .. middle_part.len - 1]
    else
        middle_part;
    const color_str = line[hash_pos + 1 ..];

    const index = try std.fmt.parseInt(usize, index_str, 10);
    const color = try parseHexColor(color_str);

    return PaletteEntry{
        .index = index,
        .color = color,
    };
}

fn parseColorFromLine(line: []const u8) !RGB {
    const hash_pos = std.mem.indexOf(u8, line, "#") orelse return error.InvalidFormat;
    const color_str = line[hash_pos + 1 ..];
    return parseHexColor(color_str);
}

fn parseHexColor(hex_str: []const u8) !RGB {
    if (hex_str.len != 6) return error.InvalidHexColor;

    const r = try std.fmt.parseInt(u8, hex_str[0..2], 16);
    const g = try std.fmt.parseInt(u8, hex_str[2..4], 16);
    const b = try std.fmt.parseInt(u8, hex_str[4..6], 16);

    return RGB{
        .r = @as(f32, @floatFromInt(r)) / 255.0,
        .g = @as(f32, @floatFromInt(g)) / 255.0,
        .b = @as(f32, @floatFromInt(b)) / 255.0,
    };
}

fn rgbToHsl(rgb: RGB) HSL {
    const max_val = @max(@max(rgb.r, rgb.g), rgb.b);
    const min_val = @min(@min(rgb.r, rgb.g), rgb.b);
    const delta = max_val - min_val;

    var h: f32 = 0;
    var s: f32 = 0;
    const l: f32 = (max_val + min_val) / 2.0;

    if (delta != 0) {
        s = if (l < 0.5) delta / (max_val + min_val) else delta / (2.0 - max_val - min_val);

        if (max_val == rgb.r) {
            h = 60.0 * (((rgb.g - rgb.b) / delta) + (if (rgb.g < rgb.b) @as(f32, 6) else @as(f32, 0)));
        } else if (max_val == rgb.g) {
            h = 60.0 * (((rgb.b - rgb.r) / delta) + 2.0);
        } else {
            h = 60.0 * (((rgb.r - rgb.g) / delta) + 4.0);
        }
    }

    return HSL{ .h = h, .s = s, .l = l };
}

fn calculateColorDistance(color1: RGB, color2: RGB) f32 {
    const hsl1 = rgbToHsl(color1);
    const hsl2 = rgbToHsl(color2);

    // Calculate hue distance (circular)
    var hue_diff = @abs(hsl1.h - hsl2.h);
    if (hue_diff > 180.0) {
        hue_diff = 360.0 - hue_diff;
    }
    hue_diff /= 180.0; // Normalize to 0-1

    const sat_diff = @abs(hsl1.s - hsl2.s);
    const light_diff = @abs(hsl1.l - hsl2.l);

    // Weighted distance: hue is most important, then lightness, then saturation
    return std.math.sqrt(hue_diff * hue_diff * 0.5 + light_diff * light_diff * 0.3 + sat_diff * sat_diff * 0.2);
}

fn calculateSimilarityToFavorites(colors: ThemeColors, favorites: []ThemeInfo) f32 {
    var total_similarity: f32 = 0;
    var count: f32 = 0;

    for (favorites) |fav_theme| {
        var theme_similarity: f32 = 0;
        var theme_count: f32 = 0;

        // Compare background (high weight)
        theme_similarity += (1.0 - calculateColorDistance(colors.background, fav_theme.colors.background)) * 3.0;
        theme_count += 3.0;

        // Compare foreground (high weight)
        theme_similarity += (1.0 - calculateColorDistance(colors.foreground, fav_theme.colors.foreground)) * 2.0;
        theme_count += 2.0;

        // Compare palette colors (medium weight)
        for (colors.palette, fav_theme.colors.palette) |color, fav_color| {
            theme_similarity += (1.0 - calculateColorDistance(color, fav_color)) * 0.5;
            theme_count += 0.5;
        }

        // Compare cursor color (low weight)
        theme_similarity += (1.0 - calculateColorDistance(colors.cursor_color, fav_theme.colors.cursor_color)) * 0.5;
        theme_count += 0.5;

        // Compare selection background (low weight)
        theme_similarity += (1.0 - calculateColorDistance(colors.selection_background, fav_theme.colors.selection_background)) * 0.5;
        theme_count += 0.5;

        total_similarity += theme_similarity / theme_count;
        count += 1;
    }

    return total_similarity / count;
}

fn compareThemesBySimilarity(context: void, a: ThemeInfo, b: ThemeInfo) bool {
    _ = context;
    return a.similarity_score > b.similarity_score;
}

// Tests
test "parseHexColor memory leak detection" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const red = try parseHexColor("ff0000");
    try std.testing.expect(red.r == 1.0);
    try std.testing.expect(red.g == 0.0);
    try std.testing.expect(red.b == 0.0);

    const green = try parseHexColor("00ff00");
    try std.testing.expect(green.r == 0.0);
    try std.testing.expect(green.g == 1.0);
    try std.testing.expect(green.b == 0.0);

    const blue = try parseHexColor("0000ff");
    try std.testing.expect(blue.r == 0.0);
    try std.testing.expect(blue.g == 0.0);
    try std.testing.expect(blue.b == 1.0);
}

test "parseHexColor handles invalid input" {
    // Test invalid hex length
    try std.testing.expectError(error.InvalidHexColor, parseHexColor("ff00"));
    try std.testing.expectError(error.InvalidHexColor, parseHexColor("ff00000"));

    // Test invalid hex characters
    try std.testing.expectError(error.InvalidCharacter, parseHexColor("gggggg"));
}

test "rgbToHsl conversion accuracy" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    // Test pure red
    const red = RGB{ .r = 1.0, .g = 0.0, .b = 0.0 };
    const red_hsl = rgbToHsl(red);
    try std.testing.expect(@abs(red_hsl.h - 0.0) < 0.01);
    try std.testing.expect(@abs(red_hsl.s - 1.0) < 0.01);
    try std.testing.expect(@abs(red_hsl.l - 0.5) < 0.01);

    // Test pure green
    const green = RGB{ .r = 0.0, .g = 1.0, .b = 0.0 };
    const green_hsl = rgbToHsl(green);
    try std.testing.expect(@abs(green_hsl.h - 120.0) < 0.01);
    try std.testing.expect(@abs(green_hsl.s - 1.0) < 0.01);
    try std.testing.expect(@abs(green_hsl.l - 0.5) < 0.01);

    // Test pure blue
    const blue = RGB{ .r = 0.0, .g = 0.0, .b = 1.0 };
    const blue_hsl = rgbToHsl(blue);
    try std.testing.expect(@abs(blue_hsl.h - 240.0) < 0.01);
    try std.testing.expect(@abs(blue_hsl.s - 1.0) < 0.01);
    try std.testing.expect(@abs(blue_hsl.l - 0.5) < 0.01);

    // Test grayscale
    const gray = RGB{ .r = 0.5, .g = 0.5, .b = 0.5 };
    const gray_hsl = rgbToHsl(gray);
    try std.testing.expect(@abs(gray_hsl.s - 0.0) < 0.01);
    try std.testing.expect(@abs(gray_hsl.l - 0.5) < 0.01);
}

test "calculateColorDistance symmetric property" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const color1 = RGB{ .r = 1.0, .g = 0.0, .b = 0.0 };
    const color2 = RGB{ .r = 0.0, .g = 1.0, .b = 0.0 };

    const distance1 = calculateColorDistance(color1, color2);
    const distance2 = calculateColorDistance(color2, color1);

    try std.testing.expect(@abs(distance1 - distance2) < 0.001);
}

test "calculateColorDistance identity property" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const color = RGB{ .r = 0.5, .g = 0.3, .b = 0.8 };
    const distance = calculateColorDistance(color, color);

    try std.testing.expect(@abs(distance) < 0.001);
}

test "parseColorFromLine memory leak detection" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const background_line = "background = #1e1f29";
    const color = try parseColorFromLine(background_line);

    // #1e1f29 = RGB(30, 31, 41)
    try std.testing.expect(@abs(color.r - (30.0 / 255.0)) < 0.01);
    try std.testing.expect(@abs(color.g - (31.0 / 255.0)) < 0.01);
    try std.testing.expect(@abs(color.b - (41.0 / 255.0)) < 0.01);
}

test "parseColorFromLine handles invalid format" {
    try std.testing.expectError(error.InvalidFormat, parseColorFromLine("background = no_hash"));
    try std.testing.expectError(error.InvalidFormat, parseColorFromLine("invalid_line"));
}

test "parsePaletteLine memory leak detection" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const palette_line = "palette = 5=#ff79c6";
    const entry = try parsePaletteLine(palette_line);

    try std.testing.expect(entry.index == 5);
    // #ff79c6 = RGB(255, 121, 198)
    try std.testing.expect(@abs(entry.color.r - 1.0) < 0.01);
    try std.testing.expect(@abs(entry.color.g - (121.0 / 255.0)) < 0.01);
    try std.testing.expect(@abs(entry.color.b - (198.0 / 255.0)) < 0.01);
}

test "parsePaletteLine handles invalid format" {
    try std.testing.expectError(error.InvalidFormat, parsePaletteLine("palette = invalid"));
    try std.testing.expectError(error.InvalidFormat, parsePaletteLine("palette = 5=no_hash"));
    try std.testing.expectError(error.InvalidCharacter, parsePaletteLine("palette = not_number=#ff0000"));
}

test "loadTheme memory leak detection" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Create a temporary theme file
    var temp_dir = std.testing.tmpDir(.{});
    defer temp_dir.cleanup();

    const theme_content =
        \\palette = 0=#000000
        \\palette = 1=#ff5555
        \\palette = 2=#50fa7b
        \\background = #1e1f29
        \\foreground = #e6e6e6
        \\cursor-color = #bbbbbb
        \\selection-background = #44475a
    ;

    try temp_dir.dir.writeFile(.{ .sub_path = "test_theme", .data = theme_content });

    // Get the temp path for testing
    const temp_path = try temp_dir.dir.realpathAlloc(allocator, "test_theme");

    // Create a modified loadTheme function for testing
    const theme = loadThemeFromPath(allocator, "test_theme", temp_path) catch |err| {
        return err;
    };

    try std.testing.expect(std.mem.eql(u8, theme.name, "test_theme"));
    // Verify background color parsing
    try std.testing.expect(@abs(theme.colors.background.r - (30.0 / 255.0)) < 0.01);
    try std.testing.expect(@abs(theme.colors.background.g - (31.0 / 255.0)) < 0.01);
    try std.testing.expect(@abs(theme.colors.background.b - (41.0 / 255.0)) < 0.01);
}

fn loadThemeFromPath(allocator: Allocator, theme_name: []const u8, theme_path: []const u8) !ThemeInfo {
    const file = try std.fs.cwd().openFile(theme_path, .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);

    var theme_colors = ThemeColors{
        .background = RGB{ .r = 0, .g = 0, .b = 0 },
        .foreground = RGB{ .r = 1, .g = 1, .b = 1 },
        .palette = [_]RGB{RGB{ .r = 0, .g = 0, .b = 0 }} ** 16,
        .cursor_color = RGB{ .r = 1, .g = 1, .b = 1 },
        .selection_background = RGB{ .r = 0.5, .g = 0.5, .b = 0.5 },
    };

    var lines = std.mem.splitSequence(u8, content, "\n");
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len == 0) continue;

        if (std.mem.startsWith(u8, trimmed, "palette = ")) {
            if (parsePaletteLine(trimmed)) |palette_entry| {
                if (palette_entry.index < 16) {
                    theme_colors.palette[palette_entry.index] = palette_entry.color;
                }
            } else |_| {}
        } else if (std.mem.startsWith(u8, trimmed, "background = ")) {
            if (parseColorFromLine(trimmed)) |color| {
                theme_colors.background = color;
            } else |_| {}
        } else if (std.mem.startsWith(u8, trimmed, "foreground = ")) {
            if (parseColorFromLine(trimmed)) |color| {
                theme_colors.foreground = color;
            } else |_| {}
        } else if (std.mem.startsWith(u8, trimmed, "cursor-color = ")) {
            if (parseColorFromLine(trimmed)) |color| {
                theme_colors.cursor_color = color;
            } else |_| {}
        } else if (std.mem.startsWith(u8, trimmed, "selection-background = ")) {
            if (parseColorFromLine(trimmed)) |color| {
                theme_colors.selection_background = color;
            } else |_| {}
        }
    }

    return ThemeInfo{
        .name = try allocator.dupe(u8, theme_name),
        .colors = theme_colors,
    };
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

test "calculateSimilarityToFavorites basic functionality" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Create test theme colors
    const test_colors = ThemeColors{
        .background = RGB{ .r = 0.1, .g = 0.1, .b = 0.1 },
        .foreground = RGB{ .r = 0.9, .g = 0.9, .b = 0.9 },
        .palette = [_]RGB{RGB{ .r = 0.0, .g = 0.0, .b = 0.0 }} ** 16,
        .cursor_color = RGB{ .r = 0.7, .g = 0.7, .b = 0.7 },
        .selection_background = RGB{ .r = 0.3, .g = 0.3, .b = 0.3 },
    };

    // Create identical favorite theme
    const identical_theme = ThemeInfo{
        .name = try allocator.dupe(u8, "identical"),
        .colors = test_colors,
    };

    // Create different favorite theme
    const different_colors = ThemeColors{
        .background = RGB{ .r = 0.9, .g = 0.9, .b = 0.9 },
        .foreground = RGB{ .r = 0.1, .g = 0.1, .b = 0.1 },
        .palette = [_]RGB{RGB{ .r = 1.0, .g = 1.0, .b = 1.0 }} ** 16,
        .cursor_color = RGB{ .r = 0.2, .g = 0.2, .b = 0.2 },
        .selection_background = RGB{ .r = 0.8, .g = 0.8, .b = 0.8 },
    };

    const different_theme = ThemeInfo{
        .name = try allocator.dupe(u8, "different"),
        .colors = different_colors,
    };

    // Test with identical theme
    var identical_favorites = [_]ThemeInfo{identical_theme};
    const identical_similarity = calculateSimilarityToFavorites(test_colors, identical_favorites[0..]);
    try std.testing.expect(identical_similarity > 0.99); // Should be very high

    // Test with different theme
    var different_favorites = [_]ThemeInfo{different_theme};
    const different_similarity = calculateSimilarityToFavorites(test_colors, different_favorites[0..]);
    try std.testing.expect(different_similarity < identical_similarity); // Should be lower

    // Test with mixed favorites
    var mixed_favorites = [_]ThemeInfo{ identical_theme, different_theme };
    const mixed_similarity = calculateSimilarityToFavorites(test_colors, mixed_favorites[0..]);
    try std.testing.expect(mixed_similarity > different_similarity);
    try std.testing.expect(mixed_similarity < identical_similarity);
}
