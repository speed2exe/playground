const std = @import("std");
const tree_print = @import("tree_print.zig");

pub fn main() !void {
    std.log.debug("v={}", .{v});
}

fn D(comptime T: type) type {
    return struct {
        const Self = @This();
        a: T,
        b: T,

        fn init(v: T) Self {
            return Self{
                .a = v,
                .b = undefined,
            };
        }
    };
}
