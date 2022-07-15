const std = @import("std");
const f1 = @import("f1.zig");
const testing = std.testing;

export fn add(a: i32, b: i32) i32 {
    return a + b;
}


test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}

test "test min" {
    try testing.expect(false);
}
