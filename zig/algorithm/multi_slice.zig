const std = @import("std");
const expectEqual = std.testing.expectEqual;

// Represents Slice of slices from a slice
// Initialize with a total number of parts or max_size per part
// if elems.len is not a multiple of num_parts or if elems.len is not a
// multiple of max_size, the excess will be "chopped off"
// e.g. elems: [1,2,3,4,5,6,7], num_parts: 2
//   => [1,2,3], [4,5,6]
// e.g. elems: [1,2,3,4,5,6,7], max_size: 2
//   => [1,2], [4,5], [5,6]
fn MultiSlice(comptime T: type) type {
    return struct {
        const Self = @This();

        elems: []T,
        num_parts: usize,
        max_size: usize,

        pub fn initNumParts(elems: []T, num_parts: usize) Self {
            return Self {
                .elems = elems,
                .max_size = elems.len / num_parts,
                .num_parts = num_parts,
            };
        }

        pub fn initMaxSize(elems: []T, max_size: usize) Self {
            return Self {
                .elems = elems,
                .max_size = max_size,
                .num_parts = elems.len / max_size,
            };
        }

        pub fn getNthSlice(self: Self, n: usize) []T {
            const start = (n * self.max_size);
            const end = ((n + 1) * self.max_size);
            return self.elems[start..end];
        }

        pub fn getRemainder(self: Self) []T {
            return self.elems[(self.max_size * self.num_parts)..];
        }

    };
}

test "test MultiSlice initNumParts" {
    var elems = [_]u8{1,2,3,4,5,6,7};
    var elemss = MultiSlice(u8).initNumParts(&elems, 2);
    var part1 = elemss.getNthSlice(0);
    try expectEqual(@as([]u8, elems[0..3]), part1);

    var part2 = elemss.getNthSlice(1);
    try expectEqual(@as([]u8, elems[3..6]), part2);

    var part3 = elemss.getRemainder();
    try expectEqual(@as([]u8, elems[6..]), part3);
}

test "test MultiSlice initMaxSize" {
    var elems = [_]u8{1,2,3,4,5,6,7};
    var elemss = MultiSlice(u8).initMaxSize(&elems, 3);
    var part1 = elemss.getNthSlice(0);
    try expectEqual(@as([]u8, elems[0..3]), part1);

    var part2 = elemss.getNthSlice(1);
    try expectEqual(@as([]u8, elems[3..6]), part2);

    var part3 = elemss.getRemainder();
    try expectEqual(@as([]u8, elems[6..]), part3);
}
