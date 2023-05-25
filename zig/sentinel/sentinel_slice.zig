const std = @import("std");

pub fn main() !void {
    const word = zeroSentinel();
    std.log.info("word: {any}", .{word});
    std.log.info("word[0]: {any}", .{word[0]});
    std.log.info("word type: {any}", .{@TypeOf(word)});
}

pub fn zeroSentinel() [:0]const u8 {
    return &[_:0]u8{};
}
