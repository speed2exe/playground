const std = @import("std");

pub fn queue(comptime f: anytype, args: anytype) returnType(f) {
    return @call(.auto, f, args);
}

fn returnType(comptime f: anytype) type {
    return @typeInfo(@TypeOf(f)).Fn.return_type.?;
}

fn paramTupleType(comptime f: anytype) type {
    std.builtin.Type;
    return @typeInfo(@TypeOf(f)).Fn.return_type.?;
}

var threads: []std.Thread = &[_]std.Thread.spawn{};

pub fn init(allocator: std.mem.Allocator) !void {
    _ = allocator;
    std.log.info("len of threads: {d}", .{threads.len});

    // std.Thread.Pool.init
    // std.Thread.spawn
}

pub fn main() !void {
    try init();

    var result = queue(add, .{ 1, 2 });
    std.log.info("result: {}", .{result});
}

fn add(a: i32, b: i32) i32 {
    return a + b;
}
