const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addModule("lib", .{
        .root_source_file = b.path("src/lib/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const executables = [_]struct { name: []const u8, src: []const u8 }{
        .{ .name = "add_theme_to_favorites", .src = "src/bin/add_theme_to_favorites.zig" },
        .{ .name = "update_theme", .src = "src/bin/update_theme.zig" },
    };

    inline for (executables) |cfg| {
        const exe = b.addExecutable(.{
            .name = cfg.name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(cfg.src),
                .target = target,
                .optimize = optimize,
                .imports = &.{.{ .name = "lib", .module = lib }},
            }),
        });
        b.installArtifact(exe);
    }

    const test_lib = b.addTest(.{
        .name = "lib",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/lib/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&b.addRunArtifact(test_lib).step);
}
