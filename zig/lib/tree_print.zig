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

    switch (type_info) {
        .Struct => |s| {
            try writer.print("{s} {s}", .{ id_colored, type_name });
            const backup_len = prefix.items.len;
            const last_field_idx = type_info.Struct.fields.len - 1;
            if (last_field_idx == -1) {
                return;
            }

            inline for (s.fields[0..last_field_idx]) |field| {
                try writer.print("\n{s}├─", .{ prefix.items });
                try prefix.appendSlice("│ ");
                try treePrintPrefix(prefix, writer, @field(arg, field.name), "."++field.name);
                prefix.shrinkRetainingCapacity(backup_len);
            }

            try writer.print("\n{s}└─", .{ prefix.items });
            const last_field_name = s.fields[last_field_idx].name;
            try prefix.appendSlice("  ");
            try treePrintPrefix(prefix, writer, @field(arg, last_field_name), "." ++ last_field_name);
            prefix.shrinkRetainingCapacity(backup_len);
        },
        .Array => |a| {
            try writer.print("{s} {s}", .{ id_colored, type_name });
            const backup_len = prefix.items.len;
            const array_len = a.len;
            if (array_len == 0) {
                return;
            }
            inline for (arg[0 .. array_len - 1]) |item, i| {
                try writer.print("\n{s}├─\x1b[33m[{d}]\x1b[m", .{ prefix.items, i });
                try prefix.appendSlice("│ ");
                try treePrintPrefix(prefix, writer, item, "");
                prefix.shrinkRetainingCapacity(backup_len);
            }
            try writer.print("\n{s}└─\x1b[33m[{d}]\x1b[m", .{ prefix.items, array_len - 1 });
            try prefix.appendSlice("  ");
            try treePrintPrefix(prefix, writer, arg[array_len - 1], "");
        },
        .Pointer => |p| {
            switch (p.size) {
                .One => {
                    try writer.print("{s} {s} \n{s}└─", .{ id_colored, type_name, prefix.items });
                    try treePrintPrefix(prefix, writer, arg.*, ".*");
                },
                else => {
                    try writer.print("{s} {s}", .{ id_colored, type_name });
                },
            }
        },
        .Optional => {
            const value = arg orelse {
                try writer.print("{s} {s} {s} null", .{ id_colored, type_name, arrow });
                return;
            };
            try writer.print("{s} {s} \n{s}└─", .{ id_colored, type_name, prefix.items });
            try treePrintPrefix(prefix, writer, value, ".?");
        },
        else => {
            try writer.print("{s} {s} {s} {any}", .{ id_colored, type_name, arrow, arg });
        },
    }
}

const Person = struct {
    o_i: ?i32 = 9,
    o_j: ?i32 = null,
    v: void = undefined,
    b: bool = true,
    f: f32 = 3.14,
    age: u8,
    name: []const u8,
    cc: CreditCard = .{},
    code: [3]u8 = [_]u8{ 1, 2, 3 },
    k: type = u16,
    int_ptr: *const u8,
};

const CreditCard = struct {
    name: []const u8 = "john",
    number: u64 = 999,
    number2: u64 = 999,
    debt: Debt = .{},
};

const Debt = struct {
    id: u32 = 0,
    amount: u64 = 888,
};

pub fn main() !void {
    const int: u8 = 7;

    // std.fmt.format
    const person = Person{
        .age = 20,
        .name = "John",
        .int_ptr = &int,
    };

    var w = std.io.getStdOut().writer();

    // treePrint(std.io.getStdOut(), person);
    try treePrint(std.heap.page_allocator, w, person);
}

// TODO: Array
