const std = @import("std");

pub fn BufferReader (
    comptime ReaderType: type,
    comptime BufferType: type,
) type {

    return struct {
        const Self = @This();

        pub const Reader = std.io.Reader(*Self, anyerror, read);

        pub const BufferReader = std.io.Reader(BufferType, BufferType.Error, BufferType.read);
        pub const BufferWriter = std.io.Writer(BufferType, BufferType.Error, BufferType.write);

        src: ReaderType,
        buffer: BufferType,

        pub fn init(reader: ReaderType, buffer: BufferType) Self {

        }

        pub fn read() Error!usize {

        }


    };
}
