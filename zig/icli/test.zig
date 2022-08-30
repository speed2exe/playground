const std = @import("std");

pub fn main() void {
    var s = S{};
    s.f(u8, 1);
}

const S = struct {
    fn f(self: *S, comptime T: type, value: T) void {
        _ = self;
        _ = T;
        _ = value;
    }
};

