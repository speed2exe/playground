const std = @import("std");
const tree_print = @import("tree_print.zig");

pub fn main() !void {


    var ll = [_]T {
        T{.a = "r", .b = 1},
    };

    const l: []T = &ll;

    const m_t = std.ComptimeStringMap(u8, l);

    const v = m_t.get("u") orelse unreachable;
    std.log.debug("v={}", .{v});
}

const T = struct {
    a: []const u8,
    b: u8,
};
