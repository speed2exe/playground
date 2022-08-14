const std = @import("std");

pub fn main() !void {

    // 1 to 100 random order
    const data = [_]u8{ 86, 53, 13, 36, 8, 64, 65, 1, 90, 14, 25, 79, 70, 98, 54, 55, 6, 17, 12, 77, 46, 49, 82, 58, 26,
        89, 48, 83, 27, 42, 80, 97, 52, 39, 76, 22, 85, 9, 29, 11, 2, 20, 66, 87, 40, 50, 35, 15, 92, 74, 78, 67, 28, 63,
        68, 62, 23, 94, 75, 96, 69, 88, 99, 44, 16, 91, 72, 33, 84, 45, 34, 51, 32, 37, 7, 47, 31, 57, 93, 21, 19, 10, 4,
        81, 3, 71, 18, 56, 60, 24, 100, 41, 95, 73, 38, 30, 61, 59, 43, 5};

    const mergeSorted = try mergeSort(u8, &data, u8Less, std.heap.page_allocator);
    std.debug.print("after mergeSort: {d}",.{mergeSorted});
}

fn u8Less(a: u8, b: u8) bool {
    return a < b;
}

// sort elements and produce a new array which is sorted
pub fn mergeSort (
    comptime T: type,
    data: []const T, // data to be sorted
    less: fn(a: T, b: T) bool,
    allocator: std.mem.Allocator,
) ![]const T {
    if (data.len < 2) {
        return data;
    }

    // initialize a new array for computation
    // require a total space of 2 * size of data
    var full = try allocator.alloc(T, data.len * 2);
    var src = full[0..data.len];
    var dest = full[data.len..];
    std.mem.copy(T, src, data);

    if (mergeSortWithOutput(T, src, dest, less)) {
        return full;
    } else {
        return full;
    }
}

// returns whether the final result is in src instead of dest
pub fn mergeSortWithOutput (
    comptime T: type,
    src: []T,
    dest: []T,
    less: fn(a: T, b: T) bool,
) bool {
    if (src.len < 2) {
        return true;
    }

    // get the midpoint index
    const mid = (src.len / 2);

    const left_src = src[0..mid];
    const right_src = src[mid..];

    const left_dest = dest[0..mid];
    const right_dest = dest[mid..];

    const left_result_in_src = mergeSortWithOutput(T, left_src, left_dest, less);
    const right_result_in_src = mergeSortWithOutput(T, right_src, right_dest, less);

    if (left_result_in_src) {
        if (!right_result_in_src) {
            std.mem.copy(T, right_src, right_dest);
        }
        merge(T, left_src, right_src, less, dest);
        return false;
    }

    // case for !left_result_in_src
    if (right_result_in_src) {
        std.mem.copy(T, right_dest, right_src);
    }
    merge(T, left_dest, right_dest, less, src);
    return true;
}

fn merge (
    comptime T: type,
    left: []const T,
    right: []const T,
    less: fn(a: T, b: T) bool,
    dest: []T,
) void {
    var left_idx: usize = 0;
    var right_idx: usize = 0;
    var dest_idx: usize = 0;

    while (true) {
        if (left_idx >= left.len) {
            std.mem.copy(T, dest[dest_idx..], right[right_idx..]);
            return;
        }
        if (right_idx >= right.len) {
            std.mem.copy(T, dest[dest_idx..], left[left_idx..]);
            return;
        }

        const left_elem_value = left[left_idx];
        const right_elem_value = right[right_idx];
        if (less(left_elem_value, right_elem_value)) {
            dest[dest_idx] = left_elem_value;
            left_idx += 1;
        } else {
            dest[dest_idx] = right_elem_value;
            right_idx += 1;
        }
        dest_idx += 1;
    }
}
