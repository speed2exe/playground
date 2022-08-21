const std = @import("std");
const best = @import("./best.zig");
const multi_slice = @import("./multi_slice.zig");

pub fn main() void {    
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const leaked = gpa.deinit();
        if (leaked) {
            std.log.err("got leaked!",.{});
        }
    }
    
    var data = [_]u8 {
        86, 53, 13, 36, 8, 64, 65, 1, 90, 14, 25, 79, 70, 98, 54, 55, 6, 17,
        12, 77, 46, 49, 82, 58, 26, 89, 48, 83, 27, 42, 80, 97, 52, 39, 76, 22,
        85, 9, 29, 11, 2, 20, 66, 87, 40, 50, 35, 15, 92, 74, 78, 67, 28, 63,
        68, 62, 23, 94, 75, 96, 69, 88, 99, 44, 16, 91, 72, 33, 84, 45, 34, 51,
        32, 37, 7, 47, 31, 57, 93, 21, 19, 10, 4, 81, 3, 71, 18, 56, 60, 24,
        100, 41, 95, 73, 38, 30, 61, 59, 43, 5
    };

    // const now = std.time.nanoTimestamp();
    // defer {
    //     const then = std.time.nanoTimestamp();
    //     std.log.warn("quicksort nano sec: {d}",.{then - now});
    // }

    try radixSort(u8, u8Key, &data, allocator);

    for (data) |d| {
        std.debug.print("{d}\n", .{d});
    }
}

pub fn u8Key(a: u8) usize {
    return @as(usize, a);
}

// base2
pub fn radixSort (
    comptime T: type,
    keyFromElem: fn (T) usize,
    elems: []T,
    allocator: std.mem.Allocator,
) !void {
    if (elems.len == 0) {
        return;
    }

    // TODO: improve allocation

    var radix_elems = try allocator.alloc(RadixElem(T), elems.len);
    defer allocator.free(radix_elems);
    for (elems) |elem, i| {
        radix_elems[i] = RadixElem(T) {
            .index = i,
            .elem = elem,
            .key = keyFromElem(elem),
        };
    }

    // lock in answer after computation
    defer {
        for (radix_elems) |radix_elem| {
            elems[radix_elem.index] = radix_elem.elem;
        }
    }

    // assume bucket size is 2;
    const buckets_size = 2;
    var bucket_data = try allocator.alloc(RadixElem(T), elems.len * buckets_size);
    defer allocator.free(bucket_data);

    var buckets = blk: {
        break :blk multi_slice.MultiSlice(RadixElem(T)).initNumParts(bucket_data, buckets_size);
    };

    // stores the number of elems that is valid in buckets
    var buckets_elem_len = try allocator.alloc(usize, elems.len);
    defer allocator.free(buckets_elem_len);

    // find largest key
    var biggest_elem = best.best(RadixElem(T), higherKey(T), radix_elems) orelse unreachable;
    var biggest_key = biggest_elem.key;

    var mask: usize = 0b1;
    while (biggest_key > 0): ({
        biggest_key >>= 1;
        mask <<= 1;
    }) {
        // initialize all len to 0
        for (buckets_elem_len) |*len| {
            len.* = 0;
        }

        for (radix_elems) |radix_elem| {
            // find bucket_index
            // can consider (key % buckets.len) if using variable len
            const bucket_index: usize =
                if (radix_elem.key & mask == 0) 0
                else 1;

            var chosen_bucket = buckets.getNthSlice(bucket_index);
            const elem_index = buckets_elem_len[bucket_index];
            chosen_bucket[elem_index] = radix_elem;
            buckets_elem_len[bucket_index] += 1;
        }

        // put all the elems from buckets back to radix_elems
        {
            var index: usize = 0;
            while (true) {
                for (bucket[0..buckets_elem_len[bucket_index]]) |bucket_elem| {
                    radix_elems[index] = bucket_elem;
                    index += 1;
                }
            }
        }
    }
}

fn RadixElem(comptime T: type) type {
    return struct {
        index: usize,
        elem: T,
        key: usize,
    };
}


fn higherKey(comptime T: type) fn(RadixElem(T), RadixElem(T)) bool {
    return struct {
        fn function(a: RadixElem(T), b: RadixElem(T)) bool {
            return a.key > b.key;
        }
    }.function;
}
