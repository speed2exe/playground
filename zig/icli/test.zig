const std = @import("std");
const tree_print = @import("tree_print.zig");

pub fn main() !void {
    const l = .{
        .{ "r", @as(u8, 1) },
    };

    const m_t = std.ComptimeStringMap(u8, comptime l);

    var v = m_t.get("r") orelse unreachable;
    std.log.debug("v={}", .{v});
}

const T = struct {
    a: []const u8,
    b: u8,
};
