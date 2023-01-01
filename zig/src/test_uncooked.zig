const std = @import("std");
const os = std.os;
const fs = std.fs;

pub fn main() !void {
    var tty: fs.File = try fs.cwd().openFile("/dev/tty", .{ .read = true, .write = true });
    var buffer: [5]u8 = undefined;

    // read a line from the tty
    var n = tty.read(&buffer);
    std.debug.print("n :{}", .{n});
    std.debug.print("buffer :{s}", .{buffer});
}
