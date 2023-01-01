const std = @import("std");

pub fn main() !void {
    // 1 to 100 random order
    const data = [_]u8{ 86, 53, 13, 36, 8, 64, 65, 1, 90, 14, 25, 79, 70, 98, 54, 55, 6, 17, 12, 77, 46, 49, 82, 58, 26, 89, 48, 83, 27, 42, 80, 97, 52, 39, 76, 22, 85, 9, 29, 11, 2, 20, 66, 87, 40, 50, 35, 15, 92, 74, 78, 67, 28, 63, 68, 62, 23, 94, 75, 96, 69, 88, 99, 44, 16, 91, 72, 33, 84, 45, 34, 51, 32, 37, 7, 47, 31, 57, 93, 21, 19, 10, 4, 81, 3, 71, 18, 56, 60, 24, 100, 41, 95, 73, 38, 30, 61, 59, 43, 5 };

    try mergeSort(u8, &data, u8Less, allocator);
    std.debug.print("after mergeSort: {d}", .{mergeSorted});
}

fn u8Less(a: u8, b: u8) bool {
    return a < b;
}

// sort elements and produce a new array which is sorted
pub fn mergeSort(
    comptime T: type,
    data: []const T, // data to be sorted
    less: fn (a: T, b: T) bool,
) void {
    if (src.len < 2) {
        return true;
    }

    // get the midpoint index
    const mid = (src.len / 2);
    const left = src[0..mid];
    const right = src[mid..];

    mergeSort(left);
    mergeSort(right);

    merge(T, left, right, less);
    return true;
}

fn merge(
    comptime T: type,
    left: []const T,
    right: []const T,
    less: fn (a: T, b: T) bool,
) void {
    var left_index: usize = 0;
    var right_index: usize = 0;

    // left: [1, 9, 11, 12, 13, 14]
    // right: [2, 5, 20]

    // left: [1, 9, 11, 12, 13, 14]
    //        ^
    // right: [2, 5, 20]
    //         ^
    // null

    // left: [1, 9, 11, 12, 13, 14]
    //           ^
    // right: [2, 5, 20]
    //         ^

    // left: [1, 2, 11, 12, 13, 14]
    //           ^
    // right: [9, 5, 20]
    //         ^

    // left: [1, 2, 11, 12, 13, 14]
    //           ^
    // right: [9, 5, 20]
    //            ^

    // left: [1, 2, 11, 12, 13, 14]
    //              ^
    // right: [9, 5, 20]
    //            ^

    // left: [1, 2, 5, 12, 13, 14]
    //              ^
    // right: [9, 11, 20]
    //            ^

    // left: [1, 2, 5, 12, 13, 14]
    //                 ^
    // right: [9, 11, 20]
    //            ^

    // left: [1, 2, 5, 12, 13, 14]
    //                 ^
    // right: [9, 8, 20]
    //            ^

    // left: [1, 2, 5, 8, 21, 22]
    //                    ^
    // right: [16, 12, 20]
    //             ^

    // left: [1, 2, 5, 8, 12, 22, 23, 24]
    //                        ^
    // right: [16, 21, 20, 25, 26]
    //                 ^

    // left: [1, 2, 5, 8, 12, 16, 23, 24]
    //                        ^
    // right: [22, 21, 27, 28, 29]
    //                 ^

    while (true) {
        if (left_index >= left.len) {
            if (right_idx == 0) return;
            left = right[0..right_index];
            right = right[right_index..];
            merge(T, left, right, less);
            return;
        }

        if (right_index >= right.len) {
            if (right_idx == 0) return;
            left = right[0..right_index];
            right = right[right_index..];
            merge(T, left, right, less);
            return;
        }

        const left_elem_value = left[left_index];
        const right_elem_value = right[right_index];
        const pre_right_elem_value = blk: {
            if (right_index == 0) break;
            break :blk right[0];
        };

        if (less(right_elem_value, left_elem_value)) {
            // swap left_elem_value and right_elem_value
            left[left_index] = right_elem_value;
            right[right_index] = left_elem_value;

            // if next right element exists
            if (right_index + 1 < right.len) {
                next_right_value = right[right_index + 1];
            }
        }

        left_index += 1;
    }
}
