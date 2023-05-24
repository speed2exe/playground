const std = @import("std");
const os = std.os;

const c = @cImport({
    @cDefine("_GNU_SOURCE", {});
    @cInclude("sys/mman.h");
    @cInclude("unistd.h");
});

pub fn main() !void {
    const fd = c.memfd_create("test", 0);
    std.log.info("fd is {d}", .{fd});
    const m = try std.os.write(fd, "hello in test file");
    std.log.info("wrote {d} bytes", .{m});
    const pid = c.getpid();
    std.log.info("pid is {d}", .{pid});
    try os.fsync(fd);

    var buffer: [1024]u8 = undefined;
    const n = try os.read(fd, &buffer);

    std.log.info("read {d} bytes", .{n});
    std.log.info("buffer is {s}", .{buffer[0..n]});

    std.time.sleep(std.time.ns_per_s * 2000);
}
