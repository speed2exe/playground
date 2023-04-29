const std = @import("std");

pub fn main() !void {
    var a: u8 = 5;
    _ = a;
    var b: [5]u8 = .{ 1, 2, 3, 4, 5 };
    var c = b[0..];
    _ = c;
    var d: [5]c_int = .{ 1, 2, 3, 4, 5 };
    var e = d[0..];
    _ = e;
    var f: []const u8 = "hello";
    _ = f;
    var g: MyStruct = .{};
    _ = g;

    std.debug.print("end of test\n", .{});
}

const MyStruct = struct {
    a: u8 = 1,
    b: f32 = 2.0,
    c: []const u8 = "hello",
};
