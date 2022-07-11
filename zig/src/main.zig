const std = @import("std");
const log = std.log;
const assert = @import("assert");

// The Road to Zig 1.0

// Example 1
const buffer_len = 666;
var buffer: [buffer_len]u8 = undefined;

test "Example 1" {
    buffer[42] = 69;
}

// Example 2
fn getBufferLn() usize {
    buffer[42] = 69;
    return 666;
}
var buffer2: [getBufferLn()]u8 = undefined;

test "Example 2" {
    buffer[42] = 69;
}

// Example 3
fn fibonacci(x: u32) u32 {
    if (x <= 1) return x;
    return fibonacci(x - 1) + fibonacci(x - 2);
}

test "Example 3" {
    const x = fibonacci(7);
    log.warn("result is {d}", .{x});
}

test "Example 4" {
    const x = comptime fibonacci(7);
    warn("result is {d}", .{x});
    const array1: [x]u8 = undefined;

    log.warn("aleeaeak {d}", result[0]);
    //log.warn("array.len = {}", array.len);
}

pub fn main() anyerror!void {
    // integer
    var one_million: i32 = 1_000_000;
    one_million = one_million;

    // does not work, cannot shadow
    // var one_million = "lol";

    //float
    // const pi: f32 = 3.14159;

    // string
    const hello: []const u8 = "Hello, world!";
    _ = try print(hello);
}

fn print(s: []const u8) anyerror!void {
    _ = try std.io.getStdOut().write(s);
}

fn warnMy(s: []const u8) void {
    log.warn(s, .{});
}
