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
        settings: Settings,
        input: RingBuffer,
        command_buffer: array_list.Array(u8),
        allocator: std.mem.Allocator,

        pub fn init(settings: Settings) File.OpenError!Self {
            var tty = try std.fs.openFileAbsolute("/dev/tty", .{});
            var input = RingBuffer.init(tty.reader());
            return Self {
                .tty = tty,
                .allocator = settings.allocator,
                .settings = settings,
                .input = input,
                .command_buffer = array_list.Array(u8).init(settings.allocator),
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
            try setRaw(self.tty);
            defer unsetRaw(self.tty) catch |err| {
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
                // generate autocomplete?
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

    };
}

pub const ComptimeSettings = struct {
    input_buffer_size: usize = 4096,
};

pub const Settings = struct {
    allocator: std.mem.Allocator,
    execute: fn([]const u8) bool,
    suggest: ?fn([]const u8, usize) [][]const u8 = null,
    prompt: []const u8 = "> ",
};

pub fn main() !void {
    var tty = try std.fs.openFileAbsolute("/dev/tty", .{});

    try setRaw(tty);
    defer unsetRaw(tty) catch |err| {
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
        std.debug.print("{s}", .{buf});
    }
}

// only works for linux
// TODO: make this work for other platforms
fn setRaw(file: std.fs.File) !void {
    var termios = try std.os.tcgetattr(file.handle);

    termios.iflag &= ~(linux.IGNBRK | linux.BRKINT | linux.PARMRK | linux.ISTRIP | linux.INLCR | linux.IGNCR | linux.ICRNL | linux.IXON);
    termios.oflag &= ~linux.OPOST;
    termios.lflag &= ~(linux.ECHO | linux.ECHONL | linux.ICANON | linux.ISIG |linux.IEXTEN);
    termios.cflag &= ~(linux.CSIZE | linux.PARENB);
    termios.cflag |= linux.CS8;
    termios.cc[linux.V.MIN] = 1;
    termios.cc[linux.V.TIME] = 0;

    try std.os.tcsetattr(file.handle, linux.TCSA.NOW, termios);
}

fn unsetRaw(file: std.fs.File) !void {
    var termios = try std.os.tcgetattr(file.handle);
    try std.os.tcsetattr(file.handle, linux.TCSA.NOW, termios);
}
