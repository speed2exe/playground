// create sort algorithm for generic types
// quick and merge

const std = @import("std");
const testing = std.testing;
// const print = std.debug.print;

test "benchmark quickSort 1-100" {
    // 1 to 100 random order
    var data = [_]u8 {
        86, 53, 13, 36, 8, 64, 65, 1, 90, 14, 25, 79, 70, 98, 54, 55, 6, 17,
        12, 77, 46, 49, 82, 58, 26, 89, 48, 83, 27, 42, 80, 97, 52, 39, 76, 22,
        85, 9, 29, 11, 2, 20, 66, 87, 40, 50, 35, 15, 92, 74, 78, 67, 28, 63,
        68, 62, 23, 94, 75, 96, 69, 88, 99, 44, 16, 91, 72, 33, 84, 45, 34, 51,
        32, 37, 7, 47, 31, 57, 93, 21, 19, 10, 4, 81, 3, 71, 18, 56, 60, 24,
        100, 41, 95, 73, 38, 30, 61, 59, 43, 5
    };

    const now = std.time.nanoTimestamp();
    defer {
        const then = std.time.nanoTimestamp();
        std.log.warn("quicksort nano sec: {d}",.{then - now});
    }

    quickSort(u8, &data, u8Less);
}

test "benchmark std.sort 1-100" {
    // 1 to 100 random order
    var data = [_]u8 {
        86, 53, 13, 36, 8, 64, 65, 1, 90, 14, 25, 79, 70, 98, 54, 55, 6, 17,
        12, 77, 46, 49, 82, 58, 26, 89, 48, 83, 27, 42, 80, 97, 52, 39, 76, 22,
        85, 9, 29, 11, 2, 20, 66, 87, 40, 50, 35, 15, 92, 74, 78, 67, 28, 63,
        68, 62, 23, 94, 75, 96, 69, 88, 99, 44, 16, 91, 72, 33, 84, 45, 34, 51,
        32, 37, 7, 47, 31, 57, 93, 21, 19, 10, 4, 81, 3, 71, 18, 56, 60, 24,
        100, 41, 95, 73, 38, 30, 61, 59, 43, 5
    };

    const now = std.time.nanoTimestamp();
    defer {
        const then = std.time.nanoTimestamp();
        std.log.warn("std.sort nano sec: {d}",.{then - now});
    }
    std.sort.sort(u8, &data, @as(u8, 0), u8LessWithContex);
}

test "quickSort u8" {
    var array = [_]u8{3,2,5,9,7,6,4, 10, 99, 77, 88,55, 44, 22, 33};
    quickSort(u8, &array, u8Less);

    var expected = [_]u8 { 2, 3, 4, 5, 6, 7, 9, 10, 22, 33, 44, 55, 77, 88, 99 };
    try testing.expectEqualSlices(u8,
        &expected,
        &array,
    );
}

test "quickSort string" {
    var string_array = [_][]const u8{"z", "b", "ac", "ab", "bc", "ba", "a"};
    quickSort([]const u8, &string_array, stringLessThan);

    var expected = [_][]const u8{ "a", "b", "z", "ab", "ac", "ba", "bc" };
    try testing.expectEqualSlices([]const u8,
        &expected,
        &string_array,
    );
}

fn u8Less(a: u8, b: u8) bool {
    return a < b;
}

fn u8LessWithContex(c: u8, a: u8, b: u8) bool {
    _ = c;
    return a < b;
}

// custom string sorting rules
fn stringLessThan(a: []const u8, b: []const u8) bool {
    if (a.len < b.len) {
        return true;
    }
    if (a.len > b.len) {
        return false;
    }
    for (a) |a_val, i| {
        const b_val = b[i];
        if (a_val < b_val) {
            return true;
        }

        if (a_val > b_val) {
            return false;
        }
    }
    return false;
}

// quickSort sorts the data inplace
// quickSort is basically recursive partitioning
pub fn quickSort (
    comptime T: type,
    data: []T, // array to be sorted
    less: fn(a: T, b: T) bool,
) void {
    if (data.len < 2) { // no need to sort
        return;
    }

    // pick a pivot and get the index
    // use first elem, TODO: improve
    var pivot_idx = partition(T, data[0], data, less);
    // edge case where no partitioning happens
    // pivot_idx = becomeOneIfZeroBranchless(usize, pivot_idx);
    if (pivot_idx < 1) {
        pivot_idx += 1;
    }

    const left = data[0..pivot_idx];
    // print("left: {d}\n",.{left});
    const right = data[pivot_idx..];
    // print("right: {d}\n",.{right});

    quickSort(T, left, less);
    quickSort(T, right, less);
}

// returns the index that indicates the 
// equal or greater than the pivot_value
fn partition(
    comptime T: type,
    pivot_value: T,
    data: []T,
    less: fn(a: T, b: T) bool,
) usize {
    // print("before partition: {d}\n",.{data});
    // defer {
    //     print("after partition: {d}\n",.{data});
    // }

    var res_idx: usize = 0;
    for (data) |data_value, data_idx| {
        // print("data_value: {d}, data_idx: {}\n", .{data_value, data_idx});

        if (less(data_value, pivot_value)) {
            // print("{d} is less then {d}\n", .{data_value, pivot_value});
            // put the data_value to the 

            const temp = data[res_idx];
            data[res_idx] = data[data_idx];
            data[data_idx] = temp;
            res_idx += 1;
        }
    }   

    return res_idx;
}

fn becomeOneIfZeroBranchless(comptime T: type, x: T) T {
    // works for unsigned integers
    // overflow if x is bigger than max_value - 2
    // created just for fun :)

    // 0 => 1
    // 1 => 1
    // 2 => 2
    // 3 => 3
    // 4 => 4

    return ((x + 2) / (x + 1)) - 1 + x;
}
