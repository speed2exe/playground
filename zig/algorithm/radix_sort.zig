const std = @import("std");
const best = @import("./best.zig");

// base2
pub fn radixSort (
    comptime T: type,
    keyFromValue: fn (a: T, b: T) usize,
    elems: []T,
    allocator: std.mem.Allocator,
) !void {
    if (elems.len == 0) {
        return;
    }

    var keys = try allocator.alloc(usize, data.len);
    defer allocator.free(keys);
    for (elems) |elem, i| {
        keys[i] = elem;
    }

    // assume bucket size is 2;
    var buckets = try allocator.alloc(?T, data.len*2);

    // find largest bit len, TODO: check if need
    var biggest_key = best.best(T, higherUsize ,keys) orelse unreachable;
    var mask: usize = 0b1;
    while (biggest_key > 0): ({
        biggest_key >>= 1;
        mask <<= 1;
    }) {
        for (keys) |key| {
            // can consider (key % buckets.len) if using variable len
            if (key & mask == 0) {
                buckets =
            }
        }
    }

}

fn higherUsize(a: usize, b: usize) bool {
    return a > b;
}
