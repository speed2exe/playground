const std = @import("std");
const builtin = std.builtin;

const ansi_esc_code = @import("./ansi_esc_code.zig");
const Color = ansi_esc_code.Color;
const comptimeFmtInColor = ansi_esc_code.comptimeFmtInColor;
const comptimeInColor = ansi_esc_code.comptimeInColor;

const arrow = comptimeFmtInColor(Color.bright_black, "=>", .{});
const empty = " " ++ arrow ++ " {}";

pub const TreePrinter = struct {
    const address_fmt = comptimeInColor(Color.blue, "@{x}");

    // key: pointer address, value: number of repeats
    const CountsByAddress = std.AutoHashMap(usize, usize);

    /// settings
    array_print_limit: usize = 10, // affects Arrays, Slice, Vector, minimum 1
    print_u8_chars: bool = true,
    ptr_recursive_limit: usize = 10,

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
        var counts_by_address = CountsByAddress.init(self.allocator);
        try writer.print(comptimeInColor(Color.yellow, id), .{});
        try self.printValueImpl(&prefix, &counts_by_address, writer, arg);
        try writer.print("\n", .{});
    }

    fn printValueImpl(
        self: TreePrinter,
        prefix: *std.ArrayList(u8),
        counts_by_address: *CountsByAddress,
        writer: anytype,
        arg: anytype,
    ) !void {
        const arg_type = @TypeOf(arg);
        try writer.print("{s}{s}", .{
            comptimeInColor(Color.bright_black, ": "),
            comptimeInColor(Color.cyan, @typeName(arg_type)),
        });

        switch (@typeInfo(arg_type)) {
            .Struct => |s| {
                if (s.fields.len == 0) {
                    try writer.writeAll(empty);
                    return;
                }
                try self.printFieldValues(prefix, counts_by_address, writer, arg, s);
            },
            .Array => |a| {
                if (a.child == u8 and self.print_u8_chars) try writer.print(" {s}", .{arg});
                if (a.len == 0) {
                    try writer.writeAll(empty);
                    return;
                }

                try self.printArrayValues(prefix, counts_by_address, writer, arg, a);
            },
            .Vector => |v| {
                if (v.child == u8 and self.print_u8_chars) try writer.print(" {s}", .{arg});
                if (v.len == 0) {
                    try writer.writeAll(empty);
                    return;
                }

                try self.printVectorValues(prefix, counts_by_address, writer, arg, v);
            },
            .Pointer => |p| {
                switch (p.size) {
                    .One => {
                        const addr: usize = @ptrToInt(arg);
                        try writer.print(" " ++ address_fmt, .{addr});

                        // TODO: verify
                        if (counts_by_address.getPtr(addr)) |counts_ptr| {
                            if (counts_ptr.* >= self.ptr_recursive_limit) {
                                try writer.print("...(Repeated)", .{});
                                return;
                            }
                            counts_ptr.* += 1;
                        } else {
                            try counts_by_address.put(addr, 1);
                        }

                        // TODO: segment ignores unprintable values, verification is needed
                        if (addr == 0) return;
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

                        try writer.print("\n{s}└─" ++ comptimeInColor(Color.yellow, ".*"), .{prefix.items});
                        const backup_len = prefix.items.len;
                        try prefix.appendSlice("  ");
                        try self.printValueImpl(prefix, counts_by_address, writer, arg.*);
                        prefix.shrinkRetainingCapacity(backup_len);
                    },
                    .Slice => {
                        try writer.print(" " ++ address_fmt, .{@ptrToInt(arg.ptr)});
                        if (p.child == u8 and self.print_u8_chars) try writer.print(" \"{s}\"", .{arg});
                        if (arg.len == 0) return;
                        try self.printSliceValues(prefix, counts_by_address, writer, arg);
                    },
                    else => {
                        try writer.print(" {s} {any}", .{ arrow, arg });
                    },
                }
            },
            .Optional => {
                // TODO: compilation issues
                if (arg) |value| {
                    try writer.print(" \n{s}└─" ++ comptimeInColor(Color.yellow, ".?"), .{prefix.items});
                    try self.printValueImpl(prefix, counts_by_address, writer, value);
                } else {
                    try writer.print(" {s} null", .{arrow});
                }
            },
            .Union => |u| {
                if (u.fields.len == 0) {
                    try writer.writeAll(empty);
                    return;
                }
                if (u.tag_type) |_| {
                    try self.printFieldValueAtIndex(prefix, counts_by_address, writer, arg, u, @enumToInt(arg));
                } else {
                    try self.printFieldValues(prefix, counts_by_address, writer, arg, u);
                }
            },
            .Enum => try writer.print(" {s} {} ({d})", .{ arrow, arg, @enumToInt(arg) }),
            .Fn => try writer.print(" " ++ address_fmt, .{@ptrToInt(&arg)}),
            else => try writer.print(" {s} {any}", .{ arrow, arg }),
        }
    }

    inline fn printArrayValues(
        self: TreePrinter,
        prefix: *std.ArrayList(u8),
        counts_by_address: *CountsByAddress,
        writer: anytype,
        arg: anytype,
        arg_type: anytype,
    ) !void {
        const backup_len = prefix.items.len;
        inline for (arg[0 .. arg_type.len - 1]) |item, i| {
            if (i == self.array_print_limit - 1) {
                try writer.print("\n{s}...{d} item(s) not shown", .{ prefix.items, arg.len - self.array_print_limit });
                break;
            }
            const index_colored = comptime comptimeFmtInColor(Color.yellow, "[{d}]", .{i});
            try writer.print("\n{s}├─" ++ index_colored, .{prefix.items});
            try prefix.appendSlice("│ ");
            try self.printValueImpl(prefix, counts_by_address, writer, item);
            prefix.shrinkRetainingCapacity(backup_len);
        }
        const index_colored = comptime comptimeFmtInColor(Color.yellow, "[{d}]", .{arg.len - 1});
        try writer.print("\n{s}└─" ++ index_colored, .{prefix.items});
        try prefix.appendSlice("  ");
        try self.printValueImpl(prefix, counts_by_address, writer, arg[arg_type.len - 1]);
    }

    inline fn printVectorValues(
        self: TreePrinter,
        prefix: *std.ArrayList(u8),
        counts_by_address: *CountsByAddress,
        writer: anytype,
        arg: anytype,
        arg_type: anytype,
    ) !void {
        const index_fmt = comptime comptimeInColor(Color.yellow, "[{d}]");
        const backup_len = prefix.items.len;
        var i: usize = 0;
        while (i < arg_type.len - 1) : (i += 1) {
            if (i == self.array_print_limit - 1) {
                try writer.print("\n{s}...{d} item(s) not shown", .{ prefix.items, arg_type.len - self.array_print_limit });
                break;
            }
            const item = arg[i];
            try writer.print("\n{s}├─" ++ index_fmt, .{ prefix.items, i });
            try prefix.appendSlice("│ ");
            try self.printValueImpl(prefix, counts_by_address, writer, item);
            prefix.shrinkRetainingCapacity(backup_len);
        }
        try writer.print("\n{s}└─" ++ index_fmt, .{ prefix.items, i });
        try prefix.appendSlice("  ");
        try self.printValueImpl(prefix, counts_by_address, writer, arg[arg_type.len - 1]);
    }

    inline fn printSliceValues(
        self: TreePrinter,
        prefix: *std.ArrayList(u8),
        counts_by_address: *CountsByAddress,
        writer: anytype,
        arg: anytype,
    ) !void {
        const index_fmt = comptime comptimeInColor(Color.yellow, "[{d}]");
        const backup_len = prefix.items.len;
        for (arg[0 .. arg.len - 1]) |item, i| {
            if (i == self.array_print_limit - 1) {
                try writer.print("\n{s}...{d} item(s) not shown", .{ prefix.items, arg.len - self.array_print_limit });
                break;
            }
            try writer.print("\n{s}├─" ++ index_fmt, .{ prefix.items, i });
            try prefix.appendSlice("│ ");
            try self.printValueImpl(prefix, counts_by_address, writer, item);
            prefix.shrinkRetainingCapacity(backup_len);
        }
        try writer.print("\n{s}└─" ++ index_fmt, .{ prefix.items, arg.len - 1 });
        try prefix.appendSlice("  ");
        try self.printValueImpl(prefix, counts_by_address, writer, arg[arg.len - 1]);
    }

    inline fn printFieldValues(
        self: TreePrinter,
        prefix: *std.ArrayList(u8),
        counts_by_address: *CountsByAddress,
        writer: anytype,
        arg: anytype,
        comptime arg_type: anytype,
    ) !void {
        // Note:
        // This is set so that unions can be printed for all its values
        // This can be removed if we are able to determine the active union
        // field during ReleaseSafe and Debug builds,
        @setRuntimeSafety(false);

        const backup_len = prefix.items.len;
        const last_field_idx = arg_type.fields.len - 1;
        inline for (arg_type.fields[0..last_field_idx]) |field| {
            try writer.print("\n{s}├─" ++ comptimeInColor(Color.yellow, "." ++ field.name), .{prefix.items});
            try prefix.appendSlice("│ ");
            try self.printValueImpl(prefix, counts_by_address, writer, @field(arg, field.name));
            prefix.shrinkRetainingCapacity(backup_len);
        }
        const last_field_name = arg_type.fields[last_field_idx].name;
        try writer.print("\n{s}└─" ++ comptimeInColor(Color.yellow, "." ++ last_field_name), .{prefix.items});
        try prefix.appendSlice("  ");
        try self.printValueImpl(prefix, counts_by_address, writer, @field(arg, last_field_name));
        prefix.shrinkRetainingCapacity(backup_len);
    }

    inline fn printFieldValueAtIndex(
        self: TreePrinter,
        prefix: *std.ArrayList(u8),
        counts_by_address: *CountsByAddress,
        writer: anytype,
        arg: anytype,
        arg_type: anytype,
        idx: usize,
    ) !void {
        const backup_len = prefix.items.len;
        inline for (arg_type.fields) |field, i| {
            if (i == idx) {
                try writer.print("\n{s}└─" ++ comptimeInColor(Color.yellow, "." ++ field.name), .{prefix.items});
                try prefix.appendSlice("  ");
                try self.printValueImpl(prefix, counts_by_address, writer, @field(arg, field.name));
                prefix.shrinkRetainingCapacity(backup_len);
                return;
            }
        }
    }
};

