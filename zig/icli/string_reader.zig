const std = @import("std");
const testing = std.testing;

pub const StringReader = struct {
    data: []const u8,

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
};

test "StringReader" {
    var buffer: [2]u8 = undefined;
    var sr = StringReader.init("abcde");
    var reader = std.io.Reader(*StringReader, anyerror, StringReader.read){ .context = &sr };

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
