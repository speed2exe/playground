const std = @import("std");

pub fn main() void {
    // var mask: usize = 0b1 & 0b0;
    // std.debug.print("mask: {d}",.{mask});

    var data = [_]u8{1,2,3,4,5};
    var full_slice: []u8 = &data;
    const mid_idx = 3;
    var part1 = full_slice[0..mid_idx];
    var part2 = full_slice[mid_idx..];

    var parts: [][]u8 = undefined;
    parts.len = 2;
    parts[0] = part1;
    parts[2] = part2;

    std.debug.print("parts: {d}", .{parts});
}
