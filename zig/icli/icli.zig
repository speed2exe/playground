const std = @import("std");
const array_list = @import("./array_list.zig");
const linux = std.os.linux;
const ring_buffer = @import("./ring_buffer.zig");
const File = std.fs.File;

pub fn InteractiveCli(comptime comptime_settings: ComptimeSettings) type {
    return struct {
        const Self = @This();
        const RingBuffer = ring_buffer.RingBuffer(comptime_settings.input_buffer_size, File.Reader);

        tty: File,
        input: RingBuffer,
        original_termios: std.os.termios,
        raw_mode_termios: std.os.termios,
        command_buffer: array_list.Array(u8),
        allocator: std.mem.Allocator,
        settings: Settings,

        pub fn init(settings: Settings) !Self {
            var tty = try std.fs.openFileAbsolute("/dev/tty", .{});
            if (!tty.isTty()) {
                return error.DeviceNotTty;
            }
            var input = RingBuffer.init(tty.reader());

            const original_termios = try std.os.tcgetattr(tty.handle);
            const raw_mode_termios = getRawModeTermios(original_termios);

            return Self {
                .tty = tty,
                .input = input,
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
                std.debug.print("\r\n", .{});
                try self.fillCommandBuffer();
                if (self.settings.execute(self.command_buffer.getAll())){
                    return;
                }
                self.command_buffer.truncate(0);
            }
        }

        fn fillCommandBuffer(self: *Self) !void {
            try self.setRawInputMode();
            defer self.setOriginalInputMode() catch |err| {
                std.debug.print("unsetRaw failed, {}", .{err});
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
            try setTermios(self.tty, self.raw_mode_termios);
        }

        fn setOriginalInputMode(self: *Self) !void {
            try setTermios(self.tty, self.original_termios);
        }

    };
}

pub const ComptimeSettings = struct {
    input_buffer_size: usize = 4096,
};

pub const Settings = struct {
    welcome_message: []const u8 = "Welcome!",
    allocator: std.mem.Allocator,
    execute: fn([]const u8) bool,
    suggest: ?fn([]const u8, usize) [][]const u8 = null,
    prompt: []const u8 = "> ",
};

pub fn main() !void {
    var tty = try std.fs.openFileAbsolute("/dev/tty", .{});
    var original_termios = try std.os.tcgetattr(tty.handle);
    var raw_mode_termios = getRawModeTermios(original_termios);
    try setTermios(tty, raw_mode_termios);
    defer setTermios(tty, original_termios) catch |err| {
        std.debug.print("unsetRaw failed, {}", .{err});
    };

    var buf: [1]u8 = undefined;
    var tty_reader = tty.reader();
    while (true) {
        const byte = try tty_reader.readByte();
        if (byte == 3) { // Ctrl-C
            return;
        }
        buf[0] = byte;
        std.debug.print("{s}, {d}\r\n", .{buf, buf});
    }
}

// based on: https://www.gnu.org/software/libc/manual/html_node/Noncanonical-Input.html
// only works for linux
// TODO: make this work for other platforms
fn getRawModeTermios(termios: std.os.termios) std.os.termios {
    var raw_mode = termios;
    raw_mode.iflag &= ~(linux.IGNBRK | linux.BRKINT | linux.PARMRK | linux.ISTRIP | linux.INLCR | linux.IGNCR | linux.ICRNL | linux.IXON);
    raw_mode.oflag &= ~linux.OPOST;
    raw_mode.lflag &= ~(linux.ECHO | linux.ECHONL | linux.ICANON | linux.ISIG | linux.IEXTEN);
    raw_mode.cflag &= ~(linux.CSIZE | linux.PARENB);
    raw_mode.cflag |= linux.CS8;
    raw_mode.cc[linux.V.MIN] = 1;
    raw_mode.cc[linux.V.TIME] = 0;
    return raw_mode;
}

fn setTermios(file: File, termios: std.os.termios) !void {
    try std.os.tcsetattr(file.handle, linux.TCSA.NOW, termios);
}

// TODO: create output ring writer buffer
