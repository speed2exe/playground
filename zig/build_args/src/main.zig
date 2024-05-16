const std = @import("std");
const car_options = @import("car_options"); // values are set during compile time

pub fn main() !void {
    std.debug.print("I drive a {s}\n", .{car_options.car}); // zig build -Dcar=toyota -> I drive a toyota
    var args_it = std.process.args();
    while (args_it.next()) |arg| {
        // zig build run -- arg1 arg2 ...
        // first arg is the path to the executable
        // second arg is the first argument given
        // third arg is the second argument given
        // ...
        std.debug.print("arg given: {s}\n", .{arg});
    }
}
