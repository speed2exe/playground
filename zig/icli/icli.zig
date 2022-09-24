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

        pub fn init(settings: Settings) !Self {
            var tty = try std.fs.openFileAbsolute("/dev/tty", .{ .write = true });
            if (!tty.isTty()) {
                return error.DeviceNotTty;
            }
            var input = RingBufferedReader.init(tty.reader());
            var output = RingBufferedWriter.init(tty.writer());

            const original_termios = try std.os.tcgetattr(tty.handle);
            const raw_mode_termios = termios.getRawModeTermios(original_termios);

            // nope, we don't want to do this, 
            var input_buffer = array_list.Array(u8).init(settings.allocator);
            var backup_buffer = array_list.Array(u8).init(settings.allocator);

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
            };
        }

        pub fn deinit(self: *Self) void {
            self.input_buffer.deinit();
            self.backup_buffer.deinit();

            const n = self.history.length;
            const valid_nodes = self.history.nodes[0..n];
            for (valid_nodes) |*node| {
                // self.printf("data of node: {s}\n",.{node.value.elems}) catch unreachable;
                node.value.deinit();
            }
        }

        pub fn run(self: *Self) !void {
            while (true) {
                try self.printPrompt();

                try self.readUserInput();
                if (self.settings.execute(self.input_buffer.getAll())) {
                    return;
                }
                self.postExecution();
            }
        }

        fn postExecution(self: *Self) void {
            if (comptime_settings.history_size == 0) {
                return;
            }

            // TODO: fix this
            if (self.history_selected) |h| {
                if (std.mem.eql(u8, h.value.elems, self.input_buffer.elems)) {
                    var n = self.history.length;
                    var valid_nodes = self.history.nodes[0..n];
                    for (valid_nodes) |*node| {
                        self.printf("n: {s}\n", .{node.value.elems}) catch unreachable;
                    }

                    self.history.remove(h);
                    _ = self.history.insertHead(h.value);

                    n = self.history.length;
                    valid_nodes = self.history.nodes[0..n];
                    for (valid_nodes) |*node| {
                        self.printf("n: {s}\n", .{node.value.elems}) catch unreachable;
                    }

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
            self.history_selected = null;

            while (true) {
                const input = try self.input.readConst();
                const handled = try self.handleKeyBind(input);
                if (handled) {
                    continue;
                }

                for (input) |byte| {
                    if (isEnd(byte)) {
                        _ = try self.output.write("\r\n");
                        _ = try self.output.flush();
                        return;
                    }

                    try self.input_buffer.append(byte);
                    _ = try self.output.write(&[1]u8{byte});

                    // TODO: handle inputs after end
                }
                _ = try self.output.flush();
                // TODO: generate autocomplete here?
            }
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
            }


            // TODO: handle other keybinds
            // return false to skip appending key to input buffer

            return false;
        }

        fn switchInputBuffer(self: *Self) void {
            const tmp = self.input_buffer;
            self.input_buffer = self.backup_buffer;
            self.backup_buffer = tmp;
        }

        fn selectLessRecent(self: *Self) !void {
            const history_selected = self.history_selected orelse {
                // switch buffer
                self.history_selected = self.history.head orelse return;
                try self.printf("debug: 1",.{});
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

        fn setInputBufferContent(self: *Self, content: []u8) !void {
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
