// Finding min and max with 3/2n-2 comparison instead of 2n-2 comparison
const std = @import("std");
const expectedEqual = std.testing.expectEqual;

pub fn MinMaxResult(comptime T: type) type {
    return struct {
        min: T,
        max: T,
    };
}

pub fn minMax (
    comptime T: type,
    lessThan: fn(T, T) bool,
    data: []T,
) ?MinMaxResult(T) {
    if (data.len == 0) {
        return null;
    }

    var min: T = data[0];
    var max: T = data[0];

    {
        var index: usize = 1;
        while (index < data.len) : (index += 2) { // compare in pairs
            const first = data[index];
            const second = if (index+1 < data.len) data[index+1] else {
                if (!lessThan(first, max)) { // first >= max
                    max = first;
                }
                if (lessThan(first, min)) { // first < min
                    min = first;
                }
                continue;
            };

            var smaller = first;
            var bigger = second;
            if (lessThan(bigger, smaller)){
                const temp = smaller;
                smaller = bigger;
                bigger = temp;
            }

            if (lessThan(smaller, min)) {
                min = first;
            }
            if (!lessThan(bigger, max)) {
                max = bigger;
            }
        }
    }

    return MinMaxResult(T) {
        .min = min,
        .max = max,
    };
}

fn u8less(a: u8, b: u8) bool {
    return a < b;
}

test "min max optimal comparison" {
    // 1 to 100 random order
    var data = [_]u8{
        86, 53, 13, 36, 8, 64, 65, 1, 90, 14, 25, 79, 70, 98, 54, 55, 6, 17,
        12, 77, 46, 49, 82, 58, 26, 89, 48, 83, 27, 42, 80, 97, 52, 39, 76, 22,
        85, 9, 29, 11, 2, 20, 66, 87, 40, 50, 35, 15, 92, 74, 78, 67, 28, 63,
        68, 62, 23, 94, 75, 96, 69, 88, 99, 44, 16, 91, 72, 33, 84, 45, 34, 51,
        32, 37, 7, 47, 31, 57, 93, 21, 19, 10, 4, 81, 3, 71, 18, 56, 60, 24,
        100, 41, 95, 73, 38, 30, 61, 59, 43, 5
    };
    const result = minMax(u8, u8less, &data) orelse unreachable;
    try expectedEqual(@as(u8, 1), result.min);
    try expectedEqual(@as(u8, 100), result.max);
}
