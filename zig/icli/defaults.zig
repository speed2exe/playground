const std = @import("std");
const Suggestion = @import("./suggestion.zig").Suggestion;
const UserInput = @import("./user_input.zig").UserInput;

pub fn isEndOfUserInput(keypress: []const u8, user_input: UserInput) bool {
    _ = user_input;

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

pub fn suggestFilterPredicate(
    user_input: UserInput,
    suggestion: Suggestion,
) bool {
    return std.mem.startsWith(u8, suggestion.text, user_input.pre_cursor);
}

pub fn suggestSortCompare(s1: Suggestion, s2: Suggestion) std.math.Order {
    if (s1.text.len > s2.text.len) {
        return std.math.Order.gt;
    }
    if (s1.text.len < s2.text.len) {
        return std.math.Order.lt;
    }
    return std.mem.order(u8, s1.text, s2.text);
}
