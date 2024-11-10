const std = @import("std");
const rlz = @import("raylib-zig");
const builtin = @import("builtin");

const os = builtin.target.os.tag;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const shared = b.option(bool, "shared", "Build as a shared library") orelse false;

    const use_x11 = b.option(bool, "x11", "Build with X11. Only useful on Linux") orelse false;
    const use_wl = b.option(bool, "wayland", "Build with Wayland. Only useful on Linux") orelse if (os == .linux) true else false;

    const use_opengl = b.option(bool, "opengl", "Build with OpenGL; deprecated on MacOS") orelse false;
    const use_gles = b.option(bool, "gles", "Build with GLES; not supported on MacOS") orelse false;

    const lib = std.Build.Step.Compile.create(b, .{
        .name = "glfw",
        .kind = .lib,
        .linkage = if (shared) .dynamic else .static,
        .root_module = .{
            .target = target,
            .optimize = optimize,
        },
    });
    lib.addIncludePath(b.path("./deps/include"));
    lib.linkLibC();

    if (shared) lib.defineCMacro("_GLFW_BUILD_DLL", null);

    lib.installHeadersDirectory(
        b.path("./deps/glfw/include/GLFW"),
        "GLFW",
        .{},
    );

    if (b.lazyDependency("vulkan_headers", .{
        .target = target,
        .optimize = optimize,
    })) |dep| {
        lib.installLibraryHeaders(dep.artifact("vulkan-headers"));
    }

    if (os == .linux) {
        if (b.lazyDependency("x11_headers", .{
            .target = target,
            .optimize = optimize,
        })) |dep| {
            lib.linkLibrary(dep.artifact("x11-headers"));
            lib.installLibraryHeaders(dep.artifact("x11-headers"));
        }
        if (b.lazyDependency("wayland_headers", .{
            .target = target,
            .optimize = optimize,
        })) |dep| {
            lib.linkLibrary(dep.artifact("wayland-headers"));
            lib.installLibraryHeaders(dep.artifact("wayland-headers"));
        }
    }

    const include_src_flag = "-Isrc";

    switch (os) {
        .windows => {
            lib.linkSystemLibrary("gdi32");
            lib.linkSystemLibrary("user32");
            lib.linkSystemLibrary("shell32");

            if (use_opengl) {
                lib.linkSystemLibrary("opengl32");
            }

            if (use_gles) {
                lib.linkSystemLibrary("GLEsv3");
            }

            const flags = [_][]const u8{
                "-D_GLFW_WIN32",
                include_src_flag,
            };

            lib.addCSourceFiles(.{
                .files = &base_sources,
                .flags = &flags,
            });
            lib.addCSourceFiles(.{
                .files = &windows_sources,
                .flags = &flags,
            });
        },

        .linux => {
            var sources = std.BoundedArray([]const u8, 64).init(0) catch unreachable;
            var flags = std.BoundedArray([]const u8, 16).init(0) catch unreachable;

            sources.appendSlice(&base_sources) catch unreachable;
            sources.appendSlice(&linux_sources) catch unreachable;

            if (use_x11) {
                sources.appendSlice(&linux_x11_sources) catch unreachable;
                flags.append("-D_GLFW_X11") catch unreachable;
            }

            if (use_wl) {
                lib.defineCMacro("WL_MARSHAL_FLAG_DESTROY", null);

                sources.appendSlice(&linux_wl_sources) catch unreachable;
                flags.append("-D_GLFW_WAYLAND") catch unreachable;
                flags.append("-Wno-implicit-function-declaration") catch unreachable;
            }

            flags.append(include_src_flag) catch unreachable;

            lib.addCSourceFiles(.{
                .files = sources.slice(),
                .flags = flags.slice(),
            });
        },

        else => {
            std.debug.print("NO SUPPORT FOR MacOS", .{});
        },
    }

    b.installArtifact(lib);

    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
        .opengl_version = rlz.OpenglVersion.gl_4_3,
        // .linux_display_backend = rlz.LinuxDisplayBackend.Wayland,
        .platform = .sdl,
    });

    const exe = b.addExecutable(.{
        .name = "Znake",
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = target,
    });

    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run zig_n_raylib");
    run_step.dependOn(&run_cmd.step);

    b.installArtifact(exe);
}
const base_sources = [_][]const u8{
    "deps/glfw/src/context.c",
    "deps/glfw/src/egl_context.c",
    "deps/glfw/src/init.c",
    "deps/glfw/src/input.c",
    "deps/glfw/src/monitor.c",
    "deps/glfw/src/null_init.c",
    "deps/glfw/src/null_joystick.c",
    "deps/glfw/src/null_monitor.c",
    "deps/glfw/src/null_window.c",
    "deps/glfw/src/osmesa_context.c",
    "deps/glfw/src/platform.c",
    "deps/glfw/src/vulkan.c",
    "deps/glfw/src/window.c",
};

const linux_sources = [_][]const u8{
    "src/linux_joystick.c",
    "src/posix_module.c",
    "src/posix_poll.c",
    "src/posix_thread.c",
    "src/posix_time.c",
    "src/xkb_unicode.c",
};

const linux_wl_sources = [_][]const u8{
    "src/wl_init.c",
    "src/wl_monitor.c",
    "src/wl_window.c",
};

const linux_x11_sources = [_][]const u8{
    "src/glx_context.c",
    "src/x11_init.c",
    "src/x11_monitor.c",
    "src/x11_window.c",
};

const windows_sources = [_][]const u8{
    "src/wgl_context.c",
    "src/win32_init.c",
    "src/win32_joystick.c",
    "src/win32_module.c",
    "src/win32_monitor.c",
    "src/win32_thread.c",
    "src/win32_time.c",
    "src/win32_window.c",
};
