const std = @import("std");
const builtin = @import("builtin");
const array_list = @import("./array_list.zig");
const fdll = @import("./fixed_doubly_linked_list.zig");
const ring_buffered_reader = @import("./ring_buffered_reader.zig");
const ring_buffered_writer = @import("./ring_buffered_writer.zig");
const File = std.fs.File;
const termios = switch (builtin.os.tag) {
    .linux => @import("./termios_linux.zig"),
    // .windows => @import("./termios_windows.zig"), // TODO
    else => @import("./termios_c.zig"),
};

pub fn InteractiveCli(comptime comptime_settings: ComptimeSettings) type {
    return struct {
        const Self = @This();
        const RingBufferedReader = ring_buffered_reader.RingBufferedReader(std.fs.File.Reader, comptime_settings.input_buffer_size);
        const RingBufferedWriter = ring_buffered_writer.RingBufferedWriter(std.fs.File.Writer, comptime_settings.input_buffer_size);
        const HistoryType = fdll.FixedDoublyLinkedList(array_list.Array(u8), comptime_settings.history_size);

        tty: File,
        input: RingBufferedReader,
        output: RingBufferedWriter,
        history: HistoryType,
        original_termios: std.os.termios,
        raw_mode_termios: std.os.termios,
        allocator: std.mem.Allocator,
        settings: Settings,

        pub fn init(settings: Settings) !Self {
            var tty = try std.fs.openFileAbsolute("/dev/tty", .{ .write = true });
            if (!tty.isTty()) {
                return error.DeviceNotTty;
            }
            var input = RingBufferedReader.init(tty.reader());
            var output = RingBufferedWriter.init(tty.writer());

            const original_termios = try std.os.tcgetattr(tty.handle);
            const raw_mode_termios = termios.getRawModeTermios(original_termios);

            return Self {
                .tty = tty,
                .input = input,
                .output = output,
                .history = HistoryType{},
                .original_termios = original_termios,
                .raw_mode_termios = raw_mode_termios,
                .allocator = settings.allocator,
                .settings = settings,
            };
        }

        pub fn deinit(self: *Self) void {
            const n = self.history.length;
            const valid_nodes = self.history.nodes[0..n];
            for (valid_nodes) |*node| {
                node.value.deinit();
            }
        }

        pub fn run(self: *Self) !void {
            while (true) {
                // prompt user
                try std.fmt.format(self.output.writer(), "\r\n{s}", .{self.settings.prompt});
                _ = try self.output.flush();

                // get input
                const input = try self.readUserInput();
                _ = try self.output.flush();
                if (self.settings.execute(input)) {
                    return;
                }
            }
        }

        fn readUserInput(self: *Self) ![]const u8 {
            try self.setRawInputMode();
            defer self.setOriginalInputMode() catch |err| {
                std.fmt.format(self.output.writer(), "Failed to set original input mode: {any}", .{err}) catch unreachable;
            };

            // reused input buffer from history when possible
            var input_buffer = blk: {
                if (self.history.length == comptime_settings.history_size) {
                    var buffer = blk2: {
                        const node = self.history.head orelse unreachable;
                        self.history.remove(node);
                        const new_node = self.history.insertFront(node.*.value) orelse unreachable;
                        break :blk2 &new_node.*.value;
                    };
                    buffer.truncate(0);
                    break :blk buffer;
                }

                const new_node = self.history.insertFront(array_list.Array(u8).init(self.settings.allocator)) orelse unreachable;
                break :blk &new_node.*.value;
            };


            while (true) {
                const input = try self.input.readConst();
                const handled = try self.handleKeyBind(input);
                if (handled) {
                    continue;
                }

                for (input) |byte| {
                    if (isEnd(byte)) {
                        _ = try self.output.write("\r\n");
                        return input_buffer.getAll();
                    }

                    try input_buffer.append(byte);
                    _ = try self.output.write(&[1]u8{byte});

                    // TODO: handle inputs after end
                }
                _ = try self.output.flush();
                // TODO: generate autocomplete here?
            }
        }

        // TODO: hash table
        fn handleKeyBind(self: *Self, bytes: []const u8) !bool {
            if (std.mem.eql(u8, bytes, &[_]u8{3})) { // ctrl-c
                return error.Cancel;
            } else if (std.mem.eql(u8, bytes, &[_]u8{4})) { // ctrl-d
                return error.Quit;
            } else if (std.mem.eql(u8, bytes, "\x1b[A")) { // up arrow
                try self.printf("got up arrow",.{});
                return true;
            } else if (std.mem.eql(u8, bytes, "\x1b[B")) { // down arrow
                try self.printf("got the down arrow",.{});
                return true;
            }


            // TODO: handle other keybinds
            // return false to skip appending key to input buffer

            return false;
        }

        fn setRawInputMode(self: *Self) !void {
            try termios.setTermios(self.tty, self.raw_mode_termios);
        }

        fn setOriginalInputMode(self: *Self) !void {
            try termios.setTermios(self.tty, self.original_termios);
        }

        fn printf(self: *Self, comptime fmt: []const u8, args: anytype) !void {
            std.fmt.format(self.output.writer(), fmt, args) catch unreachable;
            _ = try self.output.flush();
        }
    };
}

pub const ComptimeSettings = struct {
    input_buffer_size: usize = 4096,
    history_size: usize = 100,
};

pub const Settings = struct {
    welcome_message: []const u8 = "Welcome!",
    allocator: std.mem.Allocator,
    execute: fn ([]const u8) bool,
    suggest: ?fn ([]const u8, usize) [][]const u8 = null,
    prompt: []const u8 = "> ",
};

fn isEnd(byte: u8) bool {
    return byte == '\r';
}

// pub fn main() !void {
//     var tty = try std.fs.openFileAbsolute("/dev/tty", .{});
//     var original_termios = try std.os.tcgetattr(tty.handle);
//     var raw_mode_termios = getRawModeTermios(original_termios);
//     try setTermios(tty, raw_mode_termios);
//     defer setTermios(tty, original_termios) catch |err| {
//         std.debug.print("unsetRaw failed, {}", .{err});
//     };
//
//     var buf: [1]u8 = undefined;
//     var tty_reader = tty.reader();
//     while (true) {
//         const byte = try tty_reader.readByte();
//         if (byte == 3) { // Ctrl-C
//             return;
//         }
//         buf[0] = byte;
//         std.debug.print("{s}, {d}\r\n", .{buf, buf});
//     }
// }



// TODO: get terminal size
// TODO: support utf-8 input?
