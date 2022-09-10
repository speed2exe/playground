const std = @import("std");
const testing = std.testing;
const warn = std.log.warn;
var k: bool = false;

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

        // returns null if the queue is full
        // returns index if there is space
        // returned index can be used to perform remove
        // returned index in valid until next pop or remove
        pub fn push(self: *Self, item: T) ?usize {

            // if the queue is full, return false
            if (capacity == self.length) return null;

            defer self.length += 1;

            // use the next available slot in items as new node
            var new_node_ptr = &self.items[self.length];
            new_node_ptr.*.value = item;

            // get the tail linked list
            if (self.tail_ptr) | tail_ptr | {
                // link tail with new node
                new_node_ptr.*.left_ptr = tail_ptr;
                tail_ptr.*.right_ptr = new_node_ptr;
            } else {
                // no tail, so this is the first node
                self.head_ptr = new_node_ptr;
            }

            // the new node becomes the new tail
            self.tail_ptr = new_node_ptr;

            return self.length;
        }

        // TODO: Use a Circular Buffer to implement a fixed size queue
        // TODO: overhaul
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

            // get the result before it gets overwritten
            const result = head_ptr.value;

            self.removeNode(head_ptr);
            return result;
        }

        pub fn removeNode(self: *Self, node: *Node(T)) void {
            // connects the left and right nodes
            if (node.left_ptr) | left_ptr | {
                left_ptr.right_ptr = node.right_ptr;
            }
            if (node.right_ptr) | right_ptr | {
                right_ptr.left_ptr = node.left_ptr;
            }

            // check if the node is the head or tail
            if (node == self.tail_ptr) {
                self.tail_ptr = node.left_ptr;
            }
            if (node == self.head_ptr) {
                self.head_ptr = node.right_ptr;
            }

            // quick removal of node
            // steps:
            // get the last node in the list
            // copy contents of the last node to the head
            // decrease the length
            var last_node_ptr = &self.items[self.length - 1];

            // update the left and right of the node
            // so that they refer to the newly moved node
            if (last_node_ptr.left_ptr) | last_left_ptr | {
                last_left_ptr.right_ptr = node;
            }
            if (last_node_ptr.right_ptr) | last_right_ptr | {
                last_right_ptr.left_ptr = node;
            }

            // if the tail is the last node, update the tail
            if (self.tail_ptr.? == last_node_ptr) {
                self.tail_ptr = node;
            }
            if (self.head_ptr.? == last_node_ptr) {
                self.head_ptr = node;
            }

            // replace the head with the last node
            node.value = last_node_ptr.value;
            node.left_ptr = last_node_ptr.left_ptr;
            node.right_ptr = last_node_ptr.right_ptr;

            // clean up the last_node_ptr
            last_node_ptr.left_ptr = null;
            last_node_ptr.right_ptr = null;

            self.length -= 1;
        }

        // index must exist in this linked list as a valid node
        // calling remove or pop consecutively invalidates the index
        pub fn remove(self: *Self, index: usize) void {

            // link the left and the right
            var n = &self.items[index];
            if (n.left_ptr) | left_ptr | {
                left_ptr.right_ptr = n.right_ptr;
            }
            if (n.right_ptr) | right_ptr | {
                right_ptr.left_ptr = n.left_ptr;
            }

            // copy from last node
            const last_index = self.length - 1;
            var last_node_ptr = &self.items[last_index];
            n.left_ptr = last_node_ptr.left_ptr;
            n.right_ptr = last_node_ptr.right_ptr;
            n.value = last_node_ptr.value;

            if (k) self.debugPrint();

            // update the left and right of the last_node
            // so that they refer to the moved node
            if (last_node_ptr.left_ptr) | last_left_ptr | {
                last_left_ptr.right_ptr = n;
            }
            if (last_node_ptr.right_ptr) | last_right_ptr | {
                last_right_ptr.left_ptr = n;
            }

            // if the tail is the last node, update the tail
            if (self.tail_ptr) |tail_ptr| {
                if (tail_ptr == last_node_ptr) {
                    if (k) warn("removed node is a tail",.{});
                    self.tail_ptr = n;
                }
            }

            if (self.head_ptr) |head_ptr| {
                if (head_ptr == last_node_ptr) {
                    if (k) warn("removed node is a head",.{});
                    self.head_ptr = n;
                }
            }
            // if the head is the last node, update the head

            // invalidates current node
            last_node_ptr.left_ptr = null;  
            last_node_ptr.right_ptr = null;

            self.length -= 1;
        }

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
        try testing.expect(null != queue.push(10));
        try testing.expect(null != queue.push(11));
        try testing.expect(null != queue.push(12));
        try testing.expect(null != queue.push(13));
        try testing.expect(null != queue.push(14));
        try testing.expect(null == queue.push(14));


        try testing.expectEqual(@as(?u32, 10), queue.pop() orelse unreachable);
        try testing.expectEqual(@as(?u32, 11), queue.pop() orelse unreachable);
        try testing.expectEqual(@as(?u32, 12), queue.pop() orelse unreachable);
        try testing.expectEqual(@as(?u32, 13), queue.pop() orelse unreachable);
        try testing.expectEqual(@as(?u32, 14), queue.pop() orelse unreachable);
        try testing.expectEqual(@as(?u32, null), queue.pop());
    }
}
  