var i32_value: i32 = 42;

const Struct1 = struct {
    // valid in comptime
    // k: type = u16,
    // field_comptime_float: comptime_float = 3.14,
    // field_comptime_int: comptime_int = 11,
    // field_fn: fn () void = functionOne,

    field_void: void = undefined,
    field_bool: bool = true,
    field_u8: u32 = 11,
    field_float: f32 = 3.14,

    field_i32_ptr: *i32 = &i32_value,
    field_slice_u8: []const u8 = "s1 string",

    field_array_u8: [3]u8 = [_]u8{ 1, 2, 3 },
    field_array_u8_empty: [0]u8 = .{},

    field_struct2: Struct2 = .{},
    field_struct4: Struct4 = .{},

    // TODO: not working, need to fix
    // field_struct_recursive: LinkedNode,

    field_null: @TypeOf(null) = null,

    field_opt_i32_value: ?i32 = 9,
    field_opt_i32_null: ?i32 = null,

    field_error: ErrorSet1 = error.Error1,
    field_error_union_error: anyerror!u8 = error.Error2,
    field_error_union_value: ErrorSet1!u8 = 5,

    field_enum_1: EnumSet1 = .Enum1,
    field_enum_2: EnumSet2 = .Enum3,

    field_union_1: Union1 = .{ .int = 98 },
    field_union_2: Union1 = .{ .float = 3.14 },
    field_union_3: Union1 = .{ .bool = true },

    field_tagged_union_1: TaggedUnion1 = .{ .int = 98 },
    field_tagged_union_2: TaggedUnion1 = .{ .float = 3.14 },
    field_tagged_union_3: TaggedUnion1 = .{ .bool = true },

    field_fn_ptr: *const fn () void = functionOne,
    field_vector: @Vector(4, i32) = .{ 1, 2, 3, 4 },

    // TODO: support Frame and AnyFrame
    // field_anyframe: anyframe = undefined,
};

