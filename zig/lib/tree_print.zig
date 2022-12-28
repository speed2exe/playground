const std = @import("std");
const builtin = std.builtin;
const log = std.log;

const arrow = "\x1b[90m" ++ "=>" ++ "\x1b[m";

pub fn treePrint(allocator: std.mem.Allocator, writer: anytype, arg: anytype) !void {
    var prefix = std.ArrayList(u8).init(allocator);
    defer prefix.deinit();
    try treePrintPrefix(&prefix, writer, arg, "(arg)");
}

pub fn treePrintPrefix(prefix: *std.ArrayList(u8), writer: anytype, arg: anytype, comptime id: []const u8) !void {
    const arg_type = @TypeOf(arg);
    const type_info = @typeInfo(arg_type);
    const type_name = "\x1b[36m" ++ @typeName(arg_type) ++ "\x1b[m"; // cyan colored
    const id_colored = "\x1b[33m" ++ id ++ "\x1b[m"; // yellow colored

    // TODO: for reference purposes
    // std.fmt.format

    switch (type_info) {
        .Type => {
            try writer.print("{s}{s} {s} {s} {s}\n", .{ prefix.items, id_colored, type_name, arrow, @typeName(arg) });
        },
        .Struct => |s| {
            try writer.print("{s}{s} {s}\n", .{ prefix.items, id_colored, type_name });
            const backup = prefix.items.len;
            const last_field_idx = type_info.Struct.fields.len - 1;
            if (last_field_idx == -1) {
                return;
            }

            try prefix.appendSlice(" ├─ ");
            inline for (s.fields[0..last_field_idx]) |field| {
                try treePrintPrefix(prefix, writer, @field(arg, field.name), field.name);
            }

            prefix.shrinkRetainingCapacity(backup);
            try prefix.appendSlice(" └─ ");
            const last_field_name = s.fields[last_field_idx].name;
            try treePrintPrefix(prefix, writer, @field(arg, last_field_name), last_field_name);
        },
        .Int => {
            try writer.print("{s}{s} {s} {s} {d}\n", .{ prefix.items, id_colored, type_name, arrow, arg });
        },
        else => {
            try writer.print("{s}{s} {s} {s} (not handled)\n", .{ prefix.items, id_colored, type_name, arrow });
        },
    }
}

const Person = struct {
    age: u8,
    name: []const u8,
    k: type = u16,
};

pub fn main() !void {
    // std.fmt.format
    const person = Person{
        .age = 20,
        .name = "John",
    };

    var w = std.io.getStdOut().writer();

    // treePrint(std.io.getStdOut(), person);
    try treePrint(std.heap.page_allocator, w, person);
}

// TODO: check for leak
