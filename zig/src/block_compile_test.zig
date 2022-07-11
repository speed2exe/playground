const std = @import("std");

test "comptime expression" {
    comptime {
        std.log.warn("hello in comptime", .{});
    }
}
