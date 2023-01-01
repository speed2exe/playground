const std = @import("std");
const builtin = @import("builtin");
const array_list = @import("./array_list.zig");
const fdll = @import("./fixed_doubly_linked_list.zig");
const ring_buffered_reader = @import("./ring_buffered_reader.zig");
const ring_buffered_writer = @import("./ring_buffered_writer.zig");
const defaults = @import("./defaults.zig");
const tree_print = @import("./tree_print.zig");
const File = std.fs.File;
const OpenMode = std.fs.File.OpenMode;
const termios = switch (builtin.os.tag) {
    .linux => @import("./termios_linux.zig"),
    // .windows => @import("./termios_windows.zig"), // TODO
    else => @import("./termios_c.zig"),
};

pub fn InteractiveCli(comptime comptime_settings: ComptimeSettings) type {
    return struct {
        const Self = @This();
        const RingBufferedReader = ring_buffered_reader.RingBufferedReader(std.fs.File.Reader, comptime_settings.input_buffer_size);
        const RingBufferedWriter = ring_buffered_writer.RingBufferedWriter(std.fs.File.Writer, comptime_settings.input_buffer_size);
        const History = fdll.FixedDoublyLinkedList(array_list.Array(u8), comptime_settings.history_size);

        // Keybindings set up at comptime
        // TODO: allow user to include their own custom keybind(with a context)
        const keybind_by_keypress = std.ComptimeStringMap(*const fn (self: *Self) anyerror!void, .{
            .{ &[_]u8{3}, Self.cancel }, // ctrl-c
            .{ &[_]u8{4}, Self.quit }, // ctrl-d
            .{ &[_]u8{127}, Self.backspace }, // backspace
            .{ "\x1b[A", Self.selectLessRecent }, // up
            .{ "\x1b[B", Self.selectMoreRecent }, // down
            .{ "\x1b[C", Self.moveCursorRight }, // right
            .{ "\x1b[D", Self.moveCursorLeft }, // left
        });

        // variables that are pretty much unchanged once initialized
        original_termios: std.os.termios,
        raw_mode_termios: std.os.termios,
        allocator: std.mem.Allocator,
        settings: Settings,
        tty: File,
        isEndOfUserInput: *const fn (keypress: []const u8, input_pre_cursor: []const u8, input_post_cursor: []const u8) bool = comptime_settings.isEndOfUserInput,

        /// io buffered readers/writers
        input: RingBufferedReader,
        output: RingBufferedWriter,

        /// history handling
        /// (when user presses up or down to select previously executed commands)
        history: History,
        history_selected: ?*History.Node, // current history node that user is using
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
        post_cursor_position: usize,

        /// file that collects all logs
        log_file: ?File,

        pub fn init(settings: Settings) !Self {
            var tty = try std.fs.openFileAbsolute("/dev/tty", .{ .mode = OpenMode.read_write });
            if (!tty.isTty()) {
                return error.DeviceNotTty;
            }
            var input = RingBufferedReader.init(tty.reader());
            var output = RingBufferedWriter.init(tty.writer());

            const original_termios = try std.os.tcgetattr(tty.handle);
            const raw_mode_termios = termios.getRawModeTermios(original_termios);

            var pre_cursor_buffer = array_list.Array(u8).init(settings.allocator);
            var backup_buffer = array_list.Array(u8).init(settings.allocator);
            var post_cursor_buffer = &[_]u8{};

            // const log_file = null;
            const log_file = blk: {
                const log_path = comptime_settings.log_file_path orelse break :blk null;
                const log_file = try std.fs.cwd().createFile(log_path, .{});
                break :blk log_file;
            };

            return Self{
                .tty = tty,
                .input = input,
                .output = output,
                .history = History{},
                .original_termios = original_termios,
                .raw_mode_termios = raw_mode_termios,
                .allocator = settings.allocator,
                .settings = settings,
                .history_selected = null,
                .pre_cursor_buffer = pre_cursor_buffer,
                .backup_buffer = backup_buffer,
                .post_cursor_buffer = post_cursor_buffer,
                .post_cursor_position = 0,
                .log_file = log_file,
            };
        }

        pub fn deinit(self: *Self) void {
            self.pre_cursor_buffer.deinit();
            self.backup_buffer.deinit();

            self.settings.allocator.free(self.post_cursor_buffer);

            const n = self.history.length;
            const valid_nodes = self.history.nodes[0..n];
            for (valid_nodes) |*node| {
                node.value.deinit();
            }
        }

        pub fn run(self: *Self) !void {
            while (true) {
                try self.printPrompt();
                try self.readUserInput();
                if (self.settings.execute(self.pre_cursor_buffer.getAll())) {
                    return;
                }
                self.postExecution();
            }
        }

        fn postExecution(self: *Self) void {
            // Update the history
            if (comptime_settings.history_size == 0) {
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

            if (self.history.length < comptime_settings.history_size) {
                _ = self.history.insertHead(self.pre_cursor_buffer);
                self.pre_cursor_buffer = array_list.Array(u8).init(self.settings.allocator);
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
            try self.printf("{s}", .{self.settings.prompt});
        }

        /// Read user input and store it in self.input_buffer
        fn readUserInput(self: *Self) !void {
            try self.log_to_file("readUserInput: waiting...\n", .{});
            try self.setRawInputMode();
            defer self.setOriginalInputMode() catch |err| {
                self.log_to_file("Failed to set original input mode: {any}", .{err}) catch unreachable;
            };

            self.pre_cursor_buffer.truncate(0);
            self.post_cursor_position = self.post_cursor_buffer.len;
            self.history_selected = null;

            while (true) {
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
                    _ = try self.output.flush();
                    return;
                }

                try self.pre_cursor_buffer.appendSlice(input);
                _ = try self.output.write(input);
                _ = try self.writePostCursorBuffer();

                // TODO: consider async flushing
                _ = try self.output.flush();

                // TODO: generate autocompletion after flush?
            }
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
            try self.printf("\x1b[{d}D", .{to_move_left});
        }

        // return true if handled
        fn handleKeyBind(self: *Self, bytes: []const u8) !bool {
            const action = keybind_by_keypress.get(bytes) orelse return false;
            try action(self);
            return true;
        }

        /// keybind
        fn quit(_: *Self) !void {
            return error.Quit;
        }

        /// keybind
        fn cancel(self: *Self) !void {
            try self.printf("\n", .{});
            self.invalidatePreCursorBuffer();
            self.invalidatePostCursorBuffer();
            try self.reDraw();
        }

        /// keybind
        fn backspace(self: *Self) !void {
            _ = self.pre_cursor_buffer.pop() orelse return;
            try self.printf("\x1b[D", .{}); // move cursor left

            // handle post cursor buffer
            const post_cursor_input = self.validPostCursorBuffer();
            if (post_cursor_input.len > 0) {
                try self.printf("\x1b[K", .{}); // clear from cursor to end of line
                try self.printf("{s}", .{self.validPostCursorBuffer()}); // print post cursor buffer
                try self.printf("\x1b[{d}D", .{self.validPostCursorBuffer().len}); // move cursor left proportionally to len of post cursor buffer
            }
        }

        /// keybind
        fn moveCursorLeft(self: *Self) !void {
            const byte = self.pre_cursor_buffer.pop() orelse return;
            try self.prependPostCursorBuffer(&[_]u8{byte});
            try self.printf("\x1b[D", .{});
        }

        /// keybind
        fn moveCursorRight(self: *Self) !void {
            if (self.post_cursor_position == self.post_cursor_buffer.len) {
                return;
            }

            const byte_after_cursor = self.post_cursor_buffer[self.post_cursor_position];
            try self.pre_cursor_buffer.append(byte_after_cursor);
            self.post_cursor_position += 1;
            try self.printf("\x1b[C", .{});
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
            try self.printf("\r\x1b[K", .{});
            try self.printPrompt();
            try self.printCurrentInput();
        }

        inline fn printCurrentInput(self: *Self) !void {
            try self.printf("{s}", .{self.validPreCursorBuffer()});
            try self.printf("{s}", .{self.validPostCursorBuffer()});
        }

        inline fn setRawInputMode(self: *Self) !void {
            try termios.setTermios(self.tty, self.raw_mode_termios);
        }

        inline fn setOriginalInputMode(self: *Self) !void {
            try termios.setTermios(self.tty, self.original_termios);
        }

        inline fn printf(self: *Self, comptime fmt: []const u8, args: anytype) !void {
            try std.fmt.format(self.output.writer(), fmt, args);
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

pub const ComptimeSettings = struct {
    input_buffer_size: usize = 4096,
    history_size: usize = 100,
    log_file_path: ?[]const u8 = null,
    isEndOfUserInput: fn (keypress: []const u8, input_pre_cursor: []const u8, input_post_cursor: []const u8) bool = defaults.isEndOfUserInput,
};

pub const Settings = struct {
    welcome_message: []const u8 = "Welcome!",
    allocator: std.mem.Allocator,
    execute: *const fn ([]const u8) bool,
    // suggest: ?*fn ([]const u8, usize) [][]const u8 = null,
    prompt: []const u8 = "> ",
};

fn isEnd(byte: u8) bool {
    return byte == '\r';
}
