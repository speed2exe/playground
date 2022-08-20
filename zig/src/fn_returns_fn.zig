const std = @import("std");
const expectEqual = std.testing.expectEqual;

fn lessThan(comptime T: type) fn(T, T) bool {
    return struct {
        fn lessThan(a: T, b: T) bool {
            return a < b;
        }
    }.lessThan;
}

test "test lessThan" {
    const result = lessThan(i8)(8, 9);
    try expectEqual(true, result);
}
