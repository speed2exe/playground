const std = @import("std");
const builtin = std.builtin;
const log = std.log;

const ansi_esc_code = @import("./ansi_esc_code.zig");
const Color = ansi_esc_code.Color;
const comptimeFmtInColor = ansi_esc_code.comptimeFmtInColor;
const comptimeInColor = ansi_esc_code.comptimeInColor;

const arrow = comptimeFmtInColor(Color.bright_black, "=>", .{});
const empty = " " ++ arrow ++ " {}";

pub const TreePrinter = struct {
    const address_fmt = comptimeInColor(Color.blue, "@{x}");

    /// settings
    array_print_limit: usize = 10,
    print_u8_chars: bool = true,

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) TreePrinter {
        return TreePrinter{ .allocator = allocator };
    }

    pub fn printValue(self: TreePrinter, writer: anytype, arg: anytype) !void {
        return self.printValueWithId(writer, arg, ".");
    }

    pub fn printValueWithId(self: TreePrinter, writer: anytype, arg: anytype, comptime id: []const u8) !void {
        var prefix = std.ArrayList(u8).init(self.allocator);
        defer prefix.deinit();
        try self.printValueImpl(&prefix, writer, arg, id);
        try writer.print("\n", .{});
    }

    fn printValueImpl(self: TreePrinter, prefix: *std.ArrayList(u8), writer: anytype, arg: anytype, comptime id: []const u8) !void {
        const arg_type = @TypeOf(arg);
        try writer.print("{s} {s}", .{ 
            comptimeInColor(Color.yellow, id),
            comptimeInColor(Color.cyan, @typeName(arg_type)),
        });

        switch (@typeInfo(arg_type)) {
            .Struct => |s| {
                if (s.fields.len == 0) {
                    try writer.writeAll(empty);
                    return;
                }
                try self.printStructValues(prefix, writer, arg, s);
            },
            .Array => |a| {
                if (a.child == u8 and self.print_u8_chars) try writer.print(" {s}", .{ arg });
                if (arg.len == 0){
                    try writer.writeAll(empty);
                    return;
                }

                try self.printArrayValues(prefix, writer, arg);
            },
            .Pointer => |p| {
                switch (p.size) {
                    .One => {
                        try writer.print(" " ++ address_fmt, .{ @ptrToInt(arg) });
                        // TODO: segment ignores unprintable values, verification is needed
                        if (p.child == anyopaque) return;
                        const child_type_info = @typeInfo(p.child);
                        switch (child_type_info) {
                            .Fn => return,
                            else => {},
                        }
                        if (!isComptime(arg)) {
                            switch (child_type_info) {
                                .Opaque => return,
                                else => {},
                            }
                        }

                        try writer.print("\n{s}└─", .{prefix.items});
                        const backup_len = prefix.items.len;
                        try prefix.appendSlice("  ");
                        try self.printValueImpl(prefix, writer, arg.*, ".*");
                        prefix.shrinkRetainingCapacity(backup_len);
                    },
                    .Slice => {
                        try writer.print(" " ++ address_fmt, .{ @ptrToInt(arg.ptr) });
                        if (p.child == u8 and self.print_u8_chars) try writer.print(" \"{s}\"", .{arg});
                        if (arg.len == 0) return;
                        try self.printSliceValues(prefix, writer, arg);
                    },
                    else => {
                        try writer.print(" {s} {any}", .{ arrow, arg });
                    },
                }
            },
            .Optional => {
                const value = arg orelse {
                    try writer.print(" {s} null", .{ arrow });
                    return;
                };
                try writer.print(" \n{s}└─", .{ prefix.items });
                try self.printValueImpl(prefix, writer, value, ".?");
            },
            .Enum => try writer.print(" {s} {} ({d})", .{ arrow, arg, @enumToInt(arg) }),
            .Fn => try writer.print(" " ++ address_fmt, .{ @ptrToInt(&arg) }),
            else => try writer.print(" {s} {any}", .{ arrow, arg }),
        }
    }

    inline fn printArrayValues(self: TreePrinter, prefix: *std.ArrayList(u8), writer: anytype, arg: anytype) !void {
        const backup_len = prefix.items.len;
        inline for (arg[0 .. arg.len - 1]) |item, i| {
            try writer.print("\n{s}├─", .{ prefix.items });
            try prefix.appendSlice("│ ");
            const index_colored = comptime comptimeFmtInColor(Color.yellow, "[{d}]", .{i});
            try self.printValueImpl(prefix, writer, item, index_colored);
            prefix.shrinkRetainingCapacity(backup_len);
        }
        try writer.print("\n{s}└─", .{ prefix.items });
        try prefix.appendSlice("  ");
        const index_colored = comptime comptimeFmtInColor(Color.yellow, "[{d}]", .{arg.len - 1});
        try self.printValueImpl(prefix, writer, arg[arg.len - 1], index_colored);
    }

    inline fn printSliceValues(self: TreePrinter, prefix: *std.ArrayList(u8), writer: anytype, arg: anytype) !void {
        const index_fmt = comptime comptimeInColor(Color.yellow, "[{d}]");
        const backup_len = prefix.items.len;
        for (arg[0 .. arg.len - 1]) |item, i| {
            try writer.print("\n{s}├─" ++ index_fmt, .{ prefix.items, i });
            try prefix.appendSlice("│ ");
            try self.printValueImpl(prefix, writer, item, "");
            prefix.shrinkRetainingCapacity(backup_len);
        }
        try writer.print("\n{s}└─" ++ index_fmt, .{ prefix.items, arg.len - 1 });
        try prefix.appendSlice("  ");
        try self.printValueImpl(prefix, writer, arg[arg.len - 1], "");
    }

    inline fn printStructValues(self: TreePrinter, prefix: *std.ArrayList(u8), writer: anytype, arg: anytype, comptime s: std.builtin.Type.Struct) !void {
        const backup_len = prefix.items.len;
        const last_field_idx = s.fields.len - 1;
        inline for (s.fields[0..last_field_idx]) |field| {
            try writer.print("\n{s}├─", .{prefix.items});
            try prefix.appendSlice("│ ");
            try self.printValueImpl(prefix, writer, @field(arg, field.name), "." ++ field.name);
            prefix.shrinkRetainingCapacity(backup_len);
        }
        try writer.print("\n{s}└─", .{prefix.items});
        const last_field_name = s.fields[last_field_idx].name;
        try prefix.appendSlice("  ");
        try self.printValueImpl(prefix, writer, @field(arg, last_field_name), "." ++ last_field_name);
        prefix.shrinkRetainingCapacity(backup_len);
    }
};

