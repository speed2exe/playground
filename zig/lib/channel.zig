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
        const Self = @This();

        // The channel's buffer.
        buffer: [size]T,

        // Position of the next item to be read.
        read_pos: atomic.Atomic(usize),

        len: atomic.Atomic(usize),

        send_queue_number: atomic.Atomic(usize),
        recv_queue_number: atomic.Atomic(usize),

        pub fn init() Self {
           return Self{
               .buffer = [_]T{undefined} ** size,
               .read_pos = atomic.Atomic(usize).init(0),
               .len = atomic.Atomic(usize).init(size),
               .send_queue_number = atomic.Atomic(usize).init(0),
               .recv_queue_number = atomic.Atomic(usize).init(0),
           };
        }
        
        pub fn send(self: *Self, item: T) void {
            @atomicRmw(usize, &self.send_queue_number, .Add, 1, .Acquire);


            // @cmpxchgStrong
        }

        // TODO: sendwithtimeout
        // pub fn send(self: *Channel, item: T) void {

        //     // get a queue number
        //     self.send_queue_number


        //     // Wait until there is space in the buffer.
        //     std.Thread.Futex.wait(&self.counter, buffer.len, null);
        //     std.atomic.Queue



        //     // Wait until there is space in the buffer.

        //     // Put the item in the buffer.

        // }

        // TODOrecvwithtimeout

        // pub fn recv(self: *Channel) T {

        // }

        // pub fn close(self: *Channel) !void {

        // }

    };
}

test "Channel" {
    const chan = Channel(u32, 10).init();
    _ = chan;
}
