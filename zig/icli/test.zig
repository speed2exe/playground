const std = @import("std");

pub fn main() void {
    // var a: usize = 1;
    std.debug.print("*a: {}",.{@TypeOf(*u8)});
}
