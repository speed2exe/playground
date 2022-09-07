const std = @import("std");
const atomic = std.atomic;

// Channel is the data structure that resembles Go's channel.
// It is a blocking queue that can be used to send and receive data.
// It is safe to use from multiple threads.
// Lock-free
pub fn Channel (
    comptime T: type,
    comptime size: usize,
) type {
    return struct {
        // The channel's buffer.
        buffer: [size]T,
        // Position of the next item to be read.
        read_pos: usize = -1,

        len: usize = atomic.Atomic(usize).init(0),

        pub fn send(self: *Channel, item: T) void {
            // Wait until there is space in the buffer.
            std.Thread.Futex.wait(&self.counter, buffer.len, null);



            // Wait until there is space in the buffer.

            // Put the item in the buffer.

        }

        pub fn recv(self: *Channel) T {

        }

        pub fn close(self: *Channel) !void {

        }

    };
}

test "Channel" {
    var chan = Channel(u32, 10).init();
    chan.send(1);
    chan.send(2);
    chan.send(3);
    testing.expectEqual(chan.recv(), 1);
    testing.expectEqual(chan.recv(), 2);
    testing.expectEqual(chan.recv(), 3);
}
