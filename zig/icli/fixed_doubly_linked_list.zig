// This module can only be suitable for certain use cases.
// Please read before using.

const std = @import("std");
const testing = std.testing;
const warn = std.log.warn;

pub fn FixedDoublyLinkedList (
    comptime T: type,
    comptime capacity: usize,
) type {
    return struct {
        pub const Node = NodeOf(T);

        const Self = @This();

        // private
        nodes: [capacity]Node = undefined,

        // public
        length: usize = 0,
        head: ?*Node = null,
        tail: ?*Node = null,

        pub fn insertHead(self: *Self, item: T) ?*Node {
            if (capacity == self.length) return null;

            var new_node = &self.nodes[self.length];
            self.length += 1;

            new_node.value = item;
            new_node.prev = null;

            if (self.head) |head| {
                new_node.next = head;
                head.prev = new_node;
                self.head = new_node;
            } else {
                new_node.next = null;
                self.head = new_node;
                self.tail = new_node;
            }
            return new_node;
        }

        pub fn insertTail(self: *Self, item: T) ?*Node {
            if (capacity == self.length) return null;

            var new_node = &self.nodes[self.length];
            self.length += 1;

            new_node.value = item;
            new_node.next = null;

            if (self.tail) |tail| {
                new_node.prev = tail;
                tail.next = new_node;
                self.tail = new_node;
            } else {
                new_node.prev = null;
                self.head = new_node;
                self.tail = new_node;
            }
            return new_node;
        }

        /// WARNING: after removal of any node, all pointers to nodes after the
        /// removed node are invalidated
        pub fn remove(self: *Self, node: *Node) void {
            if (node == self.tail) {
                self.tail = node.prev;
            } else {
                node.next.?.prev = node.prev;
            }

            if (node == self.head) {
                self.head = node.next;
            } else {
                node.prev.?.next = node.next;
            }

            var last_node = &self.nodes[self.length - 1];
            self.length -= 1;

            if (node == last_node) {
                return;
            }

            node.value = last_node.value;
            node.next = last_node.next;
            node.prev = last_node.prev;
            if (node.next) |next| { next.prev = node; }
            if (node.prev) |prev| { prev.next = node; }
            if (last_node == self.head) { self.head = node; }
            if (last_node == self.tail) { self.tail = node; }
        }

        fn collectInternalValues(self: Self, dest: *[capacity]T) usize {
            for (self.nodes) |node, i| {
                dest[i] = node.value;
            }
            return self.length;
        }

        fn collectInternalValuesLinked(self: Self, dest: *[capacity]T) usize {
            var node = self.head;
            var i: usize = 0;
            while (node) |n| : (i += 1) {
                dest[i] = n.value;
                node = n.next;
            }
            return i;
        }

        fn debugPrint(self: Self) void {
            warn("\n LEN:{}",.{self.length});
            warn("\n NODES:",.{});
            for (self.nodes) |*node| {
                node.debugPrint();
            }
            warn("\n HEAD:",.{});
            if (self.head) |head| {
                head.debugPrint();
            } else {
                warn("null",.{});
            }
            warn("\n TAIL:",.{});
            if (self.tail) |tail| {
                tail.debugPrint();
            } else {
                warn("null",.{});
            }
            warn("\n",.{});
        }

    };
}

fn NodeOf(comptime T: type) type {
    return struct {
        const Self = @This();

        // payload of the node
        value: T,
        // previous node
        next: ?*Self = null,
        // next node
        prev: ?*Self = null,

        fn debugPrint(self: Self) void {
            std.log.warn("Node: value: {}", .{self.value});
            if (self.prev) |prev| {
                std.log.warn("\tPrev: value: {}", .{prev.value});
            } else {
                std.log.warn("\tPrev: null",.{});
            }
            if (self.next) |next| {
                std.log.warn("\tNext: value: {}", .{next.value});
            } else {
                std.log.warn("\tNext: null",.{});
            }
        }
    };
}

