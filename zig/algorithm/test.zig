const std = @import("std");
const ArrayList = std.ArrayList;

pub fn main() !void {
    var a = MyStruct{.children = ArrayList(?anotherStruct).init(std.heap.page_allocator)};
    try a.children.append(anotherStruct{});
    // var array = ArrayList(MyStruct).init(std.heap.page_allocator);
    // try array.append(a);
    // hello(&array);
    a.myMethod2();
}

fn hello(array: *ArrayList(MyStruct)) void {
    // const a = MyStruct{};
    // a.myMethod();

    for (array.items) |*a| {
        a.myMethod();
        for (a.children.items) |*t| {
            std.debug.print("type t: {s}",.{@TypeOf(t)});
        }
    }
}


const MyStruct = struct {
    a: u8 = 8,
    children: ArrayList(?anotherStruct),

    fn myMethod(s: *MyStruct) void {
        std.debug.print("type: {s}",.{@TypeOf(s)});
        // s.a = 9;
        _ = s;
    }

    fn myMethod2(s: *MyStruct) void {
        std.debug.print("items: {s}\n",.{@TypeOf(s.children.items)});
        for (s.children.items) |opt_t| {
            _ = opt_t;
            std.debug.print("opt_t: {s}\n",.{@TypeOf(opt_t)});
            if (opt_t) |t| {
                std.debug.print("t: {s}\n",.{@TypeOf(t)});

                var var_t = t;
                std.debug.print("var_t: {s}\n",.{@TypeOf(var_t)});

                var t_ptr: *anotherStruct = &var_t;
                std.debug.print("t_ptr: {s}\n",.{@TypeOf(t_ptr)});
            }
        }
    }

};

const anotherStruct = struct {
    a: u8 = 7,
    b: u16 = 8,
};
