const std = @import("std");

pub fn main () !void {
    // testing futex
    // var a = std.atomic.Atomic(u32).init(0);
    // try std.Thread.Futex.wait(&a, 0, 5_000_000_000);

    var a: ?u32 = 8;
    
    if (a) |b| {
        std.debug.print("a is not null: {}",.{b});
    } else {
        std.debug.print("a is null",.{});
    }


}
