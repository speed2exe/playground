const std = @import("std");
const tree_print = @import("tree_print.zig");

pub fn main() !void {
    var a: []const u8 = "hello";
    var b: []const u8 = "world";

    var m = std.StringHashMap(u32).init(std.heap.page_allocator);
    defer m.deinit();

    var c: u32 = 87;
    var d: u32 = 12;


    try m.put(a, c);
    try m.put(b, d);


    try tree_print.treePrint(std.heap.page_allocator, std.io.getStdOut().writer(), m, "m");
}
