const std = @import("std");
const testing = std.testing;
const string_reader = @import("./string_reader.zig");
const ring_buffer = @import("./ring_buffer.zig");

pub fn RingBufferedReader(
    comptime ReaderType: type,
    comptime buffer_size: comptime_int,
) type {
    return struct {
        const Self = @This();
        pub const Error = ReaderType.Error;
        pub const Reader = std.io.Reader(Self, Error, read);
        pub const RingBuffer = ring_buffer.RingBuffer(buffer_size);

        src: ReaderType,
        buffer: RingBuffer = .{},

        pub fn init(r: ReaderType) Self {
            return Self { .src = r };
        }

        pub fn read(self: *Self, dest: []u8) Error!usize {
            // fill buffer if empty
            if (self.buffer.unreadBytes() == 0) {
                const n = try self.buffer.readFrom(ReaderType, self.src);
                if (n == 0) {
                    return n;
                }
            }

            return self.buffer.read(dest);
        }
    };
}

test "RingBufferedReader" {
    var sr = string_reader.StringReader.init("123456789");
    var buffered_reader = RingBufferedReader(string_reader.StringReader.Reader, 4).init(sr.reader());

    {
        var dest: [6]u8 = undefined;
        const n = try buffered_reader.read(&dest);
        try testing.expectEqualSlices(u8, "1234", dest[0..n]);
    }

    {
        var dest: [2]u8 = undefined;
        const n = try buffered_reader.read(&dest);
        try testing.expectEqualSlices(u8, "56", dest[0..n]);
    }
    {
        var dest: [6]u8 = undefined;
        const n = try buffered_reader.read(&dest);
        try testing.expectEqualSlices(u8, "78", dest[0..n]);
    }
    {
        var dest: [1]u8 = undefined;
        const n = try buffered_reader.read(&dest);
        try testing.expectEqualSlices(u8, "9", dest[0..n]);
    }
}
