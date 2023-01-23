const std = @import("std");

fn inspect(arg: anytype, comptime _: []const u8) !void {
    switch (@typeInfo(@TypeOf(arg))) {
        .Struct => |s| {
            inline for (s.fields) |field| {
                try inspect(@field(arg, field.name), "");
            }
        },
        .Pointer => |p| {
            @compileLog(p);
            // try inspect(arg.*, "");
        },
        .Optional => |_| {
            if (arg) |value| {
                try inspect(value, "");
            } else {
                std.debug.print("value is null", .{});
            }
        },
        else => {},
    }
}

const MyStruct = struct {
    linked_node: ?LinkedNode = null,
};

const LinkedNode = struct {
    next: ?*LinkedNode = null,
};

pub fn main() !void {
    const my_struct: MyStruct = .{};
    inspect(my_struct.linked_node, "") catch unreachable;
}
