const std = @import("std");
const print = std.debug.print;
const Loop = std.event.Loop;

pub fn main() !void {
    var loop: Loop = undefined;
    try loop.initMultiThreaded();
    defer loop.deinit();

    loop.initThreadPool

    print("loop: {any}",.{@TypeOf(loop)});
}
