const std = @import("std");
const tree_print = @import("tree_print.zig");

pub fn main() !void {
    const data = comptimePrint(8);
    std.log.info("data: {s}", .{data});
}

// fn D(comptime T: type) type {
//     return struct {
//         const Self = @This();
//         a: T,
//         b: T,
//
//         fn init(v: T) Self {
//             return Self{
//                 .a = v,
//                 .b = undefined,
//             };
//         }
//     };
// }

pub fn comptimePrint(comptime n: comptime_int) []const u8 {
    return std.fmt.comptimePrint("dd{d}bb", .{n});
}

fn lessThan(a: u8, b: u8) bool {
    return a < b;
}

fn lessThanWithContext(Context: type, context: Context, a: u8, b: u8) bool {
    _ = context;
    lessThan(a, b);
}
