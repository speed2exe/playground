const std = @import("std");
const stdout = std.io.getStdOut();

pub fn main() void {
    writeToStdOut("hello, world");
}

fn writeToStdOut(data: []const u8) void {
    _ = stdout.write(data) catch {};
}
