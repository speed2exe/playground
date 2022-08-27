const std = @import("std");
const linux = std.os.linux;

pub fn main() !void {
    var tty = try std.fs.openFileAbsolute("/dev/tty", .{});

    try setRaw(tty);
    defer unsetRaw(tty) catch |err| {
        std.debug.print("unsetRaw failed, {}", .{err});
    };

    var tty_reader = tty.reader();
    while (true) {
        const byte = try tty_reader.readByte();
        if (byte == 3) { // Ctrl-C
            return;
        }
        std.debug.print("byte read: {d}\r\n", .{byte});
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
