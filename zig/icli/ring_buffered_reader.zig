const std = @import("std");
const testing = std.testing;
const StringReader = @import("./string_reader.zig").StringReader;
const ring_buffer = @import("./ring_buffer.zig");

const USIZE_ZERO = @as(usize, 0);

pub fn RingBufferedReader(
    comptime Context: type,
    comptime readFn: fn (context: Context, buffer: []u8) anyerror!usize,
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

        pub fn read(self: *Self, dest: []u8) !usize {
            if (!(try self.ensureDataInBuffer())) {
                return USIZE_ZERO;
            }
            return self.buffer.read(dest);
        }

        pub fn readConst(self: *Self) ![]const u8 {
            if (!(try self.ensureDataInBuffer())) {
                return &[0]u8{};
            }
            return self.buffer.readConst();
        }

        fn ensureDataInBuffer(self: *Self) !bool {
            if (self.buffer.isEmpty()) {
                const n = try self.buffer.readFrom(Context, self.context, readFn);
                return n > 0;
            }
            return true;
        }
    };
}

test "RingBufferedReader" {
    var sr = StringReader.init("123456789");
    var buffered_reader = RingBufferedReader(*StringReader, StringReader.read, 4).init(&sr);

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
