const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn best (
    comptime T: type,
    better: fn(T, T) bool,
    data: []T,
) ?T {
    if (data.len ==  0) {
        return null;
    }

    var result: T = data[0];
    for (data) |value| {
        if (better(value, result)) {
            result = value;
        }
    }
    return result;
}

fn u8Better(a: u8, b: u8) bool {
    return a > b;
}

test "best" {
    // 1 to 100 random order
    var data = [_]u8{
        86, 53, 13, 36, 8, 64, 65, 1, 90, 14, 25, 79, 70, 98, 54, 55, 6, 17,
        12, 77, 46, 49, 82, 58, 26, 89, 48, 83, 27, 42, 80, 97, 52, 39, 76, 22,
        85, 9, 29, 11, 2, 20, 66, 87, 40, 50, 35, 15, 92, 74, 78, 67, 28, 63,
        68, 62, 23, 94, 75, 96, 69, 88, 99, 44, 16, 91, 72, 33, 84, 45, 34, 51,
        32, 37, 7, 47, 31, 57, 93, 21, 19, 10, 4, 81, 3, 71, 18, 56, 60, 24,
        100, 41, 95, 73, 38, 30, 61, 59, 43, 5
    };

    const result = best(u8, u8Better, &data) orelse unreachable;
    try expectEqual(@as(u8, 100), result);
}
