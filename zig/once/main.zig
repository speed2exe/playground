const std = @import("std");

pub fn main() !void {
    someFn();
    std.debug.print("times: {d}\n", .{times});
    someFn();
    std.debug.print("times: {d}\n", .{times});
    someFn();
    std.debug.print("times: {d}\n", .{times});
    someFn();
    std.debug.print("times: {d}\n", .{times});
    someFn();
    std.debug.print("times: {d}\n", .{times});
}

var times: u8 = 0;
var myOnce = std.once(onceFn);

fn someFn() void {
    myOnce.call();
}

fn onceFn() void {
    times += 1;
}
