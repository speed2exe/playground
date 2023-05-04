const std = @import("std");

pub fn main() !void {
    const addFn = getAddFn();
    var a: i32 = 1;
    var b: i32 = 2;
    const result = addFn(a, b);
    std.log.info("result = {d}", .{result});

    const addFn2 = getAddFn2(8);
    var e: i32 = 4;
    const result2 = addFn2.add(e);
    std.log.info("result2 = {d}", .{result2});

    const addFn3 = getAddFn3(&addFn, 987);
    const result3 = addFn3.addWithLockedIn(45);
    std.log.info("result3 = {d}", .{result3});

    try printNiceStuff();

    const err_covered = coverError(printNiceStuff);
    err_covered.run();

    const err_covered2 = coverError(throwError);
    err_covered2.run();
}

fn getAddFn() fn (i32, i32) i32 {
    return struct {
        pub fn add(a: i32, b: i32) i32 {
            return a + b;
        }
    }.add;
}

fn getAddFn2(k: i32) struct {
    val: i32,
    pub fn add(this: @This(), e: i32) i32 {
        return this.val + e;
    }
} {
    return .{ .val = k };
}

fn getAddFn3(orginalAdd: *const fn (i32, i32) i32, locked_in_value: i32) struct {
    locked_in_value: i32,
    add: *const fn (i32, i32) i32,
    pub fn addWithLockedIn(this: @This(), e: i32) i32 {
        std.log.info("locked_in_value is {d}", .{this.locked_in_value});
        return this.add(this.locked_in_value, e);
    }
} {
    return .{
        .locked_in_value = locked_in_value,
        .add = orginalAdd,
    };
}

fn printNiceStuff() !void {
    return std.io.getStdOut().writeAll("hello world\n");
}

fn throwError() !void {
    return error.NotImplemented;
}

fn coverError(f: *const fn () anyerror!void) struct {
    f: *const fn () anyerror!void,
    pub fn run(this: @This()) void {
        this.f() catch |err| {
            std.log.err("error: {any}", .{err});
        };
    }
} {
    return .{ .f = f };
}
