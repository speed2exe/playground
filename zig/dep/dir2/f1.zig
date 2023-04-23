const hello = @import("../dir1/f1.zig").hello;
const std = @import("std");

pub fn hello2() void {
    std.debug.print("hello from dir2", .{});
    hello();
}
