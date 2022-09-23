// Bug in Zig for version 0.9.1, on hold project until bug is fixed

const std = @import("std");

pub fn treePrint(allocator: std.mem.Allocator, writer: anytype, arg: anytype) !void {
    var prefix = std.ArrayList(u8).init(allocator);
    defer prefix.deinit();
    try treePrintPrefix(&prefix, writer, arg);
}

pub fn treePrintPrefix(prefix: *std.ArrayList(u8), writer: anytype, arg: anytype) !void {
    _ = writer;

    const arg_type = @TypeOf(arg);
    const type_info = @typeInfo(arg_type);
    const type_name = @typeName(arg_type);

    // TODO: for reference purposes
    // std.fmt.format

    switch (type_info) {
        .Struct => {
            try writer.print("{s}{s}: Struct\n",.{prefix.items, type_name});
            const backup = prefix.items.len;
            const last_field_idx = type_info.Struct.fields.len - 1;
            if (last_field_idx == -1) {
                return;
            }

            try prefix.appendSlice(" ├─ ");
            inline for (type_info.Struct.fields[0..last_field_idx]) |field| {
                try treePrintPrefix(prefix, writer, @field(arg, field.name));
            }

            prefix.shrinkRetainingCapacity(backup);
            try prefix.appendSlice(" └─ ");
            try treePrintPrefix(prefix, writer, @field(arg, type_info.Struct.fields[last_field_idx].name));
        },
        else => {
            try writer.print("not handled: {s}:{s}\n", .{type_name, type_info});
        }
    }
}

const Person = struct {
    age: u8,
    name: []const u8,
};

pub fn main() !void {
    // std.fmt.format
    var person = Person {
        .age = 20,
        .name = "John",
    };


    var w = std.io.getStdOut().writer();

    // treePrint(std.io.getStdOut(), person);
    try treePrint(std.heap.page_allocator, w, person);
}

// TODO: check for leak
