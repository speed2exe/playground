const std = @import("std");
const testing = std.testing;
const string_reader = @import("./string_reader.zig");
const StringReader = string_reader.StringReader;

pub fn RingBuffer (
    comptime buffer_size: comptime_int,
) type {
    return struct {

        const Self = @This();

        buffer: [buffer_size]u8 = undefined,

        // inclusive
        head: usize = 0,
        // exclusive
        tail: usize = 0,

        pub const Reader = std.io.Reader(*Self, anyerror, read);
        pub const Writer = std.io.Writer(*Self, anyerror, write);

        pub fn init() Self { return Self {}; }

        pub fn reader(self: *Self) Reader {
            return Reader { .context = self };
        }

        pub fn writer(self: *Self) Writer {
            return Writer { .context = self };
        }

        pub fn read(self: *Self, dest: []u8) !usize {
            return ringRead(dest, &self.buffer, &self.head, self.tail);
        }

        pub fn write(self: *Self, src: []const u8) !usize {
            return ringWrite(src, &self.buffer, &self.head, &self.tail);
        }

        // contents that is read from reader will be put into the buffer
        // pub fn readFrom(self: *Self, comptime ReaderType: type, reader: ReaderType) !usize {
        //     return ringReadFrom(ReaderType, reader, &self.buffer, &self.head, self.tail);
        // }

        // Get view of next set of input without copying.
        // Acts like a read which "consumes" the buffer.
        pub fn readConst(self: *Self) ![]const u8 {
            return ringReadConst(&self.buffer, &self.head, self.tail);
        }

        pub fn unreadBytes(self: *Self) usize {
            return ringUnreadBytes(self.head, self.tail, self.buffer.len);
        }
    };
}

test "RingBuffer" {
    var ring = RingBuffer(10).init();
    var ring_reader = ring.reader();
    var ring_writer = ring.writer();

    {
        var buf = [_]u8{0, 0, 0};
        const n = try ring_reader.read(&buf);
        try testing.expect(n == 0);
    }
    {
        const n = try ring_writer.write("hello");
        var buf = [_]u8{0, 0, 0};
        const m = try ring_reader.read(&buf);
        try testing.expect(n == 5);
        try testing.expect(m == 3);
        try testing.expectEqualSlices(u8, &buf, "hel");
    }
    {
        const n = try ring_writer.write("0123456789");
        var buf = [_]u8{0, 0, 0};
        const m = try ring_reader.read(&buf);
        try testing.expect(n == 7);
        try testing.expect(m == 3);
        try testing.expectEqualSlices(u8, &buf, "lo0");
        try testing.expectEqualSlices(u8, &ring.buffer, "56llo01234");
    }
    {
        var buf = [_]u8{0, 0, 0, 0, 0 ,0 ,0, 0, 0, 0};
        const n = try ring_reader.read(&buf);
        try testing.expect(n == 6);
        try testing.expectEqualSlices(u8, buf[0..n], "123456");
    }
}

fn ringRead(dest: []u8, src: []u8, head_ptr: *usize, tail: usize) usize {
    var head = head_ptr.*;
    if (tail == head) {
        return 0;
    }

    defer { head_ptr.* = head; }

    if (tail > head) {
        const n = copy(dest, src[head..tail]);
        head += n;
        return n;
    }

    const n = copy(dest, src[head..]);
    const remaining_dest = dest[n..];
    if (remaining_dest.len == 0) {
        head += n;
        return n;
    }

    const m = copy(remaining_dest, src[0..tail]);
    head = m;
    return n + m;
}

