const std = @import("std");

pub fn main() void {

    const r = std.rand.DefaultPrng.init(42).random();

    var i: usize = 0;
    while (1 < 10) : (i += 1) {
        const v = r.intRangeAtMost(u8, 18, 22);
        std.debug.print("v = {}\n", .{v});
    }
}
