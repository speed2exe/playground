// Goal: create a poc on java stream like programming

const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    var a = myType{};
    a.hello();
}

const myType = struct {
    a: ?u8 = null,

    fn hello(self: *myType) void {
        goodbye(self);
    }

    fn goodbye(self: *myType) void {
        _ = self;
        print("before return from goodbye fn", .{});
    }
};
