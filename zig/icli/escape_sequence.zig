const std = @import("std");

pub const clear_entire_line = "\x1b[2K";

pub const move_up_once = "\x1b[1A";

pub const ctrl_c = &[_]u8{3};
pub const ctrl_d = &[_]u8{4};
pub const backspace = &[_]u8{127};
pub const up = "\x1b[A";
pub const down = "\x1b[B";
pub const right = "\x1b[C";
pub const left = "\x1b[D";
