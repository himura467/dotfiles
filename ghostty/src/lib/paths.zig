const std = @import("std");

pub fn findDotfilesRoot() !std.fs.Dir {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    var current: []const u8 = try std.fs.selfExePath(&buf);
    while (std.fs.path.dirname(current)) |parent| {
        if (std.mem.eql(u8, std.fs.path.basename(current), "ghostty")) {
            return try std.fs.openDirAbsolute(parent, .{});
        }
        current = parent;
    }
    return error.CouldNotFindDotfilesRoot;
}
