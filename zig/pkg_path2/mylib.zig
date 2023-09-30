const std = @import("std");

pub fn myfunc() void {
    std.debug.print("mylib: Hello, world!\n", .{});
}
