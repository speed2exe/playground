const std = @import("std");

pub fn main() void {
    var mask: usize = 0b1 & 0b0;
    std.debug.print("mask: {d}",.{mask});
}
