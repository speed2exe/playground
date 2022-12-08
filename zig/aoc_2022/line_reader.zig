const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

const USIZE_ZERO = @as(usize, 0);

pub fn LineReader(comptime ReaderType: type, comptime initial_size: usize) type {
    return struct {
        const Self = @This();
        pub const Error = ReaderType.Error;

        src: ReaderType,

        pub fn init(r: ReaderType) Self {
            return Self { .src = r };
        }

        /// readLine reads a line from the reader.
        /// caller owns the memory of the returned slice.
        pub fn readLine(self: *Self, allocator: Allocator) ![]u8 {
            var size: usize = 0;
            const buffer: []u8 = try allocator.alloc(u8, initial_size);

            while (true) {
                const n: usize = try self.read(buffer);
                if (n == 0) {
                    return buffer[0..size];
                }
            }

            return buffer[0..size];
        }

        // read(self: Self, buffer: []u8) Error!usize

    };
}
