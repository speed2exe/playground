const std = @import("std");
const expectEqual = std.testing.expectEqual;
const test_allocator = std.testing.allocator;
const best = @import("./best.zig");
const multi_slice = @import("./multi_slice.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const leaked = gpa.deinit();
        if (leaked) {
            std.log.err("got leaked!", .{});
        }
    }

    var data = [_]u8{ 86, 53, 13, 36, 8, 64, 65, 1, 90, 14, 25, 79, 70, 98, 54, 55, 6, 17, 12, 77, 46, 49, 82, 58, 26, 89, 48, 83, 27, 42, 80, 97, 52, 39, 76, 22, 85, 9, 29, 11, 2, 20, 66, 87, 40, 50, 35, 15, 92, 74, 78, 67, 28, 63, 68, 62, 23, 94, 75, 96, 69, 88, 99, 44, 16, 91, 72, 33, 84, 45, 34, 51, 32, 37, 7, 47, 31, 57, 93, 21, 19, 10, 4, 81, 3, 71, 18, 56, 60, 24, 100, 41, 95, 73, 38, 30, 61, 59, 43, 5 };

    const now = std.time.nanoTimestamp();
    defer {
        const then = std.time.nanoTimestamp();
        std.log.warn("quicksort nano sec: {d}", .{then - now});
    }

    try radixSort(u8, u8Key, &data, allocator);

    // for (data) |d| {
    //     std.debug.print("{d},", .{d});
    // }
}

test "radix sort 100 elem rand order" {
    var data = [_]u8{ 86, 53, 13, 36, 8, 64, 65, 1, 90, 14, 25, 79, 70, 98, 54, 55, 6, 17, 12, 77, 46, 49, 82, 58, 26, 89, 48, 83, 27, 42, 80, 97, 52, 39, 76, 22, 85, 9, 29, 11, 2, 20, 66, 87, 40, 50, 35, 15, 92, 74, 78, 67, 28, 63, 68, 62, 23, 94, 75, 96, 69, 88, 99, 44, 16, 91, 72, 33, 84, 45, 34, 51, 32, 37, 7, 47, 31, 57, 93, 21, 19, 10, 4, 81, 3, 71, 18, 56, 60, 24, 100, 41, 95, 73, 38, 30, 61, 59, 43, 5 };

    try radixSort(u8, u8Key, &data, test_allocator, 8);

    for (data) |d, i| {
        try expectEqual(i + 1, d);
    }
}

test "radix benchmark 2000,000" {
    var random = std.rand.Isaac64.init(0).random();
    var data: [8000_000]u8 = undefined;
    for (data) |*value| {
        value.* = random.int(u8);
    }

    const now = std.time.milliTimestamp();
    defer {
        const then = std.time.milliTimestamp();
        std.log.warn("std.sort milli sec: {d}", .{then - now});
    }

    try radixSort(u8, u8Key, &data, test_allocator, 8);
}

test "std.sort benchmark 2000,000" {
    var random = std.rand.Isaac64.init(0).random();
    var data: [8000_000]u8 = undefined;
    for (data) |*value| {
        value.* = random.int(u8);
    }

    const now = std.time.milliTimestamp();
    defer {
        const then = std.time.milliTimestamp();
        std.log.warn("std.sort milli sec: {d}", .{then - now});
    }

    std.sort.sort(u8, &data, @as(u8, 0), u8LessWithContex);
}

fn u8LessWithContex(c: u8, a: u8, b: u8) bool {
    _ = c;
    return a < b;
}

pub fn u8Key(a: u8) usize {
    return @as(usize, a);
}

pub fn usizeKey(a: usize) usize {
    return a;
}

pub fn radixSort(
    comptime T: type,
    keyFromElem: fn (T) usize,
    elems: []T,
    allocator: std.mem.Allocator,
    buckets_size: usize,
) !void {
    if (elems.len == 0) {
        return;
    }

    // TODO: improve allocation

    var radix_elems = try allocator.alloc(RadixElem(T), elems.len);
    defer allocator.free(radix_elems);
    for (elems) |elem, i| {
        radix_elems[i] = RadixElem(T){
            .index = i,
            .elem = elem,
            .key = keyFromElem(elem),
        };
    }

    // lock in answer after computation
    defer {
        for (radix_elems) |radix_elem, index| {
            elems[index] = radix_elem.elem;
        }
    }

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

    var mask: usize = buckets_size;
    while (biggest_key > 0) : (biggest_key /= buckets_size) {
        // initialize all len to 0
        for (buckets_elem_len) |*len| {
            len.* = 0;
        }

        for (radix_elems) |*radix_elem| {
            // find bucket_index
            const bucket_index: usize = radix_elem.key % mask;
            radix_elem.key /= mask;

            var chosen_bucket = buckets.getNthSlice(bucket_index);
            const elem_index = buckets_elem_len[bucket_index];
            chosen_bucket[elem_index] = radix_elem.*;
            buckets_elem_len[bucket_index] += 1;
        }

        // put all the elems from buckets back to radix_elems
        {
            var index: usize = 0;
            var buckets_iterator = buckets.getIterator();
            var bucket_index: usize = 0;
            while (buckets_iterator.next()) |bucket| : (bucket_index += 1) {
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

fn higherKey(comptime T: type) fn (RadixElem(T), RadixElem(T)) bool {
    return struct {
        fn function(a: RadixElem(T), b: RadixElem(T)) bool {
            return a.key > b.key;
        }
    }.function;
}
