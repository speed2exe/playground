const std = @import("std");
const testing = std.testing;

// Return the highest index(usize) which its value
// is less than all its next elems, if present.
// sorted_elems must be sorted and contains 1 or more elem.
pub fn binarySearch(
    comptime T: type,
    less: fn (a: T, b: T) bool,
    sorted_elems: []const T,
    target: T,
) usize {
    if (sorted_elems.len < 2) {
        return 0;
    }

    const mid_idx = sorted_elems.len / 2;
    const mid_elem = sorted_elems[mid_idx];

    if (less(mid_elem, target)) {
        return mid_idx + binarySearch(T, less, sorted_elems[mid_idx..], target);
    }

    return binarySearch(T, less, sorted_elems[0..mid_idx], target);
}

fn u32Less(a: u32, b: u32) bool {
    return a < b;
}

test "binarySearch" {
    const elems = [_]u32{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 };
    const target: u32 = 5;
    try testing.expectEqual(@as(usize, 4), binarySearch(u32, u32Less, elems[0..], target));
}

test "binarySearch" {
    const elems = [_]u32{ 0, 1, 2, 3, 4 };
    const target: u32 = 5;
    try testing.expectEqual(@as(usize, 4), binarySearch(u32, u32Less, elems[0..], target));
}
