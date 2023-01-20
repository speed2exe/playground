const std = @import("std");
const tree_print = @import("tree_print.zig");
const k = @import("./other.zig");

usingnamespace @import("std");

pub fn main() !void {
    var lol = k.Something{};
    _ = lol;

    // const arr: [4]u8 = [_]u8{
    //     0b11111111,
    //     0b00000000,
    //     0b00000000,
    //     0b00000000,
    // };

    // const value = @bitCast(u32, arr);
    // // print value
    // std.log.info("value: {d}", .{value});

    // const data = comptimePrint(8);
    // std.log.info("data: {s}", .{data});
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
//
// pub fn comptimePrint(comptime n: comptime_int) []const u8 {
//     return std.fmt.comptimePrint("dd{d}bb", .{n});
// }
//
// fn lessThan(a: u8, b: u8) bool {
//     return a < b;
// }
//
// fn lessThanWithContext(Context: type, context: Context, a: u8, b: u8) bool {
//     _ = context;
//     lessThan(a, b);
// }
