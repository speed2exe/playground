const std = @import("std");
const aoc = @import("aoc");
const subcommander = @import("subcommander");
const log = std.log.scoped(.main);

pub fn main() !void {
    // TODO: link libc if on windows
    const args = std.os.argv;

    const cmd: subcommander.Command = .{
        .subcommands = &.{
            .{ .match = "day1", .execute = day1 },
            .{ .match = "day2", .execute = day2 },
        },
    };
    try cmd.run(args[1..]);
}

fn day1(input: *const subcommander.InputCommand) void {
    _ = input;
    aoc.day1() catch |err| logErrorExit(err);
}

fn day2(input: *const subcommander.InputCommand) void {
    _ = input;
    aoc.day2() catch |err| logErrorExit(err);
}

fn logErrorExit(err: anyerror) void {
    log.err("{any}", .{err});
    std.process.exit(@truncate(@intFromError(err)));
}
