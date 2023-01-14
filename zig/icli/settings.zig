const defaults = @import("./defaults.zig");
const Suggestion = @import("./suggestion.zig").Suggestion;
const std = @import("std");
const UserInput = @import("./user_input.zig").UserInput;

pub const Settings = struct {
    input_buffer_size: usize = 4096,
    history_size: usize = 100,
    log_file_path: ?[]const u8 = null,
    is_end_of_user_input: fn (
        keypress: []const u8,
        user_input: UserInput,
    ) bool = defaults.isEndOfUserInput,
    print_newline_after_user_input: bool = true,
    preSuggestionLeftOffset: fn (input_pre_cursor: []const u8) usize = defaults.preSuggestionLeftOffset,

    prefix: []const u8 = "> ",

    max_suggestion_count: usize = 3,
    suggestFn: ?*const fn (
        pre_cursor_buffer: []const u8,
        post_cursor_buffer: []const u8,
    ) []Suggestion = null,
    suggestFilterPredicate: ?*const fn (
        user_input: UserInput,
        suggetion: Suggestion,
    ) bool = defaults.suggestFilterPredicate,

    suggestSortCompare: ?*const fn (
        _: void,
        s1: Suggestion,
        s2: Suggestion,
    ) bool = defaults.suggestSortCompare,
};
