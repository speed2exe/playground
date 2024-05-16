const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "build_args",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // option when compiling
    const car_name = b.option([]const u8, "car", "choose car please") orelse "noob car"; // -Dcar=your_car
    const pro_mode = detectProMode();

    // create options options
    const car_options = b.addOptions();
    car_options.addOption([]const u8, "car", car_name);
    car_options.addOption(bool, "pro_mode", pro_mode);

    // add options to the root module
    exe.root_module.addOptions("car_options", car_options);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn detectProMode() bool {
    // Yes! I am Pro!
    return true;
}
