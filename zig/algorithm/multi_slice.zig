const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

// Represents Slice of slices from a slice
// Initialize with a total number of parts or max_size per part
// if elems.len is not a multiple of num_parts or if elems.len is not a
// multiple of max_size, the excess will be "chopped off"
// e.g. elems: [1,2,3,4,5,6,7], num_parts: 2
//   => [1,2,3], [4,5,6]
// e.g. elems: [1,2,3,4,5,6,7], max_size: 2
//   => [1,2], [4,5], [5,6]
pub fn MultiSlice(comptime T: type) type {
    return struct {
        const Self = @This();

        elems: []T,
        len: usize,
        slice_size: usize,

        pub fn initNumParts(elems: []T, num_parts: usize) Self {
            return Self {
                .elems = elems,
                .slice_size = elems.len / num_parts,
                .len = num_parts,
            };
        }

        pub fn initMaxSize(elems: []T, max_size: usize) Self {
            return Self {
                .elems = elems,
                .slice_size = max_size,
                .len = elems.len / max_size,
            };
        }

        pub fn getNthSlice(self: Self, n: usize) []T {
            const start = (n * self.slice_size);
            const end = ((n + 1) * self.slice_size);
            return self.elems[start..end];
        }

        pub fn getRemainder(self: Self) []T {
            return self.elems[(self.slice_size * self.len)..];
        }

        pub fn getIterator(self: Self) MultiSliceIterator(T) {
            return MultiSliceIterator(T).init(self);
        }

    };
}

fn MultiSliceIterator(comptime T: type) type {
    return struct {
        const Self = @This();

        multi_slice: MultiSlice(T),
        consumed: usize = 0,

        fn init(multi_slice: MultiSlice(T)) Self {
            return Self {
                .multi_slice = multi_slice,
            };
        }

        fn next(self: *Self) ?[]T {
            if (self.consumed == self.multi_slice.len) {
                return null;
            }
            const result = self.multi_slice.getNthSlice(self.consumed);
            self.consumed += 1;
            return result;
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

test "test MultiSlice iterator" {
    var elems = [_]u8{1,2,3,4,5,6,7};
    var elemss = MultiSlice(u8).initNumParts(&elems, 2);
    var elemss_iterator = elemss.getIterator();
    
    var part1 = elemss_iterator.next() orelse unreachable;
    try expectEqual(@as([]u8, elems[0..3]), part1);

    var part2 = elemss_iterator.next() orelse unreachable;
    try expectEqual(@as([]u8, elems[3..6]), part2);

    var part3 = elemss_iterator.next();
    try expect(part3 == null);
}
