const std = @import("std");
const builtin = @import("builtin");
const array_list = @import("./array_list.zig");
const fdll = @import("./fixed_doubly_linked_list.zig");
const ring_buffered_reader = @import("./ring_buffered_reader.zig");
const ring_buffered_writer = @import("./ring_buffered_writer.zig");
const File = std.fs.File;
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

        // variables that are pretty much unchanged once initialized
        original_termios: std.os.termios,
        raw_mode_termios: std.os.termios,
        allocator: std.mem.Allocator,
        settings: Settings,
        tty: File,

        // variables that are changed as the program runs
        input: RingBufferedReader,
        output: RingBufferedWriter,
        history: History,
        history_selected: ?*History.Node, // current history node that user is using
        input_buffer: array_list.Array(u8),
        backup_buffer: array_list.Array(u8),

        post_cursor_buffer: []u8,
        post_cursor_position: usize,

        log_file: ?File,

        pub fn init(settings: Settings) !Self {
            var tty = try std.fs.openFileAbsolute("/dev/tty", .{ .write = true });
            if (!tty.isTty()) {
                return error.DeviceNotTty;
            }
            var input = RingBufferedReader.init(tty.reader());
            var output = RingBufferedWriter.init(tty.writer());

            const original_termios = try std.os.tcgetattr(tty.handle);
            const raw_mode_termios = termios.getRawModeTermios(original_termios);

            var input_buffer = array_list.Array(u8).init(settings.allocator);
            var backup_buffer = array_list.Array(u8).init(settings.allocator);
            var post_cursor_buffer = &[_]u8{};

            const log_file = blk: {
                const log_path = comptime_settings.log_file_path orelse break :blk null;
                const log_file = try std.fs.cwd().createFile(log_path, .{ .read = true });
                break :blk log_file;
            };

            return Self {
                .tty = tty,
                .input = input,
                .output = output,
                .history = History{},
                .original_termios = original_termios,
                .raw_mode_termios = raw_mode_termios,
                .allocator = settings.allocator,
                .settings = settings,
                .history_selected = null,
                .input_buffer = input_buffer,
                .backup_buffer = backup_buffer,
                .post_cursor_buffer = post_cursor_buffer,
                .post_cursor_position = 0,
                .log_file = log_file,
            };
        }

        pub fn deinit(self: *Self) void {
            self.input_buffer.deinit();
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
                const post_cursor_input = self.post_cursor_buffer[self.post_cursor_position..];
                try self.input_buffer.appendSlice(post_cursor_input);
                if (self.settings.execute(self.input_buffer.getAll())) {
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
                if (std.mem.eql(u8, h.value.elems, self.input_buffer.elems)) {
                    // h is invalidated after removal from self.history
                    // hence we need to get the buffer before removal
                    const history_buffer = h.value;

                    self.history.remove(h);
                    _ = self.history.insertHead(history_buffer);
                    return;
                }
            }

            if (self.history.length < comptime_settings.history_size) {
                _ = self.history.insertHead(self.input_buffer);
                self.input_buffer = array_list.Array(u8).init(self.settings.allocator);
                return;
            }

            // swap the input buffer with the last node's in the history
            // last node is kicked out and reinserted
            const node = self.history.tail orelse unreachable;
            self.history.remove(node);
            const node_buffer = node.value;
            _ = self.history.insertHead(self.input_buffer) orelse unreachable;
            self.input_buffer = node_buffer;
        }

        fn printPrompt(self: *Self) !void {
            // TODO: might add dynamic prompt later
            try self.printf("{s}", .{self.settings.prompt});
        }

        fn readUserInput(self: *Self) !void {
            try self.setRawInputMode();
            defer self.setOriginalInputMode() catch |err| {
                self.printf("Failed to set original input mode: {any}", .{err})
                    catch unreachable;
            };

            self.input_buffer.truncate(0);
            self.post_cursor_position = self.post_cursor_buffer.len;
            self.history_selected = null;

            while (true) {
                const input = try self.input.readConst();
                const handled = try self.handleKeyBind(input);
                if (handled) {
                    continue;
                }

                // TODO: better way to check end
                for (input) |byte| {
                    if (isEnd(byte)) {
                        _ = try self.output.write("\r\n");
                        _ = try self.output.flush();
                        return;
                    }
                }

                try self.input_buffer.appendSlice(input);
                _ = try self.output.write(input);
                _ = try self.writePostCursorBuffer();

                _ = try self.output.flush();
                // TODO: generate autocomplete here?
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
                std.mem.copy(u8, new_post_cursor_buffer[final_size - post_buffer_len..], self.post_cursor_buffer[self.post_cursor_position..]);  
                self.allocator.free(self.post_cursor_buffer);
                self.post_cursor_buffer = new_post_cursor_buffer;
                break :blk final_size - bytes.len;
            };
            std.mem.copy(u8, self.post_cursor_buffer[final_post_buffer_cursor..], bytes);
            self.post_cursor_position = final_post_buffer_cursor;
        }

        fn writePostCursorBuffer(self: *Self) !void {
            _ = try self.output.write(self.post_cursor_buffer[self.post_cursor_position..]);
        }

        // TODO: hash table
        // return true if handled, input will not be added to the input_buffer
        fn handleKeyBind(self: *Self, bytes: []const u8) !bool {
            if (std.mem.eql(u8, bytes, &[_]u8{3})) { // ctrl-c
                return error.Cancel;
            } else if (std.mem.eql(u8, bytes, &[_]u8{4})) { // ctrl-d
                return error.Quit;
            } else if (std.mem.eql(u8, bytes, "\x1b[A")) { // up arrow
                try self.selectLessRecent();
                return true;
            } else if (std.mem.eql(u8, bytes, "\x1b[B")) { // down arrow
                try self.selectMoreRecent();
                return true;
            } else if (std.mem.eql(u8, bytes, "\x1b[C")) { // right arrow
                try self.moveCursorRight();
                return true;
            } else if (std.mem.eql(u8, bytes, "\x1b[D")) { // right arrow
                try self.moveCursorLeft();
                return true;
            }

            // TODO: handle other keybinds
            // return false to skip appending key to input buffer

            return false;
        }

        fn moveCursorLeft(self: *Self) !void {
            // TODO: handle multi-byte characters
            const byte = self.input_buffer.pop() orelse return;
            try self.prependPostCursorBuffer(&[_]u8{byte});
            try self.printf("\x1b[D", .{});
        }

        fn moveCursorRight(self: *Self) !void {
            if (self.post_cursor_position == self.post_cursor_buffer.len) {
                // try self.printf("self.post_cursor_position: {d}", .{self.post_cursor_position});
                // try self.printf("self.post_cursor_buffer_len: {d}", .{self.post_cursor_buffer.len});
                return;
            }

            // TODO: handle multi-byte characters
            const byte_after_cursor = self.post_cursor_buffer[self.post_cursor_position];
            try self.input_buffer.append(byte_after_cursor);
            self.post_cursor_position += 1;
            try self.printf("\x1b[C", .{});
        }

        fn switchInputBuffer(self: *Self) void {
            const tmp = self.input_buffer;
            self.input_buffer = self.backup_buffer;
            self.backup_buffer = tmp;

            // TODO: preserve cursor position after switch back
            self.post_cursor_position = self.post_cursor_buffer.len; 
        }

        fn selectLessRecent(self: *Self) !void {
            const history_selected = self.history_selected orelse {
                // switch buffer
                self.history_selected = self.history.head orelse return;
                self.switchInputBuffer();
                try self.setInputBufferContent(self.history_selected.?.value.elems);
                try self.reDraw();
                return;
            };

            const less_recent_node = history_selected.next orelse return;
            self.history_selected = less_recent_node;
            try self.setInputBufferContent(less_recent_node.value.elems);
            try self.reDraw();
        }

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

        fn setInputBufferContent(self: *Self, content: []const u8) !void {
            self.input_buffer.truncate(0);
            try self.input_buffer.appendSlice(content);
        }

        fn reDraw(self: *Self) !void {
            // move cursor to the beginning of the line & clear the line
            try self.printf("\r\x1b[K", .{});
            try self.printPrompt();
            try self.printInputBuffer();
        }

        fn printInputBuffer(self: *Self) !void {
            try self.printf("{s}", .{self.input_buffer.elems});
        }

        fn setRawInputMode(self: *Self) !void {
            try termios.setTermios(self.tty, self.raw_mode_termios);
        }

        fn setOriginalInputMode(self: *Self) !void {
            try termios.setTermios(self.tty, self.original_termios);
        }

        fn printf(self: *Self, comptime fmt: []const u8, args: anytype) !void {
            std.fmt.format(self.output.writer(), fmt, args) catch unreachable;
            _ = try self.output.flush();
        }
    };
}

