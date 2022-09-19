const std = @import("std");
const c = std.c;
const File = std.fs.File;

// based on: https://www.gnu.org/software/libc/manual/html_node/Noncanonical-Input.html
pub fn getRawModeTermios(termios: std.os.termios) std.os.termios {
    var raw_mode = termios;
    raw_mode.iflag &= ~(c.IGNBRK | c.BRKINT | c.PARMRK | c.ISTRIP | c.INLCR | c.IGNCR | c.ICRNL | c.IXON);
    raw_mode.oflag &= ~c.OPOST;
    raw_mode.lflag &= ~(c.ECHO | c.ECHONL | c.ICANON | c.ISIG | c.IEXTEN);
    raw_mode.cflag &= ~(c.CSIZE | c.PARENB);
    raw_mode.cflag |= c.CS8;
    raw_mode.cc[c.V.MIN] = 1;
    raw_mode.cc[c.V.TIME] = 0;
    return raw_mode;
}

pub fn setTermios(file: File, termios: std.os.termios) !void {
    try std.os.tcsetattr(file.handle, c.TCSA.NOW, termios);
}