test "FixedQueue - 1" {
    var queue = FixedQueue(u32, 5){};
    {
        try testing.expect(null != queue.push(10));
        try testing.expectEqual(@as(?u32, 10), queue.pop() orelse unreachable);

        try testing.expect(null != queue.push(11)); // 11
        try testing.expect(null != queue.push(12)); // 11, 12
        try testing.expectEqual(@as(?u32, 11), queue.pop() orelse unreachable); // 12

        try testing.expect(null != queue.push(13)); // 12, 13
        try testing.expect(null != queue.push(14)); // 12, 13, 14
        try testing.expect(null != queue.push(15)); // 12, 13, 14, 15
        try testing.expectEqual(@as(?u32, 12), queue.pop() orelse unreachable); // 15, 13, 14
        try testing.expectEqual(@as(?u32, 13), queue.pop() orelse unreachable); // 15, 13, 14

        try testing.expect(null != queue.push(16)); // 12, 13, 14, 15
        try testing.expectEqual(@as(?u32, 14), queue.pop() orelse unreachable);
        try testing.expectEqual(@as(?u32, 15), queue.pop() orelse unreachable);
        try testing.expectEqual(@as(?u32, 16), queue.pop() orelse unreachable);
        try testing.expectEqual(@as(?u32, null), queue.pop());
    }
}

// test "FixedQueue - 2" {
//     var queue = FixedQueue(u32, 5){};
//     {
//         try testing.expect(@as(usize, 0) == queue.push(10));
//         try testing.expect(@as(usize, 1) == queue.push(11));
//         try testing.expect(@as(usize, 2) == queue.push(12));
// 
//         queue.remove(1);
//         try testing.expectEqual(@as(?u32, 10), queue.pop() orelse unreachable);
//         try testing.expectEqual(@as(?u32, 12), queue.pop() orelse unreachable);
//     }
// }
// 
// test "FixedQueue - 2" {
//     var queue = FixedQueue(u32, 5){};
//     {
//         try testing.expect(@as(usize, 0) == queue.push(10));
//         try testing.expect(@as(usize, 1) == queue.push(11));
//         try testing.expect(@as(usize, 2) == queue.push(12));
// 
//         queue.remove(2);
//         try testing.expectEqual(@as(?u32, 10), queue.pop() orelse unreachable);
//         try testing.expectEqual(@as(?u32, 11), queue.pop() orelse unreachable);
//     }
// }
// 
// test "FixedQueue - 3" {
//     var queue = FixedQueue(u32, 5){};
//     {
//         try testing.expect(@as(usize, 0) == queue.push(10));
//         try testing.expect(@as(usize, 1) == queue.push(11));
//         try testing.expect(@as(usize, 2) == queue.push(12));
// 
//         k = true;
//         queue.remove(0);
// 
//         try testing.expectEqual(@as(?u32, 11), queue.pop() orelse unreachable);
//         try testing.expectEqual(@as(?u32, 12), queue.pop() orelse unreachable);
//     }
// }
