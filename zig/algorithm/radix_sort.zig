const std = @import("std");
const best = @import("./best.zig");
const multi_slice = @import("./multi_slice.zig");

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
    var buckets = blk: {
        const buckets_size = 2;
        var bucket_data = try allocator.alloc(T, data.len*buckets_size);
        break :blk multi_slice.MultiSlice(T).initNumParts(buckets_size);
    };

    // find largest bit len, TODO: check if need
    var biggest_key = best.best(T, higherUsize ,keys) orelse unreachable;
    var mask: usize = 0b1;
    while (biggest_key > 0): ({
        biggest_key >>= 1;
        mask <<= 1;
    }) {
        // initialize all len to 0
        for (buckets_len) |*len| {
            len.* = 0;
        }

        for (keys) |key| {

            // find bucket_index
            // can consider (key % buckets.len) if using variable len
            const bucket_index = if (key & mask == 0) 0 else 1;

            const location = buckets_len * bucket_index + buckets_len[bucket_index];
            buckets[location] = key;
            buckets_len[bucket_index] += 1;
        }

        // put all the values back into the original array
        {
            var index = 0;
            for (buckets) |bucket| {

            }
        }
    }

}

fn higherUsize(a: usize, b: usize) bool {
    return a > b;
}
