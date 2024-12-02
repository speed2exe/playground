const std = @import("std");
const print = std.debug.print;
const LineReader = @import("./line_reader.zig").LineReader;
const assert = std.debug.assert;

pub fn day2() !void {
    // var safe_count: u32 = 0;

    // 8 is max number of elements in a line
    // 0 is treated as not exists
    var input: [1000][8]u8 = undefined;
    var input_sliced: [1000][]u8 = undefined;
    { // fill in data
        var line_reader: LineReader = .{};
        var i: usize = 0;
        while (try line_reader.next()) |line| : (i += 1) {
            var iter = std.mem.splitScalar(u8, line, ' ');
            var j: usize = 0;
            while (iter.next()) |num_str| : (j += 1) {
                input[i][j] = try std.fmt.parseInt(u8, num_str, 10);
            }
            input_sliced[i] = input[i][0..j];
        }
    }
    print("safeCount: {d}\n", .{countSafe(&input_sliced)});
    print("safeCountDamped: {d}\n", .{countSafeDamped(&input_sliced)});
    print("safeCountDampedAlloc: {d}\n", .{try countSafeDampedAlloc(&input_sliced)});
}

fn countSafe(levelss: []const []const u8) u16 {
    var safe_count: u16 = 0;
    for (levelss) |levels| {
        if (isSafe(levels[0], levels[1..])) {
            safe_count += 1;
        }
    }
    return safe_count;
}

fn countSafeDampedAlloc(levelss: []const []const u8) !u16 {
    var safe_count: u16 = 0;
    const alloc = std.heap.page_allocator;
    for (levelss, 0..) |levels, k| {
        for (levels, 0..) |_, i| {
            var new_levels = std.ArrayList(u8).init(alloc);
            defer new_levels.deinit();

            for (levels, 0..) |_, j| {
                if (i != j) {
                    try new_levels.append(levels[j]);
                }
            }

            const items = new_levels.items;
            if (isSafe(items[0], items[1..])) {
                safe_count += 1;
                _ = k;
                // print("{d}\n", .{k});
                break;
            }
        }
    }
    return safe_count;
}

fn isSafeDampedAlloc(levels: []const u8) !bool {
    const alloc = std.heap.page_allocator;
    for (levels, 0..) |_, i| {
        var new_levels = std.ArrayList(u8).init(alloc);
        defer new_levels.deinit();

        for (levels, 0..) |_, j| {
            if (i != j) {
                try new_levels.append(levels[j]);
            }
        }

        const items = new_levels.items;
        if (isSafe(items[0], items[1..])) {
            return true;
        }
    }
    return false;
}

fn countSafeDamped(levelss: []const []const u8) u16 {
    var safe_count: u16 = 0;
    for (levelss, 0..) |levels, i| {
        _ = i;
        if (isSafe(levels[1], levels[2..])) {
            // skip first element
            safe_count += 1;
            // print("{d}\n", .{i});
        } else if (isSafeDamped(levels[0], levels[1..])) {
            safe_count += 1;
            // print("{d}\n", .{i});
        }
    }
    return safe_count;
}

// 57, 60, 62, 64, 63, 64, 65
// 9,  <   >   @   ?   @   A
fn isSafeDamped(cur: u8, levels: []const u8) bool {
    assert(levels.len > 0);
    const next = levels[0];
    const is_asc: bool = next > cur;
    const is_safe = safeDiff(cur, next, is_asc);
    if (is_safe) {
        return isSafeDampedIncr(cur, next, levels[1..]);
    }
    return isSafe(cur, levels[1..]);
}

fn isSafeDampedIncr(prev: u8, cur: u8, rest: []const u8) bool {
    if (rest.len == 0) return true;
    const is_asc: bool = cur > prev;
    const next = rest[0];
    const is_safe = safeDiff(cur, next, is_asc) and safeDiff(prev, cur, is_asc);
    if (is_safe) {
        return isSafeDampedIncr(cur, next, rest[1..]);
    }

    return isSafeIncr(prev, next, rest[1..]);
}

fn isSafe(cur: u8, levels: []const u8) bool {
    assert(levels.len > 0);
    const next = levels[0];
    const is_asc: bool = next > cur;
    const is_safe = safeDiff(cur, next, is_asc);
    if (is_safe) return isSafeIncr(cur, next, levels[1..]);
    return false;
}

fn isSafeIncr(prev: u8, cur: u8, levels: []const u8) bool {
    if (levels.len == 0) return true;
    const next = levels[0];
    const is_asc: bool = cur > prev;
    const is_safe = safeDiff(cur, next, is_asc) and safeDiff(prev, cur, is_asc);
    if (is_safe) return isSafeIncr(cur, next, levels[1..]);
    return false;
}

fn safeDiff(cur: u8, next: u8, is_asc: bool) bool {
    const diff = blk: {
        if (is_asc) {
            if (cur > next) {
                return false;
            } else {
                break :blk next - cur;
            }
        } else {
            if (cur < next) {
                return false;
            } else {
                break :blk cur - next;
            }
        }
    };
    return diff >= 1 and diff <= 3;
}
