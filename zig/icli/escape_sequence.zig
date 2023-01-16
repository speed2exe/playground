const std = @import("std");

pub const clear_entire_line = "\x1b[2K";

pub const ctrl_c = &[_]u8{3};
pub const ctrl_d = &[_]u8{4};
pub const tab = &[_]u8{9};
pub const shift_tab = &[_]u8{32};
pub const backspace = &[_]u8{127};
pub const cursor_up = "\x1b[A";
pub const cursor_down = "\x1b[B";
pub const cursor_right = "\x1b[C";
pub const cursor_left = "\x1b[D";

pub fn cursorUp(comptime n: comptime_int) []const u8 {
    return std.fmt.comptimePrint("\x1b[{d}A", .{n});
}
