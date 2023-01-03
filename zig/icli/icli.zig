const std = @import("std");
const builtin = @import("builtin");
const array_list = @import("./array_list.zig");
const fdll = @import("./fixed_doubly_linked_list.zig");
const ring_buffered_reader = @import("./ring_buffered_reader.zig");
const ring_buffered_writer = @import("./ring_buffered_writer.zig");
const defaults = @import("./defaults.zig");
const tree_print = @import("./tree_print.zig");
const escape_sequence = @import("./escape_sequence.zig");
const escape_sequence_writer = @import("./escape_sequence_writer.zig");
const File = std.fs.File;
const OpenMode = std.fs.File.OpenMode;
const termios = switch (builtin.os.tag) {
    .linux => @import("./termios_linux.zig"),
    // .windows => @import("./termios_windows.zig"), // TODO
    else => @import("./termios_c.zig"),
};

pub fn InteractiveCli(comptime settings: Settings) type {
    return struct {
        const Self = @This();
        const RingBufferedReader = ring_buffered_reader.RingBufferedReader(std.fs.File.Reader, settings.input_buffer_size);
        const RingBufferedWriter = ring_buffered_writer.RingBufferedWriter(std.fs.File.Writer, settings.input_buffer_size);
        const History = fdll.FixedDoublyLinkedList(array_list.Array(u8), settings.history_size);
        const EscapeSequenceWriter = escape_sequence_writer.EscapeSequenceWriter(RingBufferedWriter);

        // Keybindings set up at comptime
        // TODO: allow user to include their own custom keybind(with a context)
        const keybind_by_keypress = std.ComptimeStringMap(*const fn (self: *Self) anyerror!void, .{
            .{ &[_]u8{3}, Self.handleCtrlC }, // ctrl-c
            .{ &[_]u8{4}, Self.handleCtrlD }, // ctrl-d
            .{ &[_]u8{127}, Self.handleBackspace }, // backspace
            .{ "\x1b[A", Self.selectLessRecent }, // up
            .{ "\x1b[B", Self.selectMoreRecent }, // down
            .{ "\x1b[C", Self.moveCursorRight }, // right
            .{ "\x1b[D", Self.moveCursorLeft }, // left
        });

        // Prompt (the thing before user input, e.g. "> ")
        prompt: []const u8 = settings.prompt, // TODO: use enum to allow for different prompts (e.g. dynamic prompt)

        // Execution
        execute: *const fn ([]const u8) bool = settings.execute, // TODO: reconsider signature

        // variables that are pretty much unchanged once initialized
        original_termios: std.os.termios,
        raw_mode_termios: std.os.termios,
        allocator: std.mem.Allocator,
        tty: File,
        isEndOfUserInput: *const fn (keypress: []const u8, input_pre_cursor: []const u8, input_post_cursor: []const u8) bool = settings.isEndOfUserInput,

        /// io buffered readers/writers
        input: RingBufferedReader,
        output: RingBufferedWriter,
        escape_sequence_writer: EscapeSequenceWriter,

        /// history handling
        /// (when user presses up or down to select previously executed commands)
        history: History = History{},
        history_size: usize = settings.history_size,
        history_selected: ?*History.Node = null, // current history node that user is using
        backup_buffer: array_list.Array(u8),

        /// pre and post cursor buffer handling
        /// (when user change cursor position by left/right arrow keys, such that cursor is no longer at the end)
        /// initial_cursor_position: initial buffer length
        ///
        /// eg. [_, _, _, y, z]
        ///
        /// valid: "yz"
        /// post_cursor_position: 3
        ///
        /// after user press right arrow key...
        /// valid: "z"
        /// post_cursor_position: 4
        pre_cursor_buffer: array_list.Array(u8),
        post_cursor_buffer: []u8,
        post_cursor_position: usize = 0,

        /// suggestion handling
        max_suggestion_count: usize = settings.max_suggestion_count,
        suggest: ?*const fn (pre_cursor_buffer: []const u8, post_cursor_buffer: []const u8) anyerror![]Suggestion = settings.suggest,
        preSuggestionLeftOffset: *const fn (input_pre_cursor: []const u8) usize = settings.preSuggestionLeftOffset,
        current_suggestions: []Suggestion = undefined,
        displayed_suggestions: [settings.max_suggestion_count]Suggestion = [_]Suggestion{Suggestion{}} ** settings.max_suggestion_count,

        /// file that collects all logs
        log_file: ?File,

        // if pre run set up is already done
        done_pre_run_setup: bool = false,

        // check for error and  failure
        pub fn init(allocator: std.mem.Allocator) !Self {
            var tty = try std.fs.openFileAbsolute("/dev/tty", .{ .mode = OpenMode.read_write });
            if (!tty.isTty()) {
                return error.DeviceNotTty;
            }

            const original_termios = try std.os.tcgetattr(tty.handle);

            // const log_file = null;
            const log_file = blk: {
                const log_path = settings.log_file_path orelse break :blk null;
                const log_file = try std.fs.cwd().createFile(log_path, .{});
                break :blk log_file;
            };

            return Self{
                .tty = tty,
                .input = undefined,
                .output = undefined,
                .escape_sequence_writer = undefined,
                .original_termios = original_termios,
                .raw_mode_termios = undefined,
                .allocator = allocator,
                .pre_cursor_buffer = array_list.Array(u8).init(allocator),
                .backup_buffer = array_list.Array(u8).init(allocator),
                .post_cursor_buffer = &[_]u8{},
                .log_file = log_file,
            };
        }

        pub fn deinit(self: *Self) void {
            self.pre_cursor_buffer.deinit();
            self.backup_buffer.deinit();

            self.allocator.free(self.post_cursor_buffer);

            const n = self.history.length;
            const valid_nodes = self.history.nodes[0..n];
            for (valid_nodes) |*node| {
                node.value.deinit();
            }
        }

        fn preRun(self: *Self) void {
            if (self.done_pre_run_setup) return;
            self.input = RingBufferedReader.init(self.tty.reader());
            self.output = RingBufferedWriter.init(self.tty.writer());
            self.escape_sequence_writer = EscapeSequenceWriter.init(&self.output);
            self.raw_mode_termios = termios.getRawModeTermios(self.original_termios);
            self.done_pre_run_setup = true;
        }

        pub fn run(self: *Self) !void {
            preRun(self);

            while (true) {
                try self.readUserInput();
                if (self.execute(self.pre_cursor_buffer.getAll())) {
                    return;
                }
                self.postExecution();
            }
        }

        fn postExecution(self: *Self) void {
            // Update the history
            if (self.history_size == 0) {
                return;
            }

            if (self.history_selected) |h| {
                if (std.mem.eql(u8, h.value.elems, self.pre_cursor_buffer.elems)) {
                    // h is invalidated after removal from self.history
                    // hence we need to get the buffer before removal
                    const history_buffer = h.value;

                    self.history.remove(h);
                    _ = self.history.insertHead(history_buffer);
                    return;
                }
            }

            if (self.history.length < self.history_size) {
                _ = self.history.insertHead(self.pre_cursor_buffer);
                self.pre_cursor_buffer = array_list.Array(u8).init(self.allocator);
                return;
            }

            // swap the input buffer with the last node's in the history
            // last node is kicked out and reinserted
            const node = self.history.tail orelse unreachable;
            self.history.remove(node);
            const node_buffer = node.value;
            _ = self.history.insertHead(self.pre_cursor_buffer) orelse unreachable;
            self.pre_cursor_buffer = node_buffer;
        }

        inline fn printPrompt(self: *Self) !void {
            // TODO: might add dynamic prompt later
            try self.print("{s}", .{self.prompt});
        }

        /// Read user input and store it in self.input_buffer
        fn readUserInput(self: *Self) !void {
            try self.printPrompt();
            try self.flush();

            try self.log_to_file("readUserInput: waiting...\n", .{});

            try self.setRawInputMode();
            defer self.setOriginalInputMode() catch |err| {
                self.log_to_file("Failed to set original input mode: {any}", .{err}) catch unreachable;
            };
            defer self.clearSuggestions() catch unreachable;

            self.pre_cursor_buffer.truncate(0);
            self.post_cursor_position = self.post_cursor_buffer.len;
            self.history_selected = null;

            while (true) {
                // TODO: consider async flushing
                defer _ = self.output.flush() catch unreachable;

                const input = try self.input.readConst();
                try self.log_to_file("read: {s}, bytes: {d}\n", .{ input, input });

                const handled = try self.handleKeyBind(input);
                if (handled) {
                    try self.log_to_file("handled keybind: {s}\n", .{input});
                    continue;
                }

                if (self.isEndOfUserInput(input, self.pre_cursor_buffer.getAll(), self.validPostCursorBuffer())) {
                    try self.pre_cursor_buffer.appendSlice(self.validPostCursorBuffer());
                    _ = try self.output.write("\r\n");
                    return;
                }

                try self.pre_cursor_buffer.appendSlice(input);
                _ = try self.output.write(input);
                _ = try self.writePostCursorBuffer();

                try self.computeSuggestions();

                _ = try self.printSuggestions();
                // TODO: generate autocompletion after flush?
            }
        }

        fn clearSuggestions(self: *Self) !void {
            const sequences: []const u8 = blk: {
                comptime {
                    const clear_lines_down = ("\n" ++ escape_sequence.clear_entire_line) ** (self.displayed_suggestions.len);
                    const move_ups = escape_sequence.move_up_once ** self.displayed_suggestions.len;
                    break :blk move_ups ++ clear_lines_down;
                }
            };
            try self.print(sequences, .{});
        }

        fn computeSuggestions(self: *Self) !void {
            const suggest = self.suggest orelse return;
            self.current_suggestions = try suggest(self.validPreCursorBuffer(), self.validPostCursorBuffer());
        }

        // TODO: teardown after app ends
        fn printSuggestions(self: *Self) !void {
            if (self.current_suggestions.len == 0) {
                return;
            }

            // TODO: incorporate max_suggestions count
            const max_text_len = maxSuggestionTextLen(self.current_suggestions);

            const pre_suggestion_left_offset = self.preSuggestionLeftOffset(self.validPreCursorBuffer());

            for (self.current_suggestions) |suggestion| {
                if (pre_suggestion_left_offset > 0) {
                    try self.output.writer().print("\x1b[{d}D", .{pre_suggestion_left_offset});
                }

                try self.output.writer().print("\n\x1b[2K{s}", .{suggestion.text});
                try self.output.writer().writeByteNTimes(' ', max_text_len - suggestion.text.len);
                const description = suggestion.description orelse continue;
                try self.output.writer().print(": {s}", .{description});

                try self.log_var_to_file(max_text_len, "max_text_len");
                try self.log_var_to_file(description.len, "description.len");
                try self.log_var_to_file(pre_suggestion_left_offset, "pre_suggestion_left_offset");

                // try self.output.writer().print("\x1b[{d}D", .{description.len + max_text_len + 1});
                // try self.escape_sequence_writer.moveLeft(description.len + max_text_len + 1);

                // try self.escape_sequence_writer.moveLeft(description.len + max_text_len);
                try self.escape_sequence_writer.moveHorizontal(max_text_len + description.len + 2, pre_suggestion_left_offset);
            }

            try self.output.writer().print("\x1b[{d}A", .{self.current_suggestions.len});
        }

        fn prependPostCursorBuffer(self: *Self, bytes: []const u8) !void {
            const final_post_buffer_cursor = blk: {
                if (self.post_cursor_position >= bytes.len) {
                    break :blk self.post_cursor_position - bytes.len;
                }

                var final_size = self.post_cursor_buffer.len;
                const needed = self.post_cursor_buffer.len + bytes.len;
                if (final_size == 0) {
                    final_size = 1;
                }
                while (needed > final_size) {
                    final_size *= 2;
                }

                const new_post_cursor_buffer = try self.allocator.alloc(u8, final_size);
                const post_buffer_len = self.post_cursor_buffer.len - self.post_cursor_position;
                const post_buffer_position = final_size - post_buffer_len;
                std.mem.copy(u8, new_post_cursor_buffer[post_buffer_position..], self.post_cursor_buffer[self.post_cursor_position..]);
                self.allocator.free(self.post_cursor_buffer);
                self.post_cursor_buffer = new_post_cursor_buffer;
                break :blk post_buffer_position - bytes.len;
            };

            std.mem.copy(u8, self.post_cursor_buffer[final_post_buffer_cursor..], bytes);
            self.post_cursor_position = final_post_buffer_cursor;
        }

        fn writePostCursorBuffer(self: *Self) !void {
            const to_move_left = self.post_cursor_buffer.len - self.post_cursor_position;
            if (to_move_left == 0) {
                return;
            }
            _ = try self.output.write(self.post_cursor_buffer[self.post_cursor_position..]);
            try self.print("\x1b[{d}D", .{to_move_left});
        }

        // return true if handled
        fn handleKeyBind(self: *Self, bytes: []const u8) !bool {
            const action = keybind_by_keypress.get(bytes) orelse return false;
            try action(self);
            return true;
        }

        /// keybind
        fn handleCtrlD(_: *Self) !void {
            return error.Quit;
        }

        /// keybind
        fn handleCtrlC(self: *Self) !void {
            try self.print("\n", .{});
            self.invalidatePreCursorBuffer();
            self.invalidatePostCursorBuffer();
            try self.reDraw();
        }

        /// keybind
        fn handleBackspace(self: *Self) !void {
            _ = self.pre_cursor_buffer.pop() orelse return;
            try self.print("\x1b[D", .{}); // move cursor left
            try self.print("\x1b[K", .{}); // clear from cursor to end of line

            // handle post cursor buffer
            const post_cursor_input = self.validPostCursorBuffer();
            if (post_cursor_input.len > 0) {
                try self.print("{s}", .{self.validPostCursorBuffer()}); // print post cursor buffer
                try self.print("\x1b[{d}D", .{self.validPostCursorBuffer().len}); // move cursor left proportionally to len of post cursor buffer
            }
        }

        /// keybind
        fn moveCursorLeft(self: *Self) !void {
            const byte = self.pre_cursor_buffer.pop() orelse return;
            try self.prependPostCursorBuffer(&[_]u8{byte});
            try self.print("\x1b[D", .{});
        }

        /// keybind
        fn moveCursorRight(self: *Self) !void {
            if (self.post_cursor_position == self.post_cursor_buffer.len) {
                return;
            }

            const byte_after_cursor = self.post_cursor_buffer[self.post_cursor_position];
            try self.pre_cursor_buffer.append(byte_after_cursor);
            self.post_cursor_position += 1;
            try self.print("\x1b[C", .{});
        }

        /// keybind
        fn selectLessRecent(self: *Self) !void {
            const history_selected = self.history_selected orelse {
                self.history_selected = self.history.head orelse return;
                self.switchInputBuffer();
                try self.setInputBufferContent(self.history_selected.?.value.getAll());
                try self.reDraw();
                return;
            };

            const less_recent_node = history_selected.next orelse return;
            self.history_selected = less_recent_node;
            try self.setInputBufferContent(less_recent_node.value.elems);
            try self.reDraw();
        }

        /// keybind
        fn selectMoreRecent(self: *Self) !void {
            const history_selected = self.history_selected orelse return;
            const more_recent_node = history_selected.prev orelse {
                self.history_selected = null;
                self.switchInputBuffer();
                try self.reDraw();
                return;
            };

            self.history_selected = more_recent_node;
            try self.setInputBufferContent(more_recent_node.value.elems);
            try self.reDraw();
        }

        fn switchInputBuffer(self: *Self) void {
            const tmp = self.pre_cursor_buffer;
            self.pre_cursor_buffer = self.backup_buffer;
            self.backup_buffer = tmp;
        }

        fn setInputBufferContent(self: *Self, content: []const u8) !void {
            self.invalidatePostCursorBuffer();
            self.pre_cursor_buffer.truncate(0);
            try self.pre_cursor_buffer.appendSlice(content);
        }

        /// reDraws the prompt for user to see
        fn reDraw(self: *Self) !void {
            // move cursor to the beginning of the line & clear the line
            try self.print("\r\x1b[K", .{});
            try self.escape_sequence_writer.EraseFromCursorToEnd();
            try self.printPrompt();
            try self.printCurrentInput();
        }

        inline fn printCurrentInput(self: *Self) !void {
            try self.print("{s}", .{self.validPreCursorBuffer()});
            try self.print("{s}", .{self.validPostCursorBuffer()});
        }

        inline fn setRawInputMode(self: *Self) !void {
            try termios.setTermios(self.tty, self.raw_mode_termios);
        }

        inline fn setOriginalInputMode(self: *Self) !void {
            try termios.setTermios(self.tty, self.original_termios);
        }

        inline fn print(self: *Self, comptime fmt: []const u8, args: anytype) !void {
            try self.output.writer().print(fmt, args);
        }

        inline fn flush(self: *Self) !void {
            _ = try self.output.flush();
        }

        inline fn validPreCursorBuffer(self: *Self) []const u8 {
            return self.pre_cursor_buffer.getAll();
        }

        inline fn validPostCursorBuffer(self: *Self) []const u8 {
            return self.post_cursor_buffer[self.post_cursor_position..];
        }

        inline fn invalidatePreCursorBuffer(self: *Self) void {
            self.pre_cursor_buffer.truncate(0);
        }

        inline fn invalidatePostCursorBuffer(self: *Self) void {
            self.post_cursor_position = self.post_cursor_buffer.len;
        }

        inline fn log_to_file(self: *Self, comptime fmt: []const u8, args: anytype) !void {
            if (self.log_file) |f| {
                try std.fmt.format(f.writer(), fmt, args);
            }
        }

        inline fn log_var_to_file(self: *Self, v: anytype, comptime name: []const u8) !void {
            if (self.log_file) |f| {
                try tree_print.treePrint(self.allocator, f.writer(), v, name);
                try f.writer().print("\n", .{});
            }
        }

        inline fn log_pre_and_post_cursor_buffer(self: *Self) !void {
            try self.log_var_to_file(self.validPreCursorBuffer(), "validPreCursorBuffer");
            try self.log_var_to_file(self.validPostCursorBuffer(), "validPostCursorBuffer");
        }
    };
}