var i32_value: i32 = 42;

const Struct1 = struct {

    // can only be printed if S is comptime known
    // k: type = u16,

    field_void: void = undefined,
    field_bool: bool = true,
    field_u8: u32 = 11,
    field_float: f32 = 3.14,

    field_i32_ptr: *i32 = &i32_value,
    field_slice_u8: []const u8 = "s1 string",

    field_array_u8: [3]u8 = [_]u8{ 1, 2, 3 },
    field_array_u8_empty: [0]u8 = .{},

    field_s2: Struct2 = .{},
    field_comptime_float: comptime_float = 3.14,
    field_comptime_int: comptime_int = 11,
    field_null: @TypeOf(null) = null,

    field_opt_i32_value: ?i32 = 9,
    field_opt_i32_null: ?i32 = null,

    field_error: ErrorSet1 = error.Error1,
    field_error_union_error: anyerror!u8 = error.Error2,
    field_error_union_value: ErrorSet1!u8 = 5,

    field_enum_1: EnumSet1 = .Enum1,
    field_enum_2: EnumSet2 = .Enum3,

    field_fn_ptr: *const fn () void = myFunc,
    field_fn: fn () void = myFunc,
};

const Struct2 = struct {
    field_s3: Struct3 = .{},
    field_slice_s3: []const Struct3 = &.{ .{}, .{} },
};

const Struct3 = struct {
    field_i32: i32 = 33,
};

const ErrorSet1 = error{
    Error1,
    Error2,
};

const EnumSet1 = enum {
    Enum1,
    Enum2,
};

const EnumSet2 = enum(i32) {
    Enum3 = -999,
    Enum4 = 999,
};

pub fn main() !void {
    var w = std.io.getStdOut().writer();
    var tree_printer = TreePrinter.init(std.heap.page_allocator);

    const struct1 = Struct1{};
    try tree_printer.printValueWithId(w, struct1, "struct1");
}

const MyErrors = error{
    A,
    B,
};

inline fn isComptime(val: anytype) bool {
    return @typeInfo(@TypeOf(.{val})).Struct.fields[0].is_comptime;
}

fn myFunc() void {}

// TODO: recursive pointers
// TODO: limit items in array
// TODO: type printing

