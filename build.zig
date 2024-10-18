const std = @import("std");
const rlz = @import("raylib-zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
        .opengl_version = rlz.OpenglVersion.gl_4_3,
    });

    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const exe = b.addExecutable(.{ .name = "zig_n_raylib", .root_source_file = b.path("src/main.zig"), .optimize = optimize, .target = target });

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run zig_n_raylib");
    run_step.dependOn(&run_cmd.step);

    b.installArtifact(exe);
}
