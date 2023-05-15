const std = @import("std");

pub fn main() !void {
    {
        var dest = [_]u8{0} ** 5;
        var src = [_]u8{1} ** 5;
        @memcpy(&dest, &src);
        std.log.info("dest is {d}", .{dest});
    }
    {
        var dest = [_]u8{0} ** 3;
        var src = [_]u8{1} ** 5;
        var src_ptr: [*]u8 = &src;
        @memcpy(&dest, src_ptr);
        std.log.info("dest is {d}", .{dest});
    }
}
