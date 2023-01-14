const std = @import("std");
const ArrayList = @import("./array_list.zig");

pub const Suggestion = struct {
    text: []const u8 = "",
    description: ?[]const u8 = null,
};

pub fn maxSuggestionTextLen(suggestions: []Suggestion) usize {
    var max_len: usize = 0;
    for (suggestions) |suggestion| {
        if (suggestion.text.len > max_len) {
            max_len = suggestion.text.len;
        }
    }
    return max_len;
}
