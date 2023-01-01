const std = @import("std");
const atomic = std.atomic;
const testing = std.testing;

pub fn FixedQueue(
    comptime T: type,
    comptime capacity: usize,
) type {
    return struct {
        const Self = @This();

        // circular buffer to store all the elements
        // extra space to denote end of circular queue
        items: [capacity + 1]Node(T) = undefined,

        head_index: usize = 0,

        length: atomic.Atomic(u32) = atomic.Atomic(u32).init(0),

        // blocks if queue is full
        pub fn push(self: *Self, item: T) void {
            self.waitForSpace();
        }

        fn waitForSpace(self: Self) void {
            std.Thread.Futex.wait(self.length, capacity, null);
        }

        pub fn pop(self: *Self) ?T {

            // attempt to get the head, if there's no head, linked list is empty, return null
            const head_index = self.head_index orelse return null;
            var head_node = self.items[head_index];

            // if there's no next, head is the first and last node
            const right_index = head_node.right_index orelse {
                self.head_index = null;
                self.tail_index = null;
                self.length = 0;
                return head_node.value;
            };

            // the elem becomes the new head
            self.head_index = right_index;

            // quick removal of head
            // steps:
            // get the last node in the list
            // get the index of the head
            // put last node in the position of the head, which is the index
            // decrease the length
            const last_index = self.length - 1;
            var last_node = self.items[last_index];
            self.items[head_index] = last_node;
            last_node.self_index = head_index;
            self.length -= 1;
            return head_node.value;
        }
    };
}

fn Node(comptime T: type) type {
    return struct {
        const Self = @This();

        // payload of the node
        value: T,
        // index of this node in the graph
        self_index: usize,
        // index of left node in the graph
        left_index: ?usize = null,
        // index of right node in the graph
        right_index: ?usize = null,

        fn debugPrint(self: Self) void {
            std.log.warn("Node: value: {}, self_index: {}, left_index: {}, right_index: {}", .{ self.value, self.self_index, self.left_index, self.right_index });
        }
    };
}

test "FixedQueue" {
    var queue = FixedQueue(u32, 5){};
    {
        try testing.expectEqual(@as(?u32, null), queue.pop());
        try testing.expect(true == queue.push(10));
        try testing.expect(true == queue.push(11));
        try testing.expect(true == queue.push(12));
        try testing.expect(true == queue.push(13));
        try testing.expect(true == queue.push(14));
        try testing.expect(false == queue.push(14));

        try testing.expectEqual(@as(?u32, 10), queue.pop() orelse unreachable);
        try testing.expectEqual(@as(?u32, 11), queue.pop() orelse unreachable);
        try testing.expectEqual(@as(?u32, 12), queue.pop() orelse unreachable);
        try testing.expectEqual(@as(?u32, 13), queue.pop() orelse unreachable);
        try testing.expectEqual(@as(?u32, 14), queue.pop() orelse unreachable);
        try testing.expectEqual(@as(?u32, null), queue.pop());
    }
}

// test "FixedQueue - 1" {
//     var queue = FixedQueue(u32, 5){};
//     {
//         try testing.expect(null != queue.push(10));
//         try testing.expectEqual(@as(?u32, 10), queue.pop() orelse unreachable);
//
//         try testing.expect(null != queue.push(11)); // 11
//         try testing.expect(null != queue.push(12)); // 11, 12
//         try testing.expectEqual(@as(?u32, 11), queue.pop() orelse unreachable); // 12
//
//         try testing.expect(null != queue.push(13)); // 12, 13
//         try testing.expect(null != queue.push(14)); // 12, 13, 14
//         try testing.expect(null != queue.push(15)); // 12, 13, 14, 15
//         try testing.expectEqual(@as(?u32, 12), queue.pop() orelse unreachable); // 15, 13, 14
//         try testing.expectEqual(@as(?u32, 13), queue.pop() orelse unreachable); // 15, 13, 14
//
//         try testing.expect(null != queue.push(16)); // 12, 13, 14, 15
//         try testing.expectEqual(@as(?u32, 14), queue.pop() orelse unreachable);
//         try testing.expectEqual(@as(?u32, 15), queue.pop() orelse unreachable);
//         try testing.expectEqual(@as(?u32, 16), queue.pop() orelse unreachable);
//         try testing.expectEqual(@as(?u32, null), queue.pop());
//     }
// }
