const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const leaked = gpa.deinit();
        if (leaked) {
            std.log.err("got leaked!",.{});
        }
    }
    // // 1 to 100 random order
    const data = [_]u8 {
        5,4,3,2

        // 86, 53, 13, 36, 8, 64, 65, 1, 90, 14, 25, 79, 70, 98, 54, 55, 6, 17,
        // 12, 77, 46, 49, 82, 58, 26, 89, 48, 83, 27, 42, 80, 97, 52, 39, 76, 22,
        // 85, 9, 29, 11, 2, 20, 66, 87, 40, 50, 35, 15, 92, 74, 78, 67, 28, 63,
        // 68, 62, 23, 94, 75, 96, 69, 88, 99, 44, 16, 91, 72, 33, 84, 45, 34, 51,
        // 32, 37, 7, 47, 31, 57, 93, 21, 19, 10, 4, 81, 3, 71, 18, 56, 60, 24,
        // 100, 41, 95, 73, 38, 30, 61, 59, 43, 5
    };

    // initialised a fib. heap
    // put all data
    // take out all min

    var fib_heap = FibonacciHeap(u8).init(allocator, u8Less);
    defer fib_heap.deinit();

    // std.debug.print("{}",.{fib_heap});

    // const data = [_]u8 {
        // 86, 53, 13, 36, 8, 71,
    // };


    for (data) |value| {
        try fib_heap.insert(value);
    }

    // const pek = fib_heap.peekStaging();
    // std.debug.print("{any}",.{pek});
    // try fib_heap.stageIndex();

    // var count: usize = 1;

    // _ = try fib_heap.peekStaging();
    while (fib_heap.pop() catch unreachable) |value| {
        std.debug.print("popped: {d}\n", .{value});
        return;
    }
}

fn u8Less(a: u8, b: u8) bool {
    return a < b;
}

pub fn FibonacciHeap(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        bucketed_roots: ArrayList(?FibonacciNode(T)),
        unbucketed_roots: ArrayList(FibonacciNode(T)),

        // index of bucketed_roots with value that has lowest key value
        // null, if already calculated
        staging_index: ?usize,

        less: fn(a: T, b: T) bool,

        pub fn init (
           allocator: std.mem.Allocator,
           less: fn(a: T, b: T) bool,
        ) Self {
           return Self {
               .allocator = allocator,
               .bucketed_roots = ArrayList(?FibonacciNode(T)).init(allocator),
               .unbucketed_roots = ArrayList(FibonacciNode(T)).init(allocator),
               .staging_index = null,
               .less = less,
           };
        }

        // deinitialized this data structure
        pub fn deinit(self: *Self) void {
            for (self.bucketed_roots.items) |opt_root| {
                var root = opt_root orelse continue;
                root.deinit();
            }
            self.bucketed_roots.deinit();
            
            for (self.unbucketed_roots.items) |*root| {
                root.deinit();
            }
            self.unbucketed_roots.deinit();
        }

        // Return key of the highest Priority
        pub fn peek(self: *Self) !?T {
           const node_opt = try self.peekStaging();
           const node = node_opt orelse return null;
           return node.key;
        }

        // Key must still be valid for the whole lifetime of this structure
        // if the key type is not primitive
        pub fn insert(self: *Self, key: T) !void {
            print("insert: append called\n", .{});
            try self.unbucketed_roots.append(FibonacciNode(T).init(self.allocator, key));
        }

        pub fn pop(self: *Self) !?T {
            try self.stageIndexIfNull();
            const staging_index = self.staging_index orelse return null;
            var node = self.bucketed_roots.items[staging_index] orelse unreachable;
            defer { // invalidate staging
                self.bucketed_roots.items[staging_index] = null;
                self.staging_index = null;
            }
            try self.unbucketed_roots.appendSlice(node.children.items);
            node.children.deinit();
            return node.key;
        }

        fn peekStaging(self: *Self) !?FibonacciNode(T) {
            try self.stageIndexIfNull();
            const staging_index = self.staging_index orelse return null;
            return self.bucketed_roots.items[staging_index];
        }

        fn stageIndexIfNull(self: *Self) !void {
            if (self.staging_index == null)  {
                try self.stageIndex();
            }
        }

        // assigns index of node with lowest value
        fn stageIndex(self: *Self) !void {
            // insert all nodes from unbucketed_roots to bucketed_roots
            defer self.unbucketed_roots.clearRetainingCapacity();
            for (self.unbucketed_roots.items) |*root| {
                try self.insertNodeToBucketed(root);
            }

            // select 1st elem, do nothing if unable to be found
            var min_index: usize = undefined;
            var min_key: T = undefined;
            for (self.bucketed_roots.items) |opt_root, opt_root_index| {
                const root = opt_root orelse continue;
                min_index = opt_root_index;
                min_key = root.key;
                break;
            } else {
                return;
            }

            {   // iterate over all the other buckets, find node with lowest value
                var index = min_index; 
                while (index < self.bucketed_roots.items.len) : (index += 1) {
                    const node = self.bucketed_roots.items[index] orelse continue;
                    const key = node.key;
                    if (self.less(key, min_key)) {
                        min_index = index;
                        min_key = key;
                    }
                }
            }

            self.staging_index = min_index;
        }

        fn insertNodeToBucketed(self: *Self, node: *FibonacciNode(T)) !void {
            var degree = node.degree();

            // supposed to fit degree 0 in index 0, degree 1 in index 1 ...
            // worse case is when if max degree node of bucketed_roots same as incoming
            // node, we need to accommodate for merging
            try self.bucketed_roots.appendNTimes(null, 1);
            defer {
                var last_node = self.bucketed_roots.pop();
                if (last_node) |_| {
                    self.bucketed_roots.appendAssumeCapacity(last_node);
                }
                // print("inserted at {d} degree\n",.{degree});
            }

            while (true) { defer { degree += 1; }

                // check if node already existed in bucketed_roots with degree
                // not exists => just put new node and return
                // print("degree: {d}\n",.{degree});
                // print("len: {d}\n",.{self.bucketed_roots.items.len});

                var existing_node: FibonacciNode(T) = self.bucketed_roots.items[degree] orelse {
                    self.bucketed_roots.items[degree] = node.*;
                    return;
                };

                self.bucketed_roots.items[degree] = null; // node in current pos will cease to exist

                // need to merge since 2 nodes trying to occupy the same space
                if (self.less(node.key, existing_node.key)) {
                    try node.add_child(existing_node);
                    continue;
                } 
                try existing_node.add_child(node.*);
                node.* = existing_node;
            }
        }

        // meld (combine heap)

        // decrease key

        // pub fn prettyPrint() void {
        //     // if have time
        // }

    };
}

fn FibonacciNode(comptime T: type) type {
    return struct {
        const Self = @This();
        key: T,
        children: ArrayList(FibonacciNode(T)),

        fn init(allocator: std.mem.Allocator, key: T) Self {
            return Self {
                .key = key,
                .children = ArrayList(FibonacciNode(T)).init(allocator),
            };
        }

        fn deinit(self: *Self) void {
            //print("node deinit len: {d}\n", .{self.children.items.len});
            var items = self.children.items;
            // for (self.children.items) |*child_ptr| {
            for (items) |*child_ptr| {
                child_ptr.deinit();
            }
            self.children.deinit();
        }

        fn degree(self: Self) usize {
            return self.children.items.len;
        }

        fn add_child(self: *Self, child: FibonacciNode(T)) !void {
            print("add_child: append called\n",.{});
            try self.children.append(child);
        }
    };
}

