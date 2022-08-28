const std = @import("std");
const testing = std.testing;
const string_reader = @import("./string_reader.zig");
const StringReader = string_reader.StringReader;

pub fn RingBuffer (
    comptime buffer_size: comptime_int,
    comptime ReaderType: type,
) type {
    return struct {
        pub const ReadError = ReaderType.Error;

        const Self = @This();

        source: ReaderType,
        buffer: [buffer_size]u8 = undefined,

        // inclusive
        head: usize = 0,
        // exclusive
        tail: usize = 0,

        pub const Reader = std.io.Reader(*Self, ReadError, read);

        pub fn init(source: ReaderType) Self {
            return Self { .source = source };
        }

        pub fn reader(self: *Self) Reader {
            return Reader { .context = self };
        }

        pub fn read(self: *Self, dest: []u8) !usize {
            const unread_count = self.unread();
            if (dest.len > unread_count) { // can read more to fill dest
                try self.load();
            }
            return ringCopy(dest, &self.buffer, &self.head, self.tail);
        }

        // Get view of next set of input without copying
        pub fn readConst(self: *Self) ![]const u8 {
            if (self.unread() == 0) {
                try self.load();
            }
            if (self.tail > self.head) {
                const view = self.buffer[self.head..self.tail];
                self.head = self.tail;
                return view;
            }
            const view = self.buffer[self.head..];
            self.head = 0;
            return view;
        }

        pub fn load(self: *Self) !void {
            if (self.head == self.tail) {
                self.head = 0;
                self.tail = try self.source.read(&self.buffer);
                return;
            }

            if (self.tail > self.head) {
                self.tail += try self.source.read(self.buffer[self.tail..]);
                if (self.tail == self.buffer.len and self.head > 1) {
                    self.tail = try self.source.read(self.buffer[0..self.head - 1]);
                }
                return;
            }

            self.tail += try self.source.read(self.buffer[self.tail..self.head - 1]);
        }

        pub fn unread(self: *Self) usize {
            return ringUnread(self.head, self.tail, self.buffer.len);
        }
    };
}

test "ringBuffer" {
    var input = StringReader.init("0123456789");
    var input_reader = input.reader();
    var ring_buffer = RingBuffer(5, StringReader.Reader).init(input_reader);
    var ring_buffer_reader = ring_buffer.reader();

    {
        var buffer: [2]u8 = undefined;
        const n = try ring_buffer_reader.read(&buffer);

        const expected = "01";
        try testing.expect(n == 2);
        try testing.expect(ring_buffer.unread() == 3);
        try testing.expectEqualSlices(u8, expected, &buffer);

        const expected_buffer_contents = "01234";
        try testing.expectEqualSlices(u8, expected_buffer_contents, &ring_buffer.buffer);
    }
    {
        try ring_buffer.load();
        const expected_buffer_contents = "51234";
        try testing.expect(ring_buffer.unread() == 4);
        try testing.expectEqualSlices(u8, expected_buffer_contents, &ring_buffer.buffer);
    }
    {
        var buffer: [10]u8 = undefined;
        const n = try ring_buffer_reader.read(&buffer);

        const expected = "2345";
        try testing.expectEqual(n, 4);
        try testing.expect(ring_buffer.unread() == 0);
        try testing.expectEqualSlices(u8, expected, buffer[0..4]);
    }
    {
        var buffer: [1]u8 = undefined;
        const n = try ring_buffer_reader.read(&buffer);
        const expected = "6";
        try testing.expect(n == expected.len);
        try testing.expect(ring_buffer.unread() == 3);
        try testing.expectEqualSlices(u8, expected, buffer[0..expected.len]);

        const expected_buffer_contents = "67894";
        try testing.expectEqualSlices(u8, expected_buffer_contents, &ring_buffer.buffer);
    }
    {
        var buffer: [1]u8 = undefined;
        const n = try ring_buffer_reader.read(&buffer);
        const expected = "7";
        try testing.expect(n == expected.len);
        try testing.expect(ring_buffer.unread() == 2);
        try testing.expectEqualSlices(u8, expected, buffer[0..expected.len]);

        const expected_buffer_contents = "67894";
        try testing.expectEqualSlices(u8, expected_buffer_contents, &ring_buffer.buffer);
    }
    {
        var buffer: [5]u8 = undefined;
        const n = try ring_buffer_reader.read(&buffer);
        const expected = "89";
        try testing.expect(n == expected.len);
        try testing.expect(ring_buffer.unread() == 0);
        try testing.expectEqualSlices(u8, expected, buffer[0..expected.len]);

        const expected_buffer_contents = "67894";
        try testing.expectEqualSlices(u8, expected_buffer_contents, &ring_buffer.buffer);
    }
    {
        var buffer: [10]u8 = undefined;
        const n = try ring_buffer_reader.read(&buffer);
        try testing.expect(n == 0);
        try testing.expect(ring_buffer.unread() == 0);

        const expected_buffer_contents = "67894";
        try testing.expectEqualSlices(u8, expected_buffer_contents, &ring_buffer.buffer);
    }
}

