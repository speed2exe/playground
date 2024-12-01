const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const aoc = b.createModule(.{
        .root_source_file = b.path("./src/aoc.zig"),
        .target = target,
        .optimize = optimize,
    });

    const subcommander = b.dependency("subcommander", .{}).module("subcommander");

    const exe = b.addExecutable(.{
        .name = "aoc",
        .root_source_file = b.path("./src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);
    exe.root_module.addImport("aoc", aoc);
    exe.root_module.addImport("subcommander", subcommander);
    const run_cmd = b.addRunArtifact(exe);

    // `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // `zig build run`
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const aoc_tests = b.addTest(.{
        .root_source_file = b.path("./src/aoc.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_aoc_tests = b.addRunArtifact(aoc_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_aoc_tests.step);
}