test "test FixedDoublyLinkedList_1" {
    var fdll = FixedDoublyLinkedList(u8, 4){};
    var buffer: [4]u8 = undefined;

    {
        const node = fdll.insertTail(5) orelse unreachable;
        try testing.expectEqual(node.value, @as(u8, 5));
        const n = fdll.collectInternalValues(&buffer);
        try testing.expectEqualSlices(u8, buffer[0..n], &[_]u8{5});
    }

    {
        const node = fdll.insertTail(6) orelse unreachable;
        try testing.expectEqual(node.value, @as(u8, 6));
        const n = fdll.collectInternalValues(&buffer);
        try testing.expectEqualSlices(u8, buffer[0..n], &[_]u8{5, 6});
    }

    {
        const node = fdll.insertHead(4) orelse unreachable;
        try testing.expectEqual(node.value, @as(u8, 4));
        var n = fdll.collectInternalValues(&buffer);
        try testing.expectEqualSlices(u8, buffer[0..n], &[_]u8{5, 6, 4});
        n = fdll.collectInternalValuesLinked(&buffer);
        try testing.expectEqualSlices(u8, buffer[0..n], &[_]u8{4, 5, 6});
    }

    {
        const node = fdll.insertHead(7) orelse unreachable;
        try testing.expectEqual(node.value, @as(u8, 7));
        var n = fdll.collectInternalValues(&buffer);
        try testing.expectEqualSlices(u8, buffer[0..n], &[_]u8{5, 6, 4, 7});
        n = fdll.collectInternalValuesLinked(&buffer);
        try testing.expectEqualSlices(u8, buffer[0..n], &[_]u8{7, 4, 5, 6});
    }

    {
        const node = fdll.insertHead(99);
        try testing.expect(node == null);
    }

    {
        const node = fdll.insertTail(99);
        try testing.expect(node == null);
    }
}

test "test FixedDoublyLinkedList_2" {
    var fdll = FixedDoublyLinkedList(u8, 2){};
    var buffer: [2]u8 = undefined;

    {
        const node = fdll.insertTail(5) orelse unreachable;
        fdll.remove(node);
        const n = fdll.collectInternalValues(&buffer);
        try testing.expectEqualSlices(u8, buffer[0..n], &[_]u8{});
    }
}

test "test FixedDoublyLinkedList_3" {
    var fdll = FixedDoublyLinkedList(u8, 4){};
    var buffer: [4]u8 = undefined;

    {
        _ = fdll.insertTail(5) orelse unreachable;
        _ = fdll.insertTail(6) orelse unreachable;
        const tail = fdll.tail orelse unreachable;
        fdll.remove(tail);
        const n = fdll.collectInternalValues(&buffer);
        try testing.expectEqualSlices(u8, buffer[0..n], &[_]u8{5});
    }

    {
        _ = fdll.insertHead(6);
        const n = fdll.collectInternalValues(&buffer);
        try testing.expectEqualSlices(u8, buffer[0..n], &[_]u8{5, 6});
    }

    // TODO: failed test case! do this first!
    {
        const n = fdll.collectInternalValuesLinked(&buffer);
        try testing.expectEqualSlices(u8, buffer[0..n], &[_]u8{6, 5});
    }
}

test "test FixedDoublyLinkedList_3" {
    var fdll = FixedDoublyLinkedList(u8, 4){};
    var buffer: [4]u8 = undefined;

    {
        _ = fdll.insertTail(5) orelse unreachable;
        const r = fdll.insertTail(6) orelse unreachable;
        _ = fdll.insertTail(7) orelse unreachable;

        fdll.remove(r);

        const n = fdll.collectInternalValues(&buffer);
        try testing.expectEqualSlices(u8, buffer[0..n], &[_]u8{5, 7});

        const m = fdll.collectInternalValuesLinked(&buffer);
        try testing.expectEqualSlices(u8, buffer[0..m], &[_]u8{5, 7});
    }
}
