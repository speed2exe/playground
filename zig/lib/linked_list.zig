const std = @import("std");

pub fn FixedLinkedList (
    comptime T: type,
    comptime size: usize,
) type {
    return struct {
        head: ?Node(T),
        tail: ?Node(T),
        list: [size]Node(T),

        const Self = @This();

        pub fn init() Self {
            return Self {
                .head = null,
                .tail = null,
                .list = undefined,
            };
        }

        pub fn push(self: *Self, value: T) void {
            const node = Node(T){ .value = value };
            if (self.head == null) {
                self.head = node;
            }
        }

    };
}

fn Node(comptime T: type) type {
    return struct {
        value: T,
        next: ?Node = null,
        prev: ?Node = null,

        fn remove(self: *Node) void {
            if (self.prev) |prev| {
                prev.next = self.next;
            }
            if (self.next) |next| {
                next.prev = self.prev;
            }
        }
    };
}
