const std = @import("std");
const rlz = @import("raylib-zig");

const LinuxDisplayBackEnd = enum {
    x11,
    wayland,
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const backend = b.option(LinuxDisplayBackEnd, "linux_display_backend", "Which linux display backend to use") orelse .wayland;

    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
        .opengl_version = rlz.OpenglVersion.gl_4_3,
        .linux_display_backend = if (backend == .wayland) rlz.LinuxDisplayBackend.Wayland else rlz.LinuxDisplayBackend.X11,
        .platform = .sdl,
    });

    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const exe = b.addExecutable(.{
        .name = "zig_n_raylib",
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = target,
    });
    exe.linkLibC();

    b.default_step.dependOn(&exe.step);

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);

    const test_exe = b.addTest(.{
        .name = "tests",
        .root_source_file = b.path("tests.zig"),
        .target = b.host,
    });
    test_exe.linkLibrary(raylib_artifact);
    test_exe.root_module.addImport("raylib", raylib);
    b.installArtifact(test_exe);

    const test_artifact = b.addRunArtifact(test_exe);
    const run_step_test = b.step("test", "Run unit tests");
    run_step_test.dependOn(&test_artifact.step);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run zig_n_raylib");
    run_step.dependOn(&run_cmd.step);

    b.installArtifact(exe);
}
