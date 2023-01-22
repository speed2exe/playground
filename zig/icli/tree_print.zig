const std = @import("std");
const builtin = std.builtin;
const log = std.log;

const ansi_esc_code = @import("./ansi_esc_code.zig");
const Color = ansi_esc_code.Color;
const comptimeFmtInColor = ansi_esc_code.comptimeFmtInColor;
const comptimeInColor = ansi_esc_code.comptimeInColor;

const arrow = comptimeFmtInColor(Color.bright_black, "=>", .{});

pub const TreePrinter = struct {
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
        const type_info = @typeInfo(arg_type);
        const type_name = @typeName(arg_type);
        const type_name_colored = comptimeInColor(Color.cyan, type_name);
        const id_colored = comptimeInColor(Color.yellow, id);

        switch (type_info) {
            .Struct => |s| {
                try writer.print("{s} {s}", .{ id_colored, type_name_colored });
                const backup_len = prefix.items.len;
                const field_count = s.fields.len;
                if (field_count == 0) return;
                const last_field_idx = field_count - 1;
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
            },
            .Array => |a| {
                try writer.print("{s} {s}", .{ id_colored, type_name_colored });
                if (arg.len == 0) return;
                if (a.child == u8 and self.print_u8_chars) try writer.print(" {s} {s}", .{ arrow, arg });
                try self.printArrayValues(prefix, writer, arg);
            },
            .Pointer => |p| {
                const address_fmt = comptime comptimeFmtInColor(Color.blue, "@{{x}}", .{});
                switch (p.size) {
                    .One => {
                        try writer.print("{s} {s} " ++ address_fmt, .{ id_colored, type_name_colored, @ptrToInt(arg) });

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
                        try writer.print("{s} {s} " ++ address_fmt, .{ id_colored, type_name_colored, @ptrToInt(arg.ptr)});
                        if (arg.len == 0) return;
                        if (p.child == u8 and self.print_u8_chars) try writer.print(" \"{s}\"", .{arg});
                        // try self.printSliceValues(prefix, writer, arg);
                    },
                    else => {
                        try writer.print("{s} {s} " ++ address_fmt, .{ id_colored, type_name_colored, @ptrToInt(arg) });
                    },
                }
            },
            .Optional => {
                const value = arg orelse {
                    try writer.print("{s} {s} {s} null", .{ id_colored, type_name_colored, arrow });
                    return;
                };
                try writer.print("{s} {s} \n{s}└─", .{ id_colored, type_name_colored, prefix.items });
                try self.printValueImpl(prefix, writer, value, ".?");
            },
            .ErrorUnion => {
                // TODO:
            },
            else => {
                try writer.print("{s} {s} {s} {any}", .{ id_colored, type_name_colored, arrow, arg });
            },
        }
    }

    fn printArrayValues(self: TreePrinter, prefix: *std.ArrayList(u8), writer: anytype, arg: anytype) !void {
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

    fn printSliceValues(self: TreePrinter, prefix: *std.ArrayList(u8), writer: anytype, arg: anytype) !void {
        const index_fmt = comptime comptimeFmtInColor(Color.yellow, "[{{d}}]", .{});
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
};

const Person = struct {
    o_i: ?i32 = 9,
    // o_j: ?i32 = null,
    // v: void = undefined,
    // b: bool = true,
    // f: f32 = 3.14,
    // age: u8 = 34,
    name: []const u8 = "jon",
    // cc: CreditCard = .{},
    code: [3]u8 = [_]u8{ 1, 2, 3 },
    // k: type = u16,
    // int_ptr: *const u8,
    f: *const fn () void = myFunc,
};

const CreditCard = struct {
    const whatever: u8 = 251;

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

const aa: u32 = 8;
const Debt3 = struct {
    id: *const u32 = &aa,
};

const Debt4 = struct {
    const whatever: u8 = 251;
    const whatever2: u8 = 252;
    id: u32 = 0,
};

pub fn main() !void {
    var w = std.io.getStdOut().writer();
    var tree_printer = TreePrinter.init(std.heap.page_allocator);

    // var int: u8 = 7;
    // std.fmt.format
    // const person = Person{
    //     .int_ptr = &int,
    // };
    // std.log.info("person comptime? {}", .{isComptime(person)});
    // try treePrint(std.heap.page_allocator, w, person, "\nperson");

    // const d1 = Debt{};
    // std.log.info("debt comptime? {}", .{isComptime(d1)});
    // try treePrint(std.heap.page_allocator, w, d1, "d1");

    // const cc = CreditCard{
    //     .name = "john",
    //     .number = 999,
    //     .number2 = 999,
    //     .debt = Debt{
    //         .id = 0,
    //         .amount = 888,
    //     },
    // };
    // std.log.info("cc comptime? {}", .{isComptime(cc)});
    // try treePrint(std.heap.page_allocator, w, cc, "\ncc");

    // const person1 = Person{
    //     .age = 20,
    //     .name = "John",
    //     .int_ptr = &int,
    // };

    // comptime var i: u32 = 0;
    // var d2 = Debt2{
    //     .id = &i,
    // };
    // std.log.info("debt2 comptime? {}", .{isComptime(d2)});
    // try treePrint(std.heap.page_allocator, w, d2, "d2");

    // const d3 = Debt3{};
    // std.log.info("debt3 comptime? {}", .{isComptime(d3)});
    // try treePrint(std.heap.page_allocator, w, d3, "d3");

    // const debt4 = Debt4{};
    // std.log.info("debt4 comptime? {}", .{isComptime(debt4)});
    // try tree_printer.printValueWithId(w, debt4, "debt4");

    // const p1 = Person{};
    // std.log.info("p1 comptime? {}", .{isComptime(p1)});
    // try tree_printer.printValueWithId(w, p1, "p1");

    // const S2 = struct {
    //     b: []const u8 = "s2 default",
    //     // f: fn () void = myFunc,
    // };
    // _ = S2;
    // const S = struct {
    //     a: []const u8 = "",
    //     // b: *const S2 = &S2{},
    //     // e: MyErrors = MyErrors.A,
    // };

    // const s = S{};
    // _ = s;
    // std.log.info("s is comptime known? {}", .{isComptime(s)});
    // try tree_printer.printValueWithId(w, s, "s");
    try tree_printer.printValue(w, MyErrors.A);
    std.debug.print("{any}", .{18});
    // _ = w;
    // _ = tree_printer;
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
