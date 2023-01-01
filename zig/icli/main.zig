const std = @import("std");
const icli = @import("./icli.zig");

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const leaked = gpa.deinit();
        if (leaked) {
            std.log.err("got leaked!", .{});
        }
    }

    runApp(allocator) catch |err| {
        std.debug.print("app stopped: {}", .{err});
    };
}

fn runApp(allocator: std.mem.Allocator) !void {
    const comptime_settings = comptime icli.ComptimeSettings{
        .log_file_path = "app.log",
    };
    const settings = icli.Settings{
        .allocator = allocator,
        .execute = execute,
    };

    const cli_type = comptime icli.InteractiveCli(comptime_settings);
    var cli = try cli_type.init(settings);
    defer cli.deinit();

    try cli.run();

    // need to pass in option

    // need to pass in function for completion
}

fn execute(cmd: []const u8) bool {
    std.debug.print("executing command: {s}\n", .{cmd});

    // continue
    return false;
}

// TODO:
// fn suggest(cmd: []const u8, cursor_position: usize) [][]const u8 {
//
// }

//
