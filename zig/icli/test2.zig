const std = @import("std");

const Struct1 = struct {
    field_struct_recursive: ?LinkedNode = null,
};

const LinkedNode = struct {
    next: ?*LinkedNode = null,
};

pub fn main() !void {
    var struct1: Struct1 = .{ .field_struct_recursive = null };

    const linked_node = @field(struct1, "field_struct_recursive");

    if (linked_node) |node| {
        std.log.info("{}", .{node});
    } else {
        std.log.info("field_struct_recursive is null", .{});
    }
}

fn hello(
    arg: anytype,
) !void {
    const arg_type = @TypeOf(arg);

    switch (@typeInfo(arg_type)) {
        .Struct => |s| {
            _ = s;
        },
        .Pointer => |p| {
            _ = p;
        },
        else => std.log.print(" {s} ", .{arg}),
    }
}
