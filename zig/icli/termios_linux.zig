const std = @import("std");
const linux = std.os.linux;
const File = std.fs.File;

// based on: https://www.gnu.org/software/libc/manual/html_node/Noncanonical-Input.html
pub fn getRawModeTermios(termios: std.os.termios) std.os.termios {
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

pub fn setTermios(file: File, termios: std.os.termios) !void {
    try std.os.tcsetattr(file.handle, linux.TCSA.NOW, termios);
}
