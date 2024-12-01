const std = @import("std");
const log = std.log.scoped(.line_reader);

const BUFFER_SIZE = 4096; // 4KB

/// LineReader is a struct that reads lines from stdin
/// max single line length is BUFFER_SIZE (4096)
pub const LineReader = struct {
    buffer: [BUFFER_SIZE]u8 = undefined,
    len: usize = 0,
    ptr: usize = 0,

    file: std.fs.File = std.io.getStdIn(),

    // Read a line from stdin
    // value in valid until next read
    // returns null if EOF
    pub fn next(s: *LineReader) !?[]const u8 {
        s.fillBufferIfEmpty() catch |err| {
            if (err == error.EOF) {
                if (s.len == s.ptr) return null;
                const line = s.buffer[s.ptr..s.len];
                s.ptr = s.len;
                return line;
            }
            return err;
        };
        std.debug.assert(s.len > s.ptr);

        // try read current buffer until newline
        var start = s.ptr;
        const end = s.len;
        while (start < end) : (start += 1) {
            if (s.buffer[start] == '\n') {
                const line = s.buffer[s.ptr..start];
                s.ptr = start + 1;
                return line;
            }
        }

        // newline not found, shift data left and continue
        if (s.ptr > 0) s.shiftDataLeft();
        return s.nextContinue(s.len);
    }

    fn nextContinue(s: *LineReader, alr_read: usize) !?[]const u8 {
        std.debug.assert(alr_read > 0);

        // assume all data left aligned
        std.debug.assert(s.ptr == 0);

        if (s.len == BUFFER_SIZE) return error.LineTooLong;

        s.fillBufferExtend() catch |err| {
            if (err == error.EOF) {
                const line = s.buffer[s.ptr..s.len];
                s.ptr = s.len;
                return line;
            }
            return err;
        };

        var new_start = alr_read;
        while (new_start < s.len) : (new_start += 1) {
            if (s.buffer[new_start] == '\n') {
                const line = s.buffer[0..new_start];
                s.ptr = new_start + 1;
                return line;
            }
        }

        return s.nextContinue(new_start);
    }

    // incur 0 or 1 read
    fn fillBufferIfEmpty(s: *LineReader) !void {
        if (s.len == s.ptr) {
            s.ptr = 0;
            s.len = 0;

            const n = try s.file.read(&s.buffer);
            if (n == 0) return error.EOF;

            s.len = n;
            s.ptr = 0;
        }
    }

    fn shiftDataLeft(s: *LineReader) void {
        std.debug.assert(s.ptr > 0);

        var start = s.ptr;
        const end = s.len;
        var dest: usize = 0;
        while (start < end) : ({
            start += 1;
            dest += 1;
        }) s.buffer[dest] = s.buffer[start];

        s.ptr = 0;
        s.len = dest;
    }

    // fill buffer and extend if possible
    // incur 1 read if successful
    fn fillBufferExtend(s: *LineReader) !void {
        std.debug.assert(BUFFER_SIZE > s.len);

        const n = try s.file.read(s.buffer[s.len..]);
        if (n == 0) return error.EOF;
        s.len += n;
    }
};
