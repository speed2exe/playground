const std = @import("std");
const LineReader = @import("./line_reader.zig").LineReader;

pub fn day1() !void {
    var left_ints: [1000]u32 = undefined;
    var right_ints: [1000]u32 = undefined;

    var line_reader: LineReader = .{};
    var i: usize = 0;
    while (try line_reader.next()) |line| : (i += 1) {
        // Example line
        // "61967   56543"
        //
        // since we know the shape of the input line
        // we can hardcode the indices
        const left = line[0..5];
        const right = line[8..13];
        left_ints[i] = try std.fmt.parseInt(u32, left, 10);
        right_ints[i] = try std.fmt.parseInt(u32, right, 10);
    }

    std.sort.pdq(u32, &left_ints, {}, cmp);
    std.sort.pdq(u32, &right_ints, {}, cmp);

    var acc_diff: u32 = 0;
    for (left_ints, right_ints) |left, right| {
        if (left < right) {
            acc_diff += right - left;
        } else {
            acc_diff += left - right;
        }
    }
    std.debug.print("part1 1: {}\n", .{acc_diff});

    var acc: u64 = 0;
    var left_ptr: usize = 0;
    var right_ptr: usize = 0;
    while (left_ptr < left_ints.len) : (left_ptr += 1) {
        const left_val = left_ints[left_ptr];
        var count: usize = 0;
        while (right_ptr < right_ints.len) : (right_ptr += 1) {
            const right_val = right_ints[right_ptr];
            if (left_val == right_val) {
                count += 1;
            } else if (left_val < right_val) {
                break;
            }
        }

        acc += count * left_val;
    }

    std.debug.print("part1 2: {}\n", .{acc});
}

fn cmp(_: void, a: u32, b: u32) bool {
    return a < b;
}
