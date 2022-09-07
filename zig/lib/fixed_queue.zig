const std = @import("std");
const testing = std.testing;

pub fn FixedQueue (
    comptime T: type,
    comptime capacity: usize,
) type {
    return struct {
        const Self = @This();

        // where all the actual values lies
        items: [capacity]Node(T) = undefined,

        // current valid item count
        length: usize = 0,

        // index of the left most node, if there is
        head_index: ?usize = null,

        // index right most node, if there is
        tail_index: ?usize = null,

        // returns false if the queue is full
        pub fn push(self: *Self, item: T) bool {

            // if the queue is full, return false
            if (capacity == self.length) return false;


            // get the tail linked list
            if (self.tail_index) | tail_index | {

                // creates the new node
                // adds the node to the list
                // increase the length after the insertion
                var new_node = Node(T) {
                    .value = item,
                    .self_index = self.length,
                    .left_index = self.items[tail_index].self_index,
                };
                self.items[self.length] = new_node;

                // link tail with the new node
                self.items[tail_index].right_index = self.length;

                // the new node becomes the new tail
                self.tail_index = self.length;

            } else {
                // if there's no tail, list is empty
                // set both head and tail to the new node
                // insertion is completed and done
                self.head_index = 0;
                self.tail_index = 0;
                self.items[self.length] = Node(T) {
                    .value = item,
                    .self_index = 0,
                };
            }

            self.length += 1;
            return true;
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
            std.log.warn("Node: value: {}, self_index: {}, left_index: {}, right_index: {}", 
            .{self.value, self.self_index, self.left_index, self.right_index});
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

