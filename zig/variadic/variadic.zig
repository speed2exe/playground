const std = @import("std");

pub fn main() !void {
    var a: c_int = 1;
    var b: c_int = 2;
    var c: c_int = 3;
    std.log.info("add(1, 2, 3): {}", .{add(a, b, c)});
}

fn add(count: i32, ...) callconv(.C) i32 {
    std.log.info("count: {}", .{count});
    return 0;
}