pub const Settings = struct {
    input_buffer_size: usize = 4096,
    history_size: usize = 100,
    log_file_path: ?[]const u8 = null,
    isEndOfUserInput: fn (keypress: []const u8, input_pre_cursor: []const u8, input_post_cursor: []const u8) bool = defaults.isEndOfUserInput,
    preSuggestionLeftOffset: fn (input_pre_cursor: []const u8) usize = defaults.preSuggestionLeftOffset,

    execute: *const fn ([]const u8) bool,
    prompt: []const u8 = "> ",

    max_suggestion_count: usize = 5,
    suggest: ?*const fn (pre_cursor_buffer: []const u8, post_cursor_buffer: []const u8) anyerror![]Suggestion = null,
};

pub const Suggestion = struct {
    text: []const u8 = "",
    description: ?[]const u8 = null,
};

fn maxSuggestionTextLen(suggestions: []Suggestion) usize {
    var max_len: usize = 0;
    for (suggestions) |suggestion| {
        if (suggestion.text.len > max_len) {
            max_len = suggestion.text.len;
        }
    }
    return max_len;
}

fn isEnd(byte: u8) bool {
    return byte == '\r';
}

// TODO: inform user to Sort and Filter, but provide default implementation
// TODO: ignore undefined keys, like F1, F2, Alt+??, Ctrl+??, etc.
// TODO: clean up completion after quit (ctrl-D)
// TODO: Issue: Still seeing suggestion after execute
