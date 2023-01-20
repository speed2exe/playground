const std = @import("std");
const builtin = std.builtin;
const log = std.log;

const arrow = "\x1b[90m" ++ "=>" ++ "\x1b[m";

pub fn treePrint(allocator: std.mem.Allocator, writer: anytype, arg: anytype, comptime id: []const u8) !void {
    var prefix = std.ArrayList(u8).init(allocator);
    defer prefix.deinit();
    try treePrintPrefix(&prefix, writer, arg, id);
    try writer.print("\n", .{});
}

fn treePrintPrefix(prefix: *std.ArrayList(u8), writer: anytype, arg: anytype, comptime id: []const u8) !void {
    const arg_type = @TypeOf(arg);
    const type_info = @typeInfo(arg_type);
    const type_name = @typeName(arg_type);
    const type_name_colored = "\x1b[36m" ++ type_name ++ "\x1b[m"; // cyan colored
    const id_colored = "\x1b[33m" ++ id ++ "\x1b[m"; // yellow colored

    switch (type_info) {
        .Struct => |s| {
            try writer.print("{s} {s}", .{ id_colored, type_name_colored });
            if (s.fields.len == 0) return;

            const last_field_idx = s.fields.len - 1;
            if (last_field_idx == -1) return;

            const backup_len = prefix.items.len;
            {
                inline for (s.fields[0..last_field_idx]) |field| {
                    try writer.print("\n{s}├─", .{prefix.items});
                    try prefix.appendSlice("│ ");
                    try treePrintPrefix(prefix, writer, @field(arg, field.name), "." ++ field.name);
                    prefix.shrinkRetainingCapacity(backup_len);
                }
            }
            {
                try writer.print("\n{s}└─", .{prefix.items});
                const last_field_name = s.fields[last_field_idx].name;
                try prefix.appendSlice("  ");
                try treePrintPrefix(prefix, writer, @field(arg, last_field_name), "." ++ last_field_name);
                prefix.shrinkRetainingCapacity(backup_len);
            }
        },
        .Array => |a| {
            try writer.print("{s} {s}", .{ id_colored, type_name_colored });
            if (arg.len == 0) {
                return;
            }
            if (a.child == u8) {
                try writer.print(" {s} \"{s}\"", .{ arrow, arg });
            }
            {
                const backup_len = prefix.items.len;
                inline for (arg[0 .. arg.len - 1]) |item, i| {
                    try writer.print("\n{s}├─\x1b[33m[{d}]\x1b[m", .{ prefix.items, i });
                    try prefix.appendSlice("│ ");
                    try treePrintPrefix(prefix, writer, item, "");
                    prefix.shrinkRetainingCapacity(backup_len);
                }
            }
            {
                try writer.print("\n{s}└─\x1b[33m[{d}]\x1b[m", .{ prefix.items, arg.len - 1 });
                try prefix.appendSlice("  ");
                try treePrintPrefix(prefix, writer, arg[arg.len - 1], "");
            }
        },
        .Pointer => |p| {
            switch (p.size) {
                .One => {
                    try writer.print("{s} {s} \x1b[34m@{x}\x1b[m", .{ id_colored, type_name_colored, @ptrToInt(arg) });
                    if (p.child == anyopaque) {
                        return;
                    }
                    const child_type_info = @typeInfo(p.child);
                    switch (child_type_info) {
                        .Fn => {
                            return;
                        },
                        else => {},
                    }
                    if (!isComptime(arg)) {
                        switch (child_type_info) {
                            .Opaque => {
                                return;
                            },
                            else => {},
                        }
                    }
                    {
                        try writer.print("\n{s}└─", .{prefix.items});
                        const backup_len = prefix.items.len;
                        try prefix.appendSlice("  ");
                        try treePrintPrefix(prefix, writer, arg.*, ".*");
                        prefix.shrinkRetainingCapacity(backup_len);
                    }
                },
                .Slice => {
                    try writer.print("{s} {s}", .{ id_colored, type_name_colored });
                    if (arg.len == 0) {
                        return;
                    }
                    if (p.child == u8) {
                        try writer.print(" \"{s}\"", .{arg});
                    }
                    try writer.print(" \x1b[34m@{x}\x1b[m", .{@ptrToInt(arg.ptr)});
                    {
                        const backup_len = prefix.items.len;
                        for (arg[0 .. arg.len - 1]) |item, i| {
                            try writer.print("\n{s}├─\x1b[33m[{d}]\x1b[m", .{ prefix.items, i });
                            try prefix.appendSlice("│ ");
                            try treePrintPrefix(prefix, writer, item, "");
                            prefix.shrinkRetainingCapacity(backup_len);
                        }
                    }
                    {
                        try writer.print("\n{s}└─\x1b[33m[{d}]\x1b[m", .{ prefix.items, arg.len - 1 });
                        try prefix.appendSlice("  ");
                        try treePrintPrefix(prefix, writer, arg[arg.len - 1], "");
                    }
                },
                else => {
                    try writer.print("{s} {s} \x1b[34m@{x}\x1b[m", .{ id_colored, type_name_colored, @ptrToInt(arg) });
                },
            }
        },
        .Optional => {
            const value = arg orelse {
                try writer.print("{s} {s} {s} null", .{ id_colored, type_name_colored, arrow });
                return;
            };
            try writer.print("{s} {s} \n{s}└─", .{ id_colored, type_name_colored, prefix.items });
            try treePrintPrefix(prefix, writer, value, ".?");
        },
        else => {
            try writer.print("{s} {s} {s} {any}", .{ id_colored, type_name_colored, arrow, arg });
        },
    }
}

const Person = struct {
    o_i: ?i32 = 9,
    // o_j: ?i32 = null,
    // v: void = undefined,
    // b: bool = true,
    // f: f32 = 3.14,
    // age: u8 = 34,
    // name: []const u8 = "jon",
    // cc: CreditCard = .{},
    // code: [3]u8 = [_]u8{ 1, 2, 3 },
    // k: type = u16,
    int_ptr: *const u8,
    f: *const fn () void = myFunc,
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

const Debt2 = struct {
    id: *u32,
};

pub fn main() !void {
    var w = std.io.getStdOut().writer();
    var int: u8 = 7;

    // std.fmt.format
    const person = Person{
        .int_ptr = &int,
    };

    var cc = CreditCard{
        .name = "john",
        .number = 999,
        .number2 = 999,
        .debt = Debt{
            .id = 0,
            .amount = 888,
        },
    };
    // const person1 = Person{
    //     .age = 20,
    //     .name = "John",
    //     .int_ptr = &int,
    // };

    var i: u32 = 0;
    var d2 = Debt2{
        .id = &i,
    };

    try treePrint(std.heap.page_allocator, w, d2, "d23333");
    try treePrint(std.heap.page_allocator, w, person, "\nperson");
    try treePrint(std.heap.page_allocator, w, cc, "\ncc");
}

inline fn isComptime(val: anytype) bool {
    return @typeInfo(@TypeOf(.{val})).Struct.fields[0].is_comptime;
}

fn myFunc() void {}
