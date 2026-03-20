const std = @import("std");

pub fn findDotfilesRoot(buf: *[std.fs.max_path_bytes]u8) ![]const u8 {
    const exe_path = try std.fs.selfExePath(buf);
    var current = exe_path;
    while (std.fs.path.dirname(current)) |parent| {
        if (std.mem.eql(u8, std.fs.path.basename(current), "ghostty")) {
            return parent;
        }
        current = parent;
    }
    return error.CouldNotFindDotfilesRoot;
}
