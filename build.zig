const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = std.zig.CrossTarget{ .os_tag = .windows, .cpu_arch = .x86_64 };
    const optimize = b.standardOptimizeOption(.{});

    const download = b.addExecutable(.{
        .name = "download",
        .root_source_file = .{ .path = "download_deps.zig" },
        .target = std.zig.CrossTarget.fromTarget(builtin.target),
        .optimize = .Debug,
    });
    const download_cmd = b.addRunArtifact(download);

    const exe = b.addExecutable(.{
        .name = "giza-win32-example",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const zigwin32_module = b.dependency("win32", .{}).module("zigwin32");
    const cairo_module = b.dependency("giza", .{}).module("cairo");
    exe.addModule("win32", zigwin32_module);
    exe.addModule("cairo", cairo_module);
    exe.addObjectFile(.{ .path = "deps/cairo-windows-1.17.2/lib/x64/cairo.lib" });
    exe.subsystem = .Windows;

    const file = b.addInstallBinFile(.{ .path = "deps/cairo-windows-1.17.2/lib/x64/cairo.dll" }, "cairo.dll");
    file.step.dependOn(&download_cmd.step);

    exe.step.dependOn(&file.step);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
