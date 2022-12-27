const std = @import("std");

pub fn isEndOfUserInput(keypress: []const u8, input_pre_cursor: []const u8, input_post_cursor: []const u8) bool {
    _ = input_pre_cursor;
    _ = input_post_cursor;

    // TODO: tested only in linux
    // modify for other platforms
    return std.mem.eql(u8, keypress, "\r");
}
