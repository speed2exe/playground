const std = @import("std");

/// Writer is of type: std.io.Writer
pub fn EscapeSequenceWriter(comptime WriterType: type) type {
    return struct {
        const Self = @This();
        pub const Writer = WriterType.Writer;

        writer: Writer,

        pub fn init(w: *WriterType) Self {
            return .{
                .writer = .{ .context = w },
            };
        }

        pub fn moveHorizontal(self: *Self, left: usize, right: usize) !void {
            if (left > right) {
                return self.moveLeft(left - right);
            }
            if (right > left) {
                return self.moveRight(right - left);
            }
        }

        pub fn moveLeft(self: *Self, n: usize) !void {
            try self.writer.print("\x1b[{d}D", .{n});
        }

        pub fn moveRight(self: *Self, n: usize) !void {
            try self.writer.print("\x1b[{d}C", .{n});
        }

        pub fn testPrint(self: *Self) !void {
            try self.writer.print("testPrint\n", .{});
        }
    };
}
