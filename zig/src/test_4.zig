const std = @import("std");

test "should throw comp err" {
    std.log.warn("hello {}", .{});
}
