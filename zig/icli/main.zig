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
    const settings = icli.Settings{
        .log_file_path = "app.log",
        .suggestFn = suggest,
    };

    const cli_type = comptime icli.InteractiveCli(settings);
    var cli = try cli_type.init(allocator);
    defer cli.deinit();

    try cli.run(void, {}, execute);

    // need to pass in option

    // need to pass in function for completion
}

fn execute(_: void, cmd: []const u8) bool {
    std.debug.print("executing command: {s}\n", .{cmd});

    // continue
    return false;
}

// TODO:
// fn suggest(cmd: []const u8, cursor_position: usize) [][]const u8 {
//
// }

//

var s = [_]icli.Suggestion{
    .{ .text = "foo", .description = "foo description" },
    .{ .text = "bar", .description = "bar description" },
    .{ .text = "baz", .description = "baz description" },
};

fn suggest(pre_cursor_buffer: []const u8, post_cursor_buffer: []const u8) []icli.Suggestion {
    _ = pre_cursor_buffer;
    _ = post_cursor_buffer;
    return &s;
}
