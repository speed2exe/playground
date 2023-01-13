const std = @import("std");
const testing = std.testing;
const ring_buffer = @import("./ring_buffer.zig");

pub fn RingBufferedWriter(
    comptime Context: type,
    comptime writeFn: fn (context: Context, buffer: []const u8) anyerror!usize,
    comptime buffer_size: comptime_int,
) type {
    return struct {
        const Self = @This();
        pub const RingBuffer = ring_buffer.RingBuffer(buffer_size);

        context: Context,
        buffer: RingBuffer = .{},

        pub fn init(context: Context) Self {
            return Self{ .context = context };
        }

        // blocks until all bytes are written
        pub fn write(self: *Self, src: []const u8) anyerror!usize {
            var total_written: usize = 0;
            while (total_written < src.len) {
                const written = try self.buffer.write(src[total_written..]);
                total_written += written;
                if (self.buffer.isFull()) {
                    _ = try self.flush(); // ignore the number of bytes flushed
                }
            }
            return total_written;
        }

        pub fn flush(self: *Self) anyerror!usize {
            return self.buffer.writeTo(Context, self.context, writeFn);
        }
    };
}

test "test RingBufferedWriter" {
    const RingBuffer20 = ring_buffer.RingBuffer(20);
    var some_ring_buffer = RingBuffer20.init();

    var ring_buffered_writer = RingBufferedWriter(*RingBuffer20, RingBuffer20.write, 3).init(&some_ring_buffer);
    {
        const n = try ring_buffered_writer.write("0123456789");
        const m = try ring_buffered_writer.flush();
        try testing.expect(n == 10);
        try testing.expect(m == 1);
        const written_buffer = try some_ring_buffer.readConst();
        try testing.expectEqualSlices(u8, "0123456789", written_buffer[0..n]);
    }
}
