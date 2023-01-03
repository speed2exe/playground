const std = @import("std");
const tree_print = @import("tree_print.zig");

pub fn main() !void {
    const k = comptime comptimePrint(10);
    std.log.debug("v={*}", .{k});
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

// bugged
// pub fn comptimePrint(n: comptime comptime_int) []const u8 {
//     return std.fmt.comptimePrint("dd{d}bb", .{n});
// }
