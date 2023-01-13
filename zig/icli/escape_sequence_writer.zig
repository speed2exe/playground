const std = @import("std");

/// Writer is of type: std.io.Writer
pub fn EscapeSequenceWriter(
    comptime Context: type,
    comptime writeFn: fn (Context, []const u8) anyerror!usize,
) type {
    return struct {
        const Self = @This();
        const Writer = std.io.Writer(Context, anyerror, writeFn);

        writer: Writer,

        pub fn init(context: Context) Self {
            return .{ .writer = .{ .context = context } };
        }

        pub fn cursorMoveHorizontal(self: *Self, left: usize, right: usize) !void {
            if (left > right) {
                return self.cursorMoveLeft(left - right);
            }
            if (right > left) {
                return self.cursorMoveRight(right - left);
            }
        }

        pub fn cursorMoveLeft(self: *Self, n: usize) !void {
            if (n == 0) return;
            try self.print("\x1b[{d}D", .{n});
        }

        pub fn cursorMoveRight(self: *Self, n: usize) !void {
            if (n == 0) return;
            try self.print("\x1b[{d}C", .{n});
        }

        pub fn cursorMoveUp(self: *Self, n: usize) !void {
            if (n == 0) return;
            try self.print("\x1b[{d}A", .{n});
        }

        pub fn cursorMoveDown(self: *Self, n: usize) !void {
            if (n == 0) return;
            try self.print("\x1b[{d}B", .{n});
        }

        // Clear from cursor to the end of the line.
        // Cursor position does not change.
        pub fn eraseFromCursorToEnd(self: *Self) !void {
            try self.print("\x1b[K", .{});
        }

        // Clear from cursor to beginning of the line.
        // Cursor position does not change.
        pub fn eraseFromBeginningToCursor(self: *Self) !void {
            try self.print("\x1b[1K", .{});
        }

        // Clear entire line.
        // Cursor position does not change.
        pub fn eraseEntireLine(self: *Self) !void {
            try self.print("\x1b[2K", .{});
        }

        inline fn print(self: *Self, comptime format: []const u8, args: anytype) !void {
            try self.writer.print(format, args);
        }
    };
}
