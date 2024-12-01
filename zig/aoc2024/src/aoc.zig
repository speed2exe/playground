const std = @import("std");
const log = std.log.scoped(.aoc);
const LineReader = @import("./line_reader.zig").LineReader;

pub fn day1() !void {
    var line_reader: LineReader = .{};
    while (try line_reader.next()) |line| {
        log.info("{s}", .{line});
    }
}
