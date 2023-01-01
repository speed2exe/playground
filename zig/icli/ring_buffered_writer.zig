const std = @import("std");
const testing = std.testing;
const ring_buffer = @import("./ring_buffer.zig");

pub fn RingBufferedWriter(
    comptime WriterType: type,
    comptime buffer_size: comptime_int,
) type {
    return struct {
        const Self = @This();
        pub const Error = WriterType.Error;
        pub const Writer = std.io.Writer(*Self, Error, write);
        pub const RingBuffer = ring_buffer.RingBuffer(buffer_size);

        dest: WriterType,
        buffer: RingBuffer = .{},

        pub fn init(w: WriterType) Self {
            return Self{ .dest = w };
        }

        pub fn writer(self: *Self) Writer {
            return Writer{ .context = self };
        }

        // blocks until all bytes are written
        pub fn write(self: *Self, src: []const u8) Error!usize {
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

        pub fn flush(self: *Self) WriterType.Error!usize {
            return self.buffer.writeTo(WriterType, self.dest);
        }
    };
}

test "test RingBufferedWriter" {
    const RingBuffer5 = ring_buffer.RingBuffer(20);
    var some_ring_buffer = RingBuffer5.init();
    var writer = some_ring_buffer.writer();

    var ring_buffered_writer = RingBufferedWriter(RingBuffer5.Writer, 3).init(writer);
    {
        const n = try ring_buffered_writer.write("0123456789");
        const m = try ring_buffered_writer.flush();
        try testing.expect(n == 10);
        try testing.expect(m == 1);
        const written_buffer = try some_ring_buffer.readConst();
        try testing.expectEqualSlices(u8, "0123456789", written_buffer[0..n]);
    }
}
