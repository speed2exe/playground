const std = @import("std");
const builtin = @import("builtin");

pub fn main() void {
    std.debug.print("tag: {any}", .{builtin.os.tag});

    // var s = S{};
    // s.f(u8, 1);
}

const S = struct {
    fn f(self: *S, comptime T: type, value: T) void {
        _ = self;
        _ = T;
        _ = value;
    }
};

