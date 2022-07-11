const std = @import("std");

pub fn getString() []const u8 {
    return "hello";
}

test "compile time warn" {
    {}
    const a = comptime getString();
    std.log.warn(a, .{});
}
