const std = @import("std");

pub fn myfunc() void {
    std.debug.print("Hello, World from my module!\n", .{});
}
