const std = @import("std");

const input = std.io.getStdIn();
const allocator = std.heap.page_allocator;

pub fn main() !void {
    var result: i32 = 0;

    std.io.BufferedReader(4096, input);

    input.readUntilDelimiterOrEofAlloc(
        allocator,
        '\n',
    );

    // stream from std input
    std.debug.print("{d}", .{result});
}