test "ringRead - 1" {
    var dest = [_]u8{0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    var src  = [_]u8{0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    var head: usize = 0;
    var tail: usize = 10;
    const n = ringRead(&dest, &src, &head, tail);

    try testing.expectEqualSlices(u8, &dest, &src);
    try testing.expect(head == 10);
    try testing.expect(n == 10);
}

test "ringRead - 2" {
    var dest = [_]u8{0, 0, 0, 0, 0};
    var src  = [_]u8{0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    var head: usize = 1;
    var tail: usize = 10;

    const n = ringRead(&dest, &src, &head, tail);

    var expected_dest  = [_]u8{1, 2, 3, 4, 5};
    try testing.expectEqualSlices(u8, &dest, &expected_dest);
    try testing.expect(head == 6);
    try testing.expect(n == 5);
}

test "ringRead - 3" {
    var dest = [_]u8{0, 0, 0, 0, 0};
    var src  = [_]u8{0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    var head: usize = 1;
    var tail: usize = 4;

    const n = ringRead(&dest, &src, &head, tail);

    var expected_dest  = [_]u8{1, 2, 3, 0, 0};
    try testing.expectEqualSlices(u8, &dest, &expected_dest);
    try testing.expect(head == 4);
    try testing.expect(n == 3);
}

test "ringRead - 4" {
    var dest = [_]u8{0, 0, 0, 0, 0};
    var src  = [_]u8{0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    var head: usize = 4;
    var tail: usize = 4;

    const n = ringRead(&dest, &src, &head, tail);

    var expected_dest  = [_]u8{0, 0, 0, 0, 0};
    try testing.expectEqualSlices(u8, &dest, &expected_dest);
    try testing.expect(head == 4);
    try testing.expect(n == 0);
}

test "ringRead - 5" {
    var dest = [_]u8{0, 0, 0, 0, 0};
    var src  = [_]u8{0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    var head: usize = 8;
    var tail: usize = 2;

    const n = ringRead(&dest, &src, &head, tail);

    var expected_dest  = [_]u8{8, 9, 0, 1, 0};
    try testing.expectEqualSlices(u8, &dest, &expected_dest);
    try testing.expect(head == 2);
    try testing.expect(n == 4);
}

test "ringRead - 5" {
    var dest = [_]u8{0, 0, 0, 0, 0};
    var src  = [_]u8{0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    var head: usize = 8;
    var tail: usize = 7;

    const n = ringRead(&dest, &src, &head, tail);

    var expected_dest  = [_]u8{8, 9, 0, 1, 2};
    try testing.expectEqualSlices(u8, &dest, &expected_dest);
    try testing.expect(head == 3);
    try testing.expect(n == 5);
}

fn ringWrite(src: []const u8, dest: []u8, head_ptr: *usize, tail_ptr: *usize) usize {
    var tail = tail_ptr.*;
    const head = head_ptr.*;
    defer { tail_ptr.* = tail; }

    if (head == tail) {
        head_ptr.* = 0;
        tail = copy(dest, src);
        return tail;
    }

    if (tail > head) {
        var n = copy(dest[tail..], src);
        tail += n;
        if (tail == dest.len and head > 1) {
            tail = copy(dest[0..head - 1], src[n..]);
            n += tail;
        }
        return n;
    }

    const n = copy(dest[tail..head - 1], src);
    tail += n;
    return n;
}

test "ringWrite - 1" {
    var src  = [_]u8{0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    var dest = [_]u8{0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    var head: usize = 5;
    var tail: usize = 5;

    const n = ringWrite(&src, &dest, &head, &tail);

    const expected_dest = [_]u8{0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    try testing.expectEqualSlices(u8, &dest, &expected_dest);
    try testing.expect(tail == 10);
    try testing.expect(head == 0);
    try testing.expect(n == 10);
}

test "ringWrite - 2" {
    var src  = [_]u8{0, 1, 2, 3, 4};
    var dest = [_]u8{0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    var head: usize = 5;
    var tail: usize = 5;

    const n = ringWrite(&src, &dest, &head, &tail);

    const expected_dest = [_]u8{0, 1, 2, 3, 4};
    try testing.expectEqualSlices(u8, dest[0..n], &expected_dest);
    try testing.expect(tail == 5);
    try testing.expect(n == 5);
}

test "ringWrite - 3" {
    var src  = [_]u8{0, 1, 2, 3, 4};
    var dest = [_]u8{0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    var head: usize = 2;
    var tail: usize = 3;

    const n = ringWrite(&src, &dest, &head, &tail);

    const expected_dest = [_]u8{0, 0, 0, 0, 1, 2, 3, 4, 0, 0};
    try testing.expectEqualSlices(u8, &dest, &expected_dest);
    try testing.expect(tail == 8);
    try testing.expect(n == 5);
}

test "ringWrite - 4" {
    var src  = [_]u8{0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    var dest = [_]u8{0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    var head: usize = 3;
    var tail: usize = 4;

    const n = ringWrite(&src, &dest, &head, &tail);

    const expected_dest = [_]u8{6, 7, 0, 0, 0, 1, 2, 3, 4, 5};
    try testing.expectEqualSlices(u8, &dest, &expected_dest);
    try testing.expect(tail == 2);
    try testing.expect(n == 8);
}

test "ringWrite - 5" {
    var src  = [_]u8{0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    var dest = [_]u8{0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    var head: usize = 7;
    var tail: usize = 2;

    const n = ringWrite(&src, &dest, &head, &tail);

    const expected_dest = [_]u8{0, 0, 0, 1, 2, 3, 0, 0, 0, 0};
    try testing.expectEqualSlices(u8, &dest, &expected_dest);
    try testing.expect(tail == 6);
    try testing.expect(n == 4);
}

// copy copies maximum copyable bytes from src to dest.
fn copy(dest: []u8, src: []const u8) usize {
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

fn ringUnreadBytes(head: usize, tail: usize, len: usize) usize {
    if (tail >= head) {
        return tail - head;
    }
    return len - head + tail;
}

fn ringReadConst(buffer: []u8, head_ptr: *usize, tail: usize) []const u8 {
    var head = *head_ptr;
    defer { head_ptr.* = head; }

    if (tail > head) {
        const view = buffer[head..tail];
        head = tail;
        return view;
    }

    const view = buffer[head..];
    head = 0;
    return view;
}

// fn ringReadFrom (
//     comptime ReaderType: type,
//     reader: ReaderType,
//     buffer: []u8,
//     &self.head,
//     self.tail
// ) usize {
// 
// }