const Struct2 = struct {
    field_s3: Struct3 = .{},
    field_slice_s3: []const Struct3 = &.{ .{}, .{} },
};

const Struct3 = struct {
    field_i32: i32 = 33,
};

const Struct4 = struct {};

const LinkedNode = struct {
    val: i32,
    next: *LinkedNode = undefined,
};

const LinkedNode2 = struct {};

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

const Union1 = union {
    int: i32,
    float: f32,
    bool: bool,
};

const TaggedUnion1 = union(enum) {
    int: i32,
    float: f32,
    bool: bool,
};

fn functionOne() void {}

pub fn main() !void {
    var w = std.io.getStdOut().writer();
    var tree_printer = TreePrinter.init(std.heap.page_allocator);

    // var node1: LinkedNode = .{};
    // var node2: LinkedNode = .{.next = &node1};
    // node1.next = &node2;
    // var n1 = LinkedNode{ .val = 1 };
    // var n2 = LinkedNode{ .val = 2 };
    // n1.next = &n2;
    // n2.next = &n1;

    // std.log.info("{}", .{linked_node});
    // try tree_printer.printValueWithId(w, n1, "linked_node");

    var struct1: Struct1 = .{};
    try tree_printer.printValueWithId(w, struct1, "struct1");

    try tree_printer.printValueWithId(w, .{ 1, 2, 3 }, "anon");
}

inline fn isComptime(val: anytype) bool {
    return @typeInfo(@TypeOf(.{val})).Struct.fields[0].is_comptime;
}

// TODO: tuple in structs
