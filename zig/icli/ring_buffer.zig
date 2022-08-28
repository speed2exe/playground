const std = @import("std");
const testing = std.testing;

// pub const RingBuffer = struct {
//     source: std.io.Reader,
//     buffer: []u8,
// 
//     // inclusive
//     head: usize = 0,
//     // exclusive
//     tail: usize = 0,
// 
//     allocator: ?std.mem.Allocator = null,
// 
//     pub fn initWithAllocator(reader: std.io.Reader, allocator: std.mem.Allocator, buffer_size: usize) RingBuffer {
//         var buffer = allocator.alloc(u8, buffer_size);
//         return RingBuffer {
//             .source = reader,
//             .buffer = buffer,
//             .allocator = allocator,
//         };
//     }
// 
//     pub fn initWithBuffer(reader: std.io.Reader, buffer: []u8) RingBuffer {
//         return RingBuffer {
//             .source = reader,
//             .buffer = buffer,
//             .head = 0,
//             .tail = 0,
//         };
//     }
// 
//     // user dont need to call this if you use initWithBuffer
//     pub fn deinit(self: *RingBuffer) void {
//        var allocator = self.allocator orelse return;
//        allocator.free(self.buffer);
//     }
// 
//     pub const Reader = std.io.Reader(RingBuffer, anyerror, read);
// 
//     pub fn reader(self: *RingBuffer) Reader {
//         return Reader {
//             .context = self,
//         };
//     }
// 
//     pub fn read(self: *RingBuffer, dest: []u8) !usize {
//         const head = self.head;
//         const tail = self.tail;
// 
// 
//         
//     }
// };

fn ringCopy(dest: []u8, src: []u8, head_ptr: *usize, tail: usize) usize {
    const head = head_ptr.*;

    if (tail == head) {
        // tail_ptr.* = 0;
        // head_ptr.* = 0;
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
