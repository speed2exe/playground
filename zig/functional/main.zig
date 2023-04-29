const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const arr: [3]u8 = .{ 1, 2, 3 };
    foreach(arr, printu8);
    const arr2 = try map(u16, gpa.allocator(), arr, tou16);
    defer gpa.allocator().free(arr2);
    foreach(arr2, printu16);
}

pub fn printu8(elem: u8) void {
    std.debug.print("{any}", .{elem});
}

pub fn printu16(elem: u16) void {
    std.debug.print("{any}", .{elem});
}

pub fn tou16(elem: u8) u16 {
    return @as(u16, elem);
}

pub fn foreach(arr: anytype, f: anytype) void {
    for (arr) |elem| {
        f(elem);
    }
}

pub fn map(comptime DestType: type, allocator: std.mem.Allocator, arr: anytype, f: anytype) ![]DestType {
    var slice = try allocator.alloc(DestType, arr.len);
    errdefer allocator.free(slice);
    for (arr, 0..) |elem, i| {
        slice[i] = f(elem);
    }
    return slice;
}
