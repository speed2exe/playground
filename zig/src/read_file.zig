const std = @import("std");
const system = @import("system");
const os = std.os;

pub fn main() !void {
    var file = try std.fs.openFileAbsolute(
        "/home/zx/input.txt",
        std.fs.File.OpenFlags{},
    );
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const b = try buf_reader.reader().readByte();
    std.log.info("byte is {d}", .{b});
}
