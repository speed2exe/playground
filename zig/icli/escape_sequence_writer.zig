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
            try self.print("\x1b[{d}D", .{n});
        }

        pub fn moveRight(self: *Self, n: usize) !void {
            try self.print("\x1b[{d}C", .{n});
        }

        // Clear from cursor to the end of the line.
        // Cursor position does not change.
        pub fn EraseFromCursorToEnd(self: *Self) !void {
            try self.print("\r\x1b[K", .{});
        }

        // Clear from cursor to beginning of the line.
        // Cursor position does not change.
        pub fn EraseFromBeginningToCursor(self: *Self) !void {
            try self.print("\r\x1b[1K", .{});
        }

        // Clear entire line.
        // Cursor position does not change.
        pub fn EraseEntireLine(self: *Self) !void {
            try self.print("\r\x1b[2K", .{});
        }

        inline fn print(self: *Self, comptime format: []const u8, args: anytype) !void {
            try self.writer.print(format, args);
        }

    };
}
