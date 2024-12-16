const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "W",
        .root_source_file = b.path("main.zig"),
        .target = target,
        .optimize = optimize,
        .single_threaded = true,
        .unwind_tables = false,
    });
    exe.error_limit = if (optimize == .Debug or optimize == .ReleaseSafe) 0xff else 0;
    // TODO: test this
    //exe.use_llvm=false;
    //exe.use_lld=false;

    exe.linkLibC();
    exe.linkSystemLibrary("wayland-client");

    b.installArtifact(exe);
}
