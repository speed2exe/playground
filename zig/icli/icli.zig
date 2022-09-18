const std = @import("std");
const builtin = @import("builtin");
const array_list = @import("./array_list.zig");
const ring_buffered_reader = @import("./ring_buffered_reader.zig");
const ring_buffered_writer = @import("./ring_buffered_writer.zig");
const File = std.fs.File;
const termios = switch (builtin.os.tag) {
    .linux => @import("./termios_linux.zig"),
    else => error.UnsupportedOS,
};

pub fn InteractiveCli(comptime comptime_settings: ComptimeSettings) type {
    return struct {
        const Self = @This();
        const RingBufferedReader = ring_buffered_reader.RingBufferedReader(std.fs.File.Reader, comptime_settings.input_buffer_size);
        const RingBufferedWriter = ring_buffered_writer.RingBufferedWriter(std.fs.File.Writer, comptime_settings.input_buffer_size);

        tty: File,
        input: RingBufferedReader,
        output: RingBufferedWriter,
        original_termios: std.os.termios,
        raw_mode_termios: std.os.termios,
        command_buffer: array_list.Array(u8),
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

            return Self{
                .tty = tty,
                .input = input,
                .output = output,
                .original_termios = original_termios,
                .raw_mode_termios = raw_mode_termios,
                .allocator = settings.allocator,
                .command_buffer = array_list.Array(u8).init(settings.allocator),
                .settings = settings,
            };
        }

        pub fn deinit(self: *Self) void {
            self.command_buffer.deinit();
        }

        pub fn run(self: *Self) !void {
            while (true) {
                try std.fmt.format(self.output.writer(), "\r\n{s}", .{self.settings.prompt});
                _ = try self.output.flush();

                try self.fillCommandBuffer();
                if (self.settings.execute(self.command_buffer.getAll())) {
                    return;
                }
                self.command_buffer.truncate(0);
            }
        }

        fn fillCommandBuffer(self: *Self) !void {
            try self.setRawInputMode();
            defer self.setOriginalInputMode() catch |err| {
                std.fmt.format(self.output.writer(), "Failed to set original input mode: {any}", .{err}) catch unreachable;
            };

            while (true) {
                const input = try self.input.readConst();
                for (input) |byte| {
                    const ended = try self.handleInputByte(byte);
                    if (ended) {
                        std.debug.print("\r\n", .{});
                        // TODO: handle unread bytes
                        return;
                    }
                }
                std.debug.print("{s}", .{input});

                // TODO: generate autocomplete here?
            }
        }

        // retuns true if input is done
        fn handleInputByte(self: *Self, byte: u8) !bool {
            if (byte == 3) { // ctrl-c
                return error.Cancel;
            }

            if (byte == '\r') {
                return true;
            }

            try self.command_buffer.append(byte);

            // debug input
            // std.debug.print("{}",.{byte});
            return false;
        }

        fn setRawInputMode(self: *Self) !void {
            try termios.setTermios(self.tty, self.raw_mode_termios);
        }

        fn setOriginalInputMode(self: *Self) !void {
            try termios.setTermios(self.tty, self.original_termios);
        }
    };
}

pub const ComptimeSettings = struct {
    input_buffer_size: usize = 4096,
};

pub const Settings = struct {
    welcome_message: []const u8 = "Welcome!",
    allocator: std.mem.Allocator,
    execute: fn ([]const u8) bool,
    suggest: ?fn ([]const u8, usize) [][]const u8 = null,
    prompt: []const u8 = "> ",
};

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