pub const ComptimeSettings = struct {
    input_buffer_size: usize = 4096,
    history_size: usize = 100,
    log_file_path: ?[]const u8 = null,
};

pub const Settings = struct {
    welcome_message: []const u8 = "Welcome!",
    allocator: std.mem.Allocator,
    execute: fn ([]const u8) bool,
    suggest: ?fn ([]const u8, usize) [][]const u8 = null,
    prompt: []const u8 = "> ",
};

fn isEnd(byte: u8) bool {
    return byte == '\r';
}

// pub fn main() !void {
//     var tty = try std.fs.openFileAbsolute("/dev/tty", .{});
//     var original_termios = try std.os.tcgetattr(tty.handle);
//     var raw_mode_termios = getRawModeTermios(original_termios);
//     try setTermios(tty, raw_mode_termios);
//     defer setTermios(tty, original_termios) catch |err| {
//         std.debug.print("unsetRaw failed, {}", .{err});
//     };
//
//     var buf: [1]u8 = undefined;
//     var tty_reader = tty.reader();
//     while (true) {
//         const byte = try tty_reader.readByte();
//         if (byte == 3) { // Ctrl-C
//             return;
//         }
//         buf[0] = byte;
//         std.debug.print("{s}, {d}\r\n", .{buf, buf});
//     }
// }



// TODO: get terminal size
// TODO: support utf-8 input?
// TODO: log to file
