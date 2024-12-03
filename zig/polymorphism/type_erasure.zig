const std = @import("std");

// concrete type 1
pub const IntPrinter = struct {
    value: i32,

    pub fn print(self: IntPrinter) void {
        std.debug.print("IntPrinter.value: {d}\n", .{self.value});
    }
    pub fn increment(self: *IntPrinter) void {
        self.value += 1;
    }
};

// concrete type 2
pub const FloatPrinter = struct {
    value: f32,

    pub fn print(self: FloatPrinter) void {
        std.debug.print("FloatPrinter.value: {d}\n", .{self.value});
    }
    pub fn increment(self: *FloatPrinter) void {
        self.value += 1.2;
    }
};

// abstract type
pub const IncPrinter = struct {
    const PrintFn = *const fn (*anyopaque) void;
    const IncrementFn = *const fn (*anyopaque) void;

    ptr: *anyopaque,
    vtable: *const struct {
        print: PrintFn,
        increment: IncrementFn,
    },

    // takes a pointer to a struct that implements the print and increment functions
    pub fn init(p: anytype) IncPrinter {
        return .{
            .ptr = p,
            .vtable = &.{
                .print = @ptrCast(&@TypeOf(p.*).print),
                .increment = @ptrCast(&@TypeOf(p.*).increment),
            },
        };
    }

    pub fn print(self: IncPrinter) void {
        self.vtable.print(self.ptr);
    }
    pub fn increment(self: IncPrinter) void {
        self.vtable.increment(self.ptr);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var x: IntPrinter = .{ .value = 5 };
    var z: FloatPrinter = .{ .value = 5.5 };

    var list = std.ArrayList(IncPrinter).init(gpa.allocator());
    defer list.deinit();

    try list.append(IncPrinter.init(&x));
    try list.append(IncPrinter.init(&z));

    for (list.items) |item| {
        item.print();
    }
    for (list.items) |item| {
        item.increment();
    }
    for (list.items) |item| {
        item.print();
    }
}