fn ringCopy(dest: []u8, src: []u8, head_ptr: *usize, tail: usize) usize {
    const head = head_ptr.*;

    if (tail == head) {
        return 0;
    }

    if (tail > head) {
        const n = copy(dest, src[head..tail]);
        head_ptr.* += n;
        return n;
    }

    // src:
    // [...............................]
    //         tail^       ^head
    // read sequence:
    //                     ---------->(n)
    // ----------->(m)

    const n = copy(dest, src[head..]);
    const remaining_dest = dest[n..];
    if (remaining_dest.len == 0) {
        head_ptr.* += n;
        return n;
    }

    const m = copy(remaining_dest, src[0..tail]);
    head_ptr.* = m;
    return n + m;

}

test "ringCopy - 1" {
    var dest = [_]u8{0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    var src  = [_]u8{0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    var head: usize = 0;
    var tail: usize = 10;
    const n = ringCopy(&dest, &src, &head, tail);

    try testing.expectEqualSlices(u8, &dest, &src);
    try testing.expect(head == 10);
    try testing.expect(n == 10);
}

test "ringCopy - 2" {
    var dest = [_]u8{0, 0, 0, 0, 0};
    var src  = [_]u8{0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    var head: usize = 1;
    var tail: usize = 10;

    const n = ringCopy(&dest, &src, &head, tail);

    var expected_dest  = [_]u8{1, 2, 3, 4, 5};
    try testing.expectEqualSlices(u8, &dest, &expected_dest);
    try testing.expect(head == 6);
    try testing.expect(n == 5);
}

test "ringCopy - 3" {
    var dest = [_]u8{0, 0, 0, 0, 0};
    var src  = [_]u8{0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    var head: usize = 1;
    var tail: usize = 4;

    const n = ringCopy(&dest, &src, &head, tail);

    var expected_dest  = [_]u8{1, 2, 3, 0, 0};
    try testing.expectEqualSlices(u8, &dest, &expected_dest);
    try testing.expect(head == 4);
    try testing.expect(n == 3);
}

test "ringCopy - 4" {
    var dest = [_]u8{0, 0, 0, 0, 0};
    var src  = [_]u8{0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    var head: usize = 4;
    var tail: usize = 4;

    const n = ringCopy(&dest, &src, &head, tail);

    var expected_dest  = [_]u8{0, 0, 0, 0, 0};
    try testing.expectEqualSlices(u8, &dest, &expected_dest);
    try testing.expect(head == 4);
    try testing.expect(n == 0);
}

test "ringCopy - 5" {
    var dest = [_]u8{0, 0, 0, 0, 0};
    var src  = [_]u8{0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    var head: usize = 8;
    var tail: usize = 2;

    const n = ringCopy(&dest, &src, &head, tail);

    var expected_dest  = [_]u8{8, 9, 0, 1, 0};
    try testing.expectEqualSlices(u8, &dest, &expected_dest);
    try testing.expect(head == 2);
    try testing.expect(n == 4);
}

test "ringCopy - 5" {
    var dest = [_]u8{0, 0, 0, 0, 0};
    var src  = [_]u8{0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    var head: usize = 8;
    var tail: usize = 7;

    const n = ringCopy(&dest, &src, &head, tail);

    var expected_dest  = [_]u8{8, 9, 0, 1, 2};
    try testing.expectEqualSlices(u8, &dest, &expected_dest);
    try testing.expect(head == 3);
    try testing.expect(n == 5);
}

// copy copies maximum copyable bytes from src to dest.
fn copy(dest: []u8, src: []u8) usize {
    var max_copyable = src.len;
    if (dest.len < max_copyable) {
        max_copyable = dest.len;
    }
    std.mem.copy(u8, dest, src[0..max_copyable]);
    return max_copyable;
}

test "test copy" {
    var dest = [_]u8{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    var src = [_]u8{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16};
    const copied = copy(&dest, &src);
    try testing.expect(copied == 16);
    try testing.expectEqualSlices(u8, &dest, &src);
}

test "test copy 2" {
    var dest = [_]u8{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    var src = [_]u8{1, 2, 3, 4, 5};
    const copied = copy(&dest, &src);
    try testing.expect(copied == 5);

    var expected = [_]u8{1, 2, 3, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    try testing.expectEqualSlices(u8, &dest, &expected);
}

test "test copy 3" {
    var dest = [_]u8{0, 0, 0, 0, 0};
    var src = [_]u8{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16};
    const copied = copy(&dest, &src);
    try testing.expect(copied == 5);

    var expected = [_]u8{1, 2, 3, 4, 5};
    try testing.expectEqualSlices(u8, &dest, &expected);
}

fn ringUnread(head: usize, tail: usize, len: usize) usize {
    if (tail >= head) {
        return tail - head;
    }
    return len - head + tail;
}
