const std = @import("std");
const max_usize = std.math.maxInt(usize);
const allocator = std.heap.page_allocator;

fn main () !void {
    var stdin = std.io.getStdIn().reader();
    while (true) {
        const line = try stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', max_usize) orelse return;

    }

}

fn
