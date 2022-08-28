const std = @import("std");
const iterator = @import("./iterator.zig");
const quick_sort = @import("./quick_sort.zig");
const testing = std.testing;

pub fn Array(comptime T: type) type {
    return struct {
        const Self = @This();

        elems: []T,
        allocator: std.mem.Allocator,
        len: usize,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self {
                .elems = &[_]T{},
                .len = 0,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            if (self.elems.len == 0) {
                return;
            }
            self.allocator.free(self.elems);
        }

        pub fn append(self: *Self, elem: T) !void {
            self.len += 1;
            try self.ensureCapacity(self.len);
            self.elems[self.len - 1] = elem;
        }

        // TODO:
        // append slice
        // sort
        // forEach? allocation?
        // map? allocation?

        pub fn pop(self: *Self) ?T {
            if (self.len == 0) {
                return null;
            }
            self.len -= 1;
            return self.elems[self.len];
        }

        pub fn lastElem(self: Self) ?T {
            if (self.len == 0) {
                return null;
            }
            return self.elems[self.len - 1];
        }

        pub fn removeAtIndex(self: *Self, index: usize) !void {
            self.elems[index] = self.elems[self.len - 1];
            self.len -= 1;
        }

        pub fn getAll(self: *Self) []T {
            return self.elems[0..self.len];
        }

        pub fn getAtIndex(self: Self, index: usize) T {
            return self.elems[index];
        }

        pub fn getIterator(self: *Self) iterator.Iterator(T) {
            return iterator.Iterator(T).init(self.elems[0..self.len]);
        }

        pub fn setAtIndex(self: *Self, index: usize, value: T) !void {
            self.elems[index] = value;
        }

        pub fn numOfElems(self: Self) usize {
            return self.len;
        }

        pub fn capacity(self: Self) usize {
            return self.elems.len;
        }

        pub fn quickSort(self: *Self, less: fn(T, T) bool) void {
            quick_sort.quickSort(T, self.getAll(), less);
        }

        // TODO: Test append after truncate
        pub fn truncate(self: *Self, n: usize) void {
            self.len = n;
        }

        fn ensureCapacity(self: *Self, cap: usize) !void {
            if (self.elems.len >= cap) {
                return;
            }

            const new_capacity = nextPowerOf2IfNotPowerOf2(cap);

            var new_elems = try self.allocator.alloc(T, new_capacity);
            std.mem.copy(T, new_elems, self.elems);
            self.allocator.free(self.elems);
            self.elems = new_elems;
        }

    };
}

test "Array" {
    var array = Array(i8).init(testing.allocator);
    defer array.deinit();

    try testing.expectEqual(@as(usize, 0), array.capacity());
    try testing.expectEqual(@as(usize, 0), array.numOfElems());
    {
        const should_be_null = array.pop();
        try testing.expect(should_be_null == null);

        const last = array.lastElem();
        try testing.expect(last == null);
    }

    try array.append(6);
    try testing.expectEqual(@as(usize, 1), array.numOfElems());
    try testing.expectEqualSlices(i8, array.getAll(), &[_]i8{6});

    try array.append(7);
    try array.append(8);
    try testing.expect(array.capacity() >= 3);
    try testing.expectEqualSlices(i8, array.getAll(), &[_]i8{6, 7, 8});

    {
        const should_be_eight = array.pop() orelse unreachable;
        try testing.expect(should_be_eight == 8);

        const last = array.lastElem() orelse unreachable ;
        try testing.expect(last == 7);
    }

    try array.append(9);
    try testing.expectEqualSlices(i8, array.getAll(), &[_]i8{6, 7, 9});

    try array.setAtIndex(1, 11);
    try testing.expectEqualSlices(i8, array.getAll(), &[_]i8{6, 11, 9});

    try array.removeAtIndex(1);
    try testing.expectEqualSlices(i8, array.getAll(), &[_]i8{6, 9});
    try array.removeAtIndex(1);
    try testing.expectEqualSlices(i8, array.getAll(), &[_]i8{6});

    {
        try array.append(10);
        try array.append(11);
        var iter = array.getIterator();
        var actual_list = [_]i8{6, 10, 11};
        var actual_slice: []i8 = &actual_list;
        while (iter.next()) |elem| {
            const actual_elem = actual_slice[0];
            actual_slice = actual_slice[1..];
            try testing.expectEqual(actual_elem, elem);
        }
    }

    {
        try array.append(5);
        try array.append(4);
        quick_sort.quickSort(i8, array.getAll(), i8Less);
        try testing.expectEqualSlices(i8, array.getAll(), &[_]i8{
            4, 5, 6, 10, 11
        });
    }
}

fn i8Less(a: i8, b: i8) bool {
    return a < b;
}

// assumes that n > 0
fn nextPowerOf2IfNotPowerOf2(n: usize) usize {
    var i = n;
    i -= 1;
    i |= i >> 1;
    i |= i >> 2;
    i |= i >> 4;
    i |= i >> 8;
    i |= i >> 16;
    return i + 1;
}

test "nextPowerOfTwo" {
    try testing.expectEqual(@as(usize,1), nextPowerOf2IfNotPowerOf2(1));
    try testing.expectEqual(@as(usize,2), nextPowerOf2IfNotPowerOf2(2));
    try testing.expectEqual(@as(usize,4), nextPowerOf2IfNotPowerOf2(3));
    try testing.expectEqual(@as(usize,4), nextPowerOf2IfNotPowerOf2(4));
    try testing.expectEqual(@as(usize,8), nextPowerOf2IfNotPowerOf2(5));
    try testing.expectEqual(@as(usize,8), nextPowerOf2IfNotPowerOf2(6));
    try testing.expectEqual(@as(usize,8), nextPowerOf2IfNotPowerOf2(7));
    try testing.expectEqual(@as(usize,8), nextPowerOf2IfNotPowerOf2(8));
    try testing.expectEqual(@as(usize,16), nextPowerOf2IfNotPowerOf2(9));
}
