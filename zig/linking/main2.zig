const std = @import("std");

pub fn main() !void {
    const a: i32 = 1;
    const b: i32 = 2;
    var lib = try std.DynLib.open("./libmymath.so");
    defer lib.close();

    var add = lib.lookup(*const fn (i32, i32) i32, "add").?;
    std.debug.print("{any}\n", .{add});
    std.debug.print("type: {any}\n", .{@TypeOf(add)});

    const x: i32 = add(a, b);
    std.debug.print("x: {d}\n", .{x});
}
