const std = @import("std");
const testing = std.testing;
const warn = std.log.warn;

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
        head_ptr: ?*Node(T) = null,

        // index right most node, if there is
        tail_ptr: ?*Node(T) = null,

        // returns false if the queue is full
        pub fn push(self: *Self, item: T) bool {

            // if the queue is full, return false
            if (capacity == self.length) return false;

            // get the tail linked list
            if (self.tail_ptr) | tail_ptr | {
                // next index in self.items will be used to store the new node
                var new_node_ptr = &self.items[self.length];
                new_node_ptr.*.value = item;
                new_node_ptr.*.left_ptr = tail_ptr;

                // link tail with the new node
                tail_ptr.*.right_ptr = new_node_ptr;

                // the new node becomes the new tail
                self.tail_ptr = new_node_ptr;
            } else {
                // if there's no tail, list is empty
                // set both head and tail to the new node
                // insertion is completed
                var new_node_ptr = &self.items[self.length];
                new_node_ptr.*.value = item;
                self.head_ptr = new_node_ptr;
                self.tail_ptr = new_node_ptr;
            }

            self.length += 1;
            return true;
        }

        // remove and return the first item in the queue, if exists
        pub fn pop(self: *Self) ?T {

            // attempt to get the head, if there's no head, linked list is empty, return null
            const head_ptr = self.head_ptr orelse return null;

            // if there's no right node, head is the first and last node
            const right_ptr = head_ptr.right_ptr orelse {
                self.head_ptr = null;
                self.tail_ptr = null;
                self.length = 0;
                return head_ptr.value;
            };
            right_ptr.left_ptr = null;

            // quick removal of head
            // steps:
            // get the last node in the list
            // copy contents of the last node to the head
            // decrease the length
            const last_index = self.length - 1;
            var last_node_ptr = &self.items[last_index];

            // get the result before it gets overwritten
            const result = head_ptr.value;

            // update the left and right of the node
            // so that they refer to the newly moved node
            if (last_node_ptr.left_ptr) | last_left_ptr | {
                last_left_ptr.right_ptr = head_ptr;
            }
            if (last_node_ptr.right_ptr) | last_right_ptr | {
                last_right_ptr.left_ptr = head_ptr;
            }
            // if the tail is the last node, update the tail
            if (self.tail_ptr.? == last_node_ptr) {
                self.tail_ptr = head_ptr;
            }

            // replace the head with the last node
            head_ptr.value = last_node_ptr.value;
            head_ptr.left_ptr = last_node_ptr.left_ptr;
            head_ptr.right_ptr = last_node_ptr.right_ptr;

            // the elem becomes the new head
            // if it is not the same node
            if (right_ptr != last_node_ptr) {
                self.head_ptr = right_ptr;
            }

            self.length -= 1;

            // debugging
            self.items[last_index].value = 999;
            self.items[last_index].left_ptr = null;
            self.items[last_index].right_ptr = null;


            return result;
        }

        // n must exist in this linked list as a valid node
        // pub fn remove(self: Self, n: *Node(T)) bool {
        //     // link the left and the right
        //     if (n.left_ptr) |*left_ptr| {
        //         left_ptr.*.right_ptr = n.left_ptr;
        //     }
        //     if (n.right_ptr) |*right_ptr| {
        //         right_ptr.*.left_ptr = n.right_ptr;
        //     }

        //     // TODO: remove from the list
        //     // reduce the length

        // }

        fn debugPrint(self: Self) void {
            warn("\n LEN:{}",.{self.length});
            // debugPrint
            warn("\n NODES:",.{});
            for (self.items) |*node| {
                node.debugPrint();
            }
            // debugPrint
            warn("\n HEAD:",.{});
            if (self.head_ptr) |head_ptr| {
                head_ptr.debugPrint();
            }
            // debugPrint
            warn("\n TAIL:",.{});
            if (self.tail_ptr) |tail_ptr| {
                tail_ptr.debugPrint();
            }
            warn("\n",.{});
        }

    };
}

fn Node(comptime T: type) type {
    return struct {
        const Self = @This();

        // payload of the node
        value: T,
        // previous node
        left_ptr: ?*Self = null,
        // next node
        right_ptr: ?*Self = null,

        fn debugPrint(self: Self) void {
            std.log.warn("Node: value: {}", .{self.value});
            if (self.left_ptr) | left_ptr | {
                std.log.warn("\tLeft: value: {}", .{left_ptr.value});
            } else {
                std.log.warn("\tLeft: null",.{});
            }
            if (self.right_ptr) | right_ptr | {
                std.log.warn("\tRight: value: {}", .{right_ptr.value});
            } else {
                std.log.warn("\tRight: null",.{});
            }
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
  
test "FixedQueue" {
    var queue = FixedQueue(u32, 5){};
    _ = queue;
    {
        try testing.expect(true == queue.push(10));
        try testing.expectEqual(@as(?u32, 10), queue.pop() orelse unreachable);

        try testing.expect(true == queue.push(11)); // 11
        try testing.expect(true == queue.push(12)); // 11, 12
        try testing.expectEqual(@as(?u32, 11), queue.pop() orelse unreachable); // 12

        try testing.expect(true == queue.push(13)); // 12, 13
        try testing.expect(true == queue.push(14)); // 12, 13, 14
        try testing.expect(true == queue.push(15)); // 12, 13, 14, 15
        try testing.expectEqual(@as(?u32, 12), queue.pop() orelse unreachable); // 15, 13, 14
        try testing.expectEqual(@as(?u32, 13), queue.pop() orelse unreachable); // 15, 13, 14

        try testing.expect(true == queue.push(16)); // 12, 13, 14, 15
        try testing.expectEqual(@as(?u32, 14), queue.pop() orelse unreachable);
        try testing.expectEqual(@as(?u32, 15), queue.pop() orelse unreachable);
        try testing.expectEqual(@as(?u32, 16), queue.pop() orelse unreachable);
        try testing.expectEqual(@as(?u32, null), queue.pop());
    }
}
