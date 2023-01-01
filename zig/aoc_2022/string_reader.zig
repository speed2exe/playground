const std = @import("std");
const testing = std.testing;

pub const StringReader = struct {
    data: []const u8,

    pub const Reader = std.io.Reader(*StringReader, anyerror, read);

    pub fn init(data: []const u8) StringReader {
        return StringReader{
            .data = data,
        };
    }

    pub fn read(self: *StringReader, buffer: []u8) anyerror!usize {
        var max_copyable: usize = buffer.len;
        if (max_copyable > self.data.len) {
            max_copyable = self.data.len;
        }
        std.mem.copy(u8, buffer, self.data[0..max_copyable]);
        self.data = self.data[max_copyable..];
        return max_copyable;
    }

    pub fn reader(self: *StringReader) Reader {
        return Reader{ .context = self };
    }
};

test "StringReader" {
    var buffer: [2]u8 = undefined;
    var string_reader = StringReader.init("abcde");
    var reader = string_reader.reader();

    {
        const n = try reader.read(&buffer);
        try testing.expect(n == 2);
        const expected = "ab";
        try testing.expectEqualSlices(u8, expected, &buffer);
    }
    {
        const n = try reader.read(&buffer);
        try testing.expect(n == 2);
        const expected = "cd";
        try testing.expectEqualSlices(u8, expected, &buffer);
    }
    {
        const n = try reader.read(&buffer);
        try testing.expect(n == 1);
        const expected = "ed"; // 2nd byte not copied
        try testing.expectEqualSlices(u8, expected, &buffer);
    }
}
