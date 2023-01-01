//
const std = @import("std");

pub fn main() void {
    {
        // print type of function
        std.log.info("type of sayHi, {}", .{@TypeOf(sayHi)});
    }

    takeInFunc(sayHi);

    // get a function and execute it
    {
        const a = returnAFunc();
        std.log.info("type of a, {}", .{@TypeOf(a)});
        a();
    }

    {
        // create a function on the fly
        var b: fn () void = struct {
            fn customFunc() void {
                std.log.info("in custom func", .{});
            }
        }.customFunc;
        b();
    }

    // create fn and call it on the fly
    defer struct {
        fn f() void {
            std.log.info("deferred create and call", .{});
        }
    }.f();

    // as tuple
    {
        struct {
            fn _() void {
                std.log.info("create and call", .{});
            }
        }._();
    }

    // unable to do
    //var c: fn() void = .{fn customFunc() void {
    //std.log.info("in custom func", .{}),
    //}};
    //_ = c;
    //std.log.info("type of c {s}", .{@TypeOf(c)});

    // takes in anonFunc
    takeInFunc(struct {
        fn _() void {
            std.log.info("tooked in this anon func", .{});
        }
    }._);

    {
        var oneTimeStruct = .{
            .a = @as(u32, 1324),
            .b = struct {
                fn _() void {
                    std.log.info("calling b in one time struct {}", .{ .a = .a });
                }
            }._,
            .c = sayHi,
        };
        std.log.info("one time struct {}", .{oneTimeStruct});
        oneTimeStruct.b();
        oneTimeStruct.c();
    }

    // defer a whole block of instructions
    defer {
        std.log.info("hi there! deferred 1", .{});
        std.log.info("hi there! deferred 2", .{});
        std.log.info("hi there! deferred 3", .{});
    }
    {
        // TODO: implement one time struct with field and methods
        var s = struct {
            // fill me!!!
        };
    }
    {}
}

fn takeInFunc(f: fn () void) void {
    f();
}

fn sayHi() void {
    std.log.info("hi there!", .{});
}

fn returnAFunc() fn () void {
    return sayHi;
}

// fn returnAnonFunc() fn() void {
//     return fn hello() void {
//         std.log.info("surprised!", .{});
//     };
// }
