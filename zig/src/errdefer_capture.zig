const std = @import("std");

fn geti8Err() !i8 {
    return error.myError;
}

fn myFunc() !i8 {
    errdefer |x| {
        std.log.info("error: {}", .{x});
    }
    return geti8Err();
}

pub fn main() void {
    _ = myFunc() catch {};
}
