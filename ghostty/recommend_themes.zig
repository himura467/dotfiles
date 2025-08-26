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
    const eq_pos = std.mem.indexOf(u8, line, "=") orelse return error.InvalidFormat;
    const hash_pos = std.mem.indexOf(u8, line[eq_pos..], "#") orelse return error.InvalidFormat;

    const index_str = std.mem.trim(u8, line[eq_pos + 1 .. eq_pos + hash_pos], " \t");
    const color_str = line[eq_pos + hash_pos + 1 ..];

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
