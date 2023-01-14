const std = @import("std");

pub fn isEndOfUserInput(keypress: []const u8, input_pre_cursor: []const u8, input_post_cursor: []const u8) bool {
    _ = input_pre_cursor;
    _ = input_post_cursor;

    // TODO: tested only in linux
    // modify for other platforms
    return std.mem.eql(u8, keypress, "\r");
}

// number of steps to move left before printing suggestion
pub fn preSuggestionLeftOffset(input_pre_cursor: []const u8) usize {
    var result: usize = 0;

    var i = input_pre_cursor.len;
    while (i > 0) : (i -= 1) {
        if (input_pre_cursor[i - 1] == ' ') {
            break;
        }
        result += 1;
    }

    return result;
}
