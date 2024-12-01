const std = @import("std");
const print = std.debug.print;

pub fn withLocation(
    comptime loc: std.builtin.SourceLocation,
    comptime fmt: []const u8,
    args: anytype,
) void {
    const fmt_with_location = std.fmt.comptimePrint("{s}:{d}:{d}: {s}", .{
        loc.file,
        loc.line,
        loc.column,
        fmt,
    });
    print(fmt_with_location, args);
}
