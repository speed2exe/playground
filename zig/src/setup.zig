const std = @import("std");

const globalInt :u32 = 8;

pub fn main() void {
    // comptime comptimeFunc();
    std.fmt.allocPrint()
}

// things that need to be compiled in comptime
// fn comptimeFunc() void {
//     globalInt.* = 9;
// }
