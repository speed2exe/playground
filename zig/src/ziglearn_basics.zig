const std = @import("std");
const expect = std.testing.expect;

pub fn main() void {
    {
        var data = [_]u8{1, 2, 3};

        // value capture
        // not mutable
        for (data) |byte| {
            std.log.info("type of byte: {s}, value of byte: {}", .{
                @typeName(@TypeOf(byte)), byte,
            });
        }

        // ptr capture
        // values are mutable
        for (data) |*byte| {
            std.log.info("type of byte: {s}, value of byte: {}", .{
                @typeName(@TypeOf(byte)), byte,
            });
        }
    }
    {
        // print type of null
        std.log.info("type of null: {s}", .{@typeName(@TypeOf(null))});
        std.log.info("type of type of null: {s}", .{@typeName(@TypeOf(@TypeOf(null)))});
    }
    {
        // ternary expression
        const b: i32 = if (true) 28 else unreachable;
        std.log.info("type of b: {s}, value of b: {}", .{
            @typeName(@TypeOf(b)), b,
        });
    }
    {
        // orelse
        const a: ?f32 = 5;

        const b = a orelse unreachable;
        const c = a.?;

        std.log.info("type of b: {s}, value of b: {}", .{
            @typeName(@TypeOf(b)), b,
        });

        std.log.info("type of c: {s}, value of c: {}", .{
            @typeName(@TypeOf(c)), c,
        });
    }
    {
        // for loop without break will trigger else block
        for ([_]u0{0}**10) |_, i| {
            _ = i;
        } else {
            std.log.info("for loop executed without break", .{});
        }
    }
    {
        // while loop returns with value
        var i: usize = 0;
        var result: i32 = while (i < 2) : (i += 1) {
            if (i == 5) {
                break 8;
            }
        } else 9; // if did not break from while loop, (terminating condition)

        std.log.info("type of result: {s}, value of result: {}", .{
            @typeName(@TypeOf(result)), result,
        });
    }
    {
        // not possible, for loop returns void
        // const a = for ([_]u0{0}**10) |_, i| {
        //     break i;
        // };
        // std.log.info("a value: {}", .{a});
    }
    {
        const a = {}; // unlabelled blk yields void, void
        std.log.info("type of a: {s}, value of a: {s}", .{
            @typeName(@TypeOf(a)), a, //void, void
        });
    }
    {
        var a = {};
        std.log.info("type of a: {s}, value of a: {s}", .{
            @typeName(@TypeOf(a)), a, //void,void
        });
    }
    {
        var value :f32 = 0x1p3; // p7 means *(2^7)
        std.log.info("float value: {}", .{value});
    }
    {
        std.log.info("type of Suit: {s}, value of Suit: {s}", .{
            @typeName(@TypeOf(Suit)), Suit,
            // Note: accessing other fields result in panic
        });
        std.log.info("type of Suit.spades: {s}, value of Suit.spades: {s}", .{
            @typeName(@TypeOf(Suit.spades)), Suit.spades,
            // Note: accessing other fields result in panic
        });
    }
    {
        var result = Result{.int = 1234};
        std.log.info("type of result: {s}, value of result.int: {d}", .{
            @typeName(@TypeOf(result)), result.int
            // Note: accessing other fields result in panic
        });
        // how to check the actual underlying type: use tagged union
    }
    {
        // not allowed as &1 will be evaluated as *const comptime_int
        // var a: *i32 = &1;

        var b: i32 = 1;
        var a: *i32 = &b;
        std.log.info("type of a: {s}, type of pointer to a: {s}, value of a: {d}", .{
            @typeName(@TypeOf(a)), @typeName(@TypeOf(a.*)), a
        });
    }
    {
        var thing = &Stuff {
            .x = 10,
            .y = 20,
        };
        std.log.info("type of thing: {s}, type of pointer to thing: {s}, value of thing: {d}", .{
            @typeName(@TypeOf(thing)), @typeName(@TypeOf(thing.*)), thing
        });
    }
    {
        var a: usize = 3;
        const array = [_]u8{1, 2, 3, 4, 5};
        const sliceToEnd = array[a..];
        std.log.info("type of sliceToEnd: {s}, value of sliceToEnd: {d}", .{
            @typeName(@TypeOf(sliceToEnd)),  sliceToEnd // []const u8, {1, 2, 3}
        });
        // Note: slice from start is array[0..X]
    }{
        var a: usize = 3;
        const array = [_]u8{1, 2, 3, 4, 5};
        const slice = array[0..a];
        std.log.info("type of slice: {s}, value of slice: {d}", .{
            @typeName(@TypeOf(slice)),  slice // []const u8, {1, 2, 3}
        });

        const elem = slice[1];
        std.log.info("type of elem: {s}, value of elem: {d}", .{
            @typeName(@TypeOf(elem)),  elem
        });
    }
    {
        // comptime optimization, slice type is promoted to pointer to array
        const array = [_]u8{1, 2, 3, 4, 5};
        const slice = array[0..3];
        std.log.info("type of slice: {s}, value of slice: {d}", .{
            @typeName(@TypeOf(slice)),  slice.* // *const [3]u8, {1, 2, 3}
        });

        const elem = slice[1];
        std.log.info("type of elem: {s}, value of elem: {d}", .{
            @typeName(@TypeOf(elem)),  elem
        });
    }
    {
        // [*]T Array of pointers
        // *[]T pointer to array

        // find out syntax for pointer to a list
        const a: [2]u8 = .{1, 2};
        std.log.info("type of a: {s}, pointer_type: {s}, value of a: {d}", .{
            @typeName(@TypeOf(a)), @typeName(@TypeOf(&a)), a
        });

    }
    {
        // usize and isize (platform dependent)
        const a = @sizeOf(usize);
        const b = @sizeOf(isize);

        std.log.info("size of usize: {}", .{a});
        std.log.info("size of isize: {}", .{b});
    }
    {
        // illegal deference
        // do not do this
        var a: i64 = 8;
        const p_a :*i64 = &a;
        const p_b = @ptrToInt(p_a);
        const p_c = @intToPtr(*i64, p_b + @sizeOf(i64));
        std.log.info("type of p_c: {s}, value of p_c: {}", 
        .{@typeName(@TypeOf(p_c)), p_c.*});
    }

    {
        @setRuntimeSafety(false);
        const a = [3]u8{ 1, 2, 3 };
        var index: u8 = 5;
        const b = a[index];
        // undefined value for b
        std.log.info("type of b: {s}, value of x: {b}",
        .{@typeName(@TypeOf(b)), b});
    }

    {
        // TODO: value as expression
        // const myFunc = fn() getNum i32 {
        //     return 3;
        // }
        // const x = => {};
        // std.log.info("type of x: {s}, value of x: {s}",
        // .{@typeName(@TypeOf(x)), x});
    }

    {
        const x = .{1, "hello"}; // anonymous struct
        std.log.info("type of x: {s}, value of x: {s}",
        .{@typeName(@TypeOf(x)), x});
    }

    {
        const array :[2]u8 = .{'g', 'a'};
        std.log.info("type of array: {s}, value of array: {s}",
        .{@typeName(@TypeOf(array)), array});
    }

    const i32_value: i32 = 3;   
    std.log.info("type of i32_value: {s}", .{@typeName(@TypeOf(i32_value))});
    std.log.info("type of i32: {s}", .{@typeName(@TypeOf(i32))});
    std.log.info("type of type: {s}", .{@typeName(@TypeOf(type))});


    const constant: i32 = 5; //signed 32-bit constant
    var variable: u32 = 500; //unsigned 32-bit constant
    std.log.info("constant: {}, variable: {}", .{constant, variable});

    // @as performs explicit type coerion
    const inferred_constant = @as(i32, 5);
    var inferred_variable = @as(u32, 5000);
    std.log.info("inferred_constant: {}, inferred_variable: {}", .{inferred_constant, inferred_variable});

    // random values for undefined
    const a: i32 = undefined;
    var b: u32 = undefined;
    std.log.info("a: {}, b: {}", .{a, b});

    const array_a = [5]u8{'h', 'e', 'l', 'l', 'o'};
    const array_b = [_]u8{'h', 'e', 'l', 'l', 'o'}; // inferred len
    std.log.info("array_a: {s}, array_b: {s}", .{array_a, array_b});
    const length = array_a.len;
    std.log.info("array.len: {}", .{length});

    // ignored
    _ = 10;

    // weird for loops for numbers but works
    for ([_]u0{0}**10) |_, i| {
        std.log.info("i in loop: {}", .{i});
    }

    std.log.info("before deferring in for loop", .{});
    for ([_]u0{0}**10) |_, i| {
        defer std.log.info("deferring in loop, i: {}", .{i});
    }
    std.log.info("after deferring in for loop", .{});

    // deferif syntax will be nice
    std.log.info("before conditional defer", .{});
    if (true) {
        defer std.log.info("deferring in true", .{});
    }
    std.log.info("after conditional defer", .{});

    // Custom Error
    const helloError = error.HelloError;
    std.log.info("helloError: {}", .{helloError});
    const helloErrorType = @typeName(@TypeOf(helloError));
    std.log.info("helloError type: {s}", .{helloErrorType});

    // Error sets can be merged
    const a_error_type = error{NotDir, PathNotFound};
    const b_error_type = error{OutOfMemory, PathNotFound};
    const c_error_type = a_error_type || b_error_type;
    std.log.info("c_error_type: {s}", .{c_error_type});

    // void: {}, can just return without {}.
    return {};
}

test "if statement" {
    const a = true;
    var x: u16 = 0;
    if (a) {
        x += 1;
    } else {
        x += 2;
    }
    try expect(x == 1);
}

test "while" {
    var i: u8 = 2;
    while (i < 100) {
        i *= 2;
    }
    try expect(i == 128);
}

test "while with continue expression" {
    var sum: u8 = 0;
    var i: u8 = 1;
    while (i <= 10) : (i += 1) {
        // logging to track
        // std.log.warn("i: {d}", .{i});
        // std.log.warn("sum: {d}", .{sum});
        sum += i;
    }
    try expect(sum == 55);
}

test "for" {
    const string =  [_]u8{'a', 'b', 'c'};
    
    for (string) |character, index| {
        _ = character;
        _ = index;
    }

    for (string) |character| {
        _ = character;
    }

    for (string) |_, index| {
        _ = index;
    }

    for (string) |_| {}
}

fn addFive(x: u32) u32 {
    return x + 5;
}

test "function" {
    const y = addFive(0);
    try expect(@TypeOf(y) == u32);
    try expect(y == 5);
}

fn fibonacci(n: u16) u16 {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

test "function recursion" {
    const x = fibonacci(10);
    try expect(x == 55);
}

test "defer" {
    var x: i16 = 5;
    {
        defer x += 2;
        try expect(x == 5);
    }
    try expect (x == 7);
}

test "multi defer" {
    var x: f32 = 5;
    {
        defer x += 2;

        // this will executed first because it is in the top of defer stack
        defer x /= 2;
    }
    try expect(x == 4.5);
}

fn returnWithDefer() i32 {
    var result :i32 = 5;
    defer result += 2;
    return result;
}

// feature not bug
test "return value mutated by defer" {
    try expect(returnWithDefer() == 5);
}

test "block defer" {
    var x: i32 = 5;
    {
        defer {
            x += 2;
            x -= 3;
        }
    }
    try expect(x == 4);
}


// Creating curost error set
const CustomError = error{
    SomeError,
    OutOfMemory,
    AotherError,
};
const AllocationError = error {OutOfMemory};

test "coerce error from a subset to a superset" {
    const err: CustomError = AllocationError.OutOfMemory;
    try expect(err == CustomError.OutOfMemory);
}

test "error union" {
    // maybe_error could be of type u16 or AllocationError
    // it is assigned to 0, which is type u16,
    // thus it is not an error type
    const maybe_error: AllocationError!u16 = 10;

    // if maybe_error is error, maybe_error will be assigned
    // as 0
    const no_error = maybe_error catch 0;

    try expect(@TypeOf(no_error) == u16);
    try expect(no_error == 10);
}

fn failingFunction() error{Oops}! void {
    return error.Oops;
}

test "returning an error" {
    failingFunction() catch |err| {
        try expect(err == error.Oops);
        return;
    };
}

fn failFn() error{Oops}!i32 {
    try failingFunction();
    return 12;
}

test "try" {
    var v = failFn() catch |err| {
        try expect(err == error.Oops);
        return;
    };
    try expect(v == 12); // not reached
}

var problems: u32 = 98;

fn failFnCounter() error{Oops}!void {
    errdefer problems += 1;
    try failingFunction();
}

test "errdefer" {
    failFnCounter() catch |err| {
        // err type is error{Oops}
        // err value is error.Oops

        try expect(err == error.Oops);
        try expect(problems == 99);
        return;
    };
}

fn createFile() !void {
    return error.AccessDenied;
}

test "inferred error set" {
    // type coersion successfully takes place
    const x: error{AccessDenied}!void = createFile();

    // Zig does not let us ignore unions via _ = x;
    // we must unwrap it with "try", "catch", or "if" by any means
    _ = x catch {};
}

test "switch statement" {
    var x: i8 = 10;
    switch (x) {
        -1...1 => {
            x = -x;
        },
        10, 100 => {
            x = @divExact(x, 10);
        },
        else => {},
    }
    try expect(x == 1);
}

test "switch expression" {
    var x: i8 = 10;
    x = switch (x) {
        -1...1 => -x,
        10, 100 => @divExact(x, 10),
        else => x,
    };
    try expect(x == 1);
}

test "out of bounds" {
    // throw eror
    // const a = [3]u8{1, 2, 3};
    // var index: u8 = 5;
    // const b = a[index];
    // _ = b;
}

test "out of bounds, no safety" {
    @setRuntimeSafety(false);
    const a = [3]u8{ 1, 2, 3 };
    var index: u8 = 5;
    const b = a[index];
    _ = b;
}

// test "unreachable" {
//     const x: i32 = 1;
//     const y: u32 = if (x == 2) 5 else unreachable;
// }

fn asciiToUpper(x: u8) u8 {
    return switch (x) {
        'a'...'z' => x + 'A' - 'a',
        'A'...'Z' => x,
        else => unreachable,
    };
}

test "unreachable switch" {
    try expect(asciiToUpper('a') == 'A');
    try expect(asciiToUpper('A') == 'A');
}

// takes in a pointer to u8
fn increment(num: *u8) void {
    num.* += 1;
}

test "pointers" {
    var x: u8 = 1;
    increment(&x); // passes in address of x
    try expect(x == 2);
}

test "naughty pointer" {
    // cannot assign value of pointer to zero
    // var x: u16 = 0;
    // var y: *u8 = @intToPtr(*u8, x);
    // _ = y;
}

test "const pointers" {
    // cannot assign to const value
    // const x: u8 = 1;
    // var y = &x;
    // y.* += 1;
}

test "usize" {
    try expect(@sizeOf(usize) == @sizeOf(*u8));
    try expect(@sizeOf(isize) == @sizeOf(*u8));
}


fn total(values: []const u8) usize {
    var sum: usize = 0;
    for (values) |v| sum += v;
    return sum;
}

test "slices" {
    const array = [_]u8{1, 2, 3, 4, 5};
    const slice = array [0..3];
    try expect(total(slice) == 6);
}

test "slices 2" {
    const array = [_]u8{1, 2, 3, 4, 5};
    const slice = array [0..3];
    try expect(total(slice) == 6);
}

test "slices 3" {
    const array = [_]u8{1, 2, 3, 4, 5};
    const slice = array [0..];
    _ = slice;
}

// type of enum is type
const Direction = enum {
    north,
    south,
    east,
    west,
};

const Value = enum(u2) {
    zero,
    one,
    two,
};

test "enum ordinal value" {
    try expect(@enumToInt(Value.zero) == 0);
    try expect(@enumToInt(Value.one) == 1);
    try expect(@enumToInt(Value.two) == 2);
}

const Value2 = enum(u32) {
    hundred = 100,
    thousand = 1000,
    million = 1000000,
    next,
};

test "set enum ordinal value" {
    try expect(@enumToInt(Value2.hundred) == 100);
    try expect(@enumToInt(Value2.thousand) == 1000);
    try expect(@enumToInt(Value2.million) == 1000000);
    try expect(@enumToInt(Value2.next) == 1000001);
}

const Suit = enum {
    clubs,
    spades,
    diamonds,
    hearts,
    pub fn isClubs(self: Suit) bool {
        return self == Suit.clubs;
    }
};

test "enum method" {
    try expect(Suit.spades.isClubs() == false);
    try expect(Suit.clubs.isClubs() == true);
    try expect(Suit.spades.isClubs() == Suit.isClubs(.spades));
}

const Mode = enum {
    var count: u32 = 0;
    on,
    off,
};

test "hmm" {
    Mode.count += 1;
    try expect(Mode.count == 1);  
}

const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,
};

test "struct usage" {
    const my_vector = Vec3 {
        .x = 0,
        .y = 100,
        .z = 50,
    };
    _ = my_vector;
}

test "missing struct field" {
    // missng z field will not compile
    
    // const my_vector = Vec3 {
    //     .x = 0,
    //     .y = 100,
    // };
    // _ = my_vector;
}

const Vec4 = struct {
    x: f32,
    y: f32,
    z: f32 = 0,
    w: f32 = undefined,
};

test "struct defaults" {
    const my_vector = Vec4 {
        .x = 25,
        .y = -50,
    };
    _ = my_vector;
}

const Stuff = struct {
    x: i32,
    y: i32,
    fn swap(self: *Stuff) void {
        const tmp = self.x;
        self.x = self.y;
        self.y = tmp;
    }
};

test "automatic deference" {
    var thing = Stuff {
        .x = 10,
        .y = 20,
    };
    thing.swap();
    try expect(thing.x == 20);
    try expect(thing.y == 10);
}

test "automatic deference 2" {
    var thing = &Stuff {
        .x = 10,
        .y = 20,
    };
    try expect(thing.x == 10);
    try expect(thing.y == 20);
}

test "automatic deference" {
    // TypeOf(thing): *const Stuff
    // defaults to const for &
    // var thing = &Stuff {
    //     .x = 10,
    //     .y = 20,
    // };

    var thing = Stuff {
        .x = 10,
        .y = 20,
    };
    var thing_ptr = &thing;

    thing_ptr.*.swap(); // needed type: *Stuff
    try expect(thing.x == 20);
    try expect(thing.y == 10);
}

// Result is a type
const Result = union {
    int: i64,
    float: f64,
    boolean: bool,
};

test "simple union" {
    // not allowed to access multiple of type of union
    // var result = Result {.int =  1234};
    // result.float = 12.34;
}

// Enum
const DataType = enum {
    number,
    boolean,
};

// Tagged union
// all variants of DataType MUST be inside
const Data = union(DataType) {
    number: u8,
    boolean: bool,
};

test "switch on tagged union" {
    var result: u8 = 1;

    var value = Data {.number = 5};
    switch (value) {
        // case when there the union type is number
        // numberData is having the type: *u8
        .number => |*numberData| result += numberData.*,

        // must be exhaustive,
        .boolean => |_|{},
    }

    try expect(result == 6);
}

// Recommended when there are no other use of enum except when
// being tag
const Data2 = union(enum) {
    number: u8,
    boolean: bool,
};

test "integer widening" {
    const a: u8 = 250;
    const b: u16 = a;
    const c: u32 = b;
    try expect(c == a);
}

test "@intCast" {
    const x: u64 = 200;
    const y: u8 = @intCast(u8, x); // @as also works
    try expect(@TypeOf(y) == u8);
}

test "well defined overflow" {
    var a: u8 = 255;
    a +%= 1;
    try expect(a == 0);
}

test "float widening" {
    const a: f16 = 0;
    const b: f32 = a;
    const c: f128 = b;
    try expect(c == @as(f128, a));
}

test "labelled blocks" {
    const count = blk: {
        var sum: u32 = 0;
        var i: u32 = 0;
        while (i < 10) : (i += 1) sum += i; // 1-9 inclusive
        break :blk sum;
    };
    try expect(count == 45);
    try expect(@TypeOf(count) == u32);
}

test "nested continue" {
    var count: usize = 0;
    outer: for ([_]i32{1, 2, 3, 4, 5, 6, 7, 8}) |_| {
        for ([_]i32{1, 2, 3, 4, 5,}) |_| {
            count += 1;
            continue :outer;
        }
    }
    try expect(count == 8);
}

fn rangeHasNumber(begin: usize, end: usize, number: usize) bool {
    var i = begin;
    return while (i < end) : (i += 1) {
        if (i == number) {
            break true;
        }
    } else false;
}

test "while loop expression" {
    try expect (rangeHasNumber(0, 10, 3));
}

test "optional" {
    // result can be null or usize type
    var found_index: ?usize = null;

    const data = [_]i32{1, 2, 3, 4, 5, 6, 7, 8, 12};
    for (data) |v, i| {
        if (v == 10) found_index = i;
    }
    try expect(found_index == null);
}

test "optional orelse" {
    var a: ?f32 = null;

    // unwrap the optional
    // orelse triggers when a == null
    var b = a orelse 0;

    try expect(b == 0);
    try expect(@TypeOf(b) == f32);
}

test "optinal orelse unreachable" {
    const a: ?f32 = 5;

    const b = a orelse unreachable;
    const c = a.?; // short hand for above

    try expect(b == c);
    try expect(@TypeOf(c) == f32);
}

test "if optional payload capture" {
    const a: ?i32 = 5;

    // a.? is weird since check for null is already done
    if (a != null) {
        const value = a.?;
        _ = value;
    }
    
    // more natural to do something with b if b contains value instead of null
    var b: ?i32 = 5;
    if (b) |*value| {
        value.* += 1;
    }
    try expect(b.? == 6);
}

var numbers_left: u32 = 4;
fn eventuallyNullSequence() ?u32 {
    if (numbers_left == 0) return null;
    numbers_left -= 1;
    return numbers_left;
}

test "while null capture" {
    var sum: u32 = 0;
    while (eventuallyNullSequence()) |value| { // |value| denotes payload capturing
        sum += value; // value: 3, 2, 1
    }
    try expect (sum == 6);
}

test "comptime blocks" {
    // forcefully evaluated at compile time
    // using comptime keyword
    var x = comptime fibonacci(10);
    _ = x;

    // same as above
    var y = comptime blk: {
        break :blk fibonacci(10);
    };
    _ = y;
}

test "comptime_int" {
    const a = 12;
    const b = a + 10;

    const c: u4 = a;
    _ = c;
    // compile type int are of type comptime_int (arbituary precision)
    // can be coerce to any integer type or float that can hold them,

    const d: f32 = b;
    _ = d;
    // compile type float are of type comptime_float (f128 internally)
    // cannot be coerce to int
}

test "branching on types" {
    const a = 5;

    // type of b is determined at compile time
    const b: if (a < 10) f32 else i32 = 5;
    _ = b;
}

fn Matrix(
    comptime T: type,
    comptime width: comptime_int,
    comptime height: comptime_int,
) type {
    return [height][width]T;
}

test "returning a type from Matrix" {
    try expect(Matrix(f32, 4, 4) == [4][4]f32);
}

fn addSmallInts(comptime T: type, a: T, b: T) T {
    return switch (@typeInfo(T)) { // typeInfo returns a tagged union
        .ComptimeInt => a + b,
        .Int => |info| if (info.bits <= 16)
            a + b
        else
            @compileError("ints too large"),
        else
            => @compileError("only ints accepted"),
    };
    // TODO: find out how typeInfo works, switch and get captured value
}

test "typeinfo switch" {
    const x = addSmallInts(u16, 20, 30);
    try expect(@TypeOf(x) == u16);
    try expect(x == 50);
}

fn GetBiggerInt(comptime T: type) type {
    return @Type(.{
        .Int = .{
            .bits = @typeInfo(T).Int.bits + 1,
            .signedness = @typeInfo(T).Int.signedness,
        }
    });
}

test "@Type" {
    try expect(GetBiggerInt(u8) == u9);
    try expect(GetBiggerInt(i31) == i32);
}

fn Vec(
    comptime count: comptime_int,
    comptime T: type,
) type {
    return struct {
        data: [count]T,
        const Self = @This();

        fn abs(self: Self) Self {
            var tmp = Self {
                .data = undefined
            };
            for (self.data) |elem, i| {
                tmp.data[i] = if (elem < 0)
                    -elem
                else
                    elem;
            }
            return tmp;
        }

        fn init(data: [count]T) Self {
            return Self {
                .data = data,
            };
        }


    };
}

const eql = @import("std").mem.eql;

test "generic vector" {
    const x = Vec(3, f32).init([_]f32{10, -10, 5});
    const y = x.abs();
    try expect(eql(f32, &y.data, &[_]f32{10, 10, 5}));
}

fn plusOne(x: anytype) @TypeOf(x) {
    // TODO: type switch here
    return x + 1;
}

test "inferred function parameter" {
    try expect(plusOne(@as(u32, 1)) == 2);
}

test "comptime ++" {
    const x: [4]u8 = undefined;
    const y = x[0..];

    const a: [6]u8 = undefined;
    const b = a[0..];

    // concatenation and repeating arrays and slices
    const new = y ++ b;
    try expect(new.len == 10);
}

test "comptime **" {
    const pattern = [_]u8{1, 2};
    const memory = pattern ** 3;
    try expect(eql(
        u8,
        &memory,
        &[_]u8{1, 2, 1, 2, 1, 2},
    ));
}

test "optional-if" {
    var maybe_num: ?usize = 10;
    if (maybe_num) |payload| {
        try expect(@TypeOf(payload) == usize);
        try expect(payload == 10);
    } else {
        unreachable;
    }
}

test "error union if" {
    var ent_num: error{UnknownEntity}!u32 = 5;
    if (ent_num) |entity| {
        try expect(@TypeOf(entity) == u32);
        try expect(entity == 5);
    } else |err| {
        _ = err catch {};
        unreachable;
    }
}

test "while optional" {
    var i: ?u32 = 10;
    while (i) |num| {
        i.? -= 1;
        try expect(@TypeOf(num) == u32);
        if (num == 1) {
            i = null;
            break;
        }
    }
    
    try expect(i == null);
}

var numbers_left2: u32 = undefined;

fn eventuallyErrorSequence() !u32 {
    return if (numbers_left2 == 0) error.ReachedZero else blk: {
        numbers_left2 -= 1;
        break :blk numbers_left2;
    };
}

test "while error union capture" {
    var sum: u32 = 0;
    numbers_left2 = 3;
    while (eventuallyErrorSequence()) |value| {
        sum += value;
    } else |err| {
        try expect(err == error.ReachedZero);
    }
}

test "for capture" {
    const x = [_]i8{1, 5, 120, -5};
    for (x) |v| try expect(@TypeOf(v) == i8);
}

const Info = union(enum) {
    a: u32,
    b: []const u8,
    c,
    d: u32,
};

test "switch tagged union with capture" {
    var b = Info {
        .a = 10,
    };

    const x = switch (b) {
        .b => |str| blk: {
            try expect(@TypeOf(str) == []const u8);
            break :blk 1;
        },
        .c => 2,
        .a, .d => |num| blk: {
            try expect(@TypeOf(num) == u32);
            break :blk num * 2;
        }
    };

    try expect(x == 20);
}

test "for with pointer capture" {
    var data = [_]u8{1, 2, 3};
    for (data) |*byte| byte.* += 1;
    try expect (eql(u8, &data, &[_]u8{2, 3, 4}));
}

test "inline for" {
    const types = [_]type{i32, f32, u8, bool};
    var sum: usize = 0;

    // inline loops are unrolled, only work at comptime
    // only use this for perf if properly tested
    inline for (types) |T| sum +=  @sizeOf(T);
    try expect(sum == 10);
}

// const Window = opaque {};
const Button = opaque {};

extern fn show_window(*Window) callconv(.C) void;

test "opaque" {
    // var main_window: *Window = undefined;
    // show_window(main_window);

    // var ok_button: *Button = undefined;
    // show_window(ok_button);
}

const Window = opaque {
    fn show(self: *Window) void {
        show_window(self);
    }
};

test "opaque with declarations" {
    // var main_window: *Window = undefined;
    // main_window.show();
}

test "anonymouse struct literal" {
    const Point = struct {x: i32, y: i32};
    // anon declaration
    var pt: Point =  .{
        .x = 13,
        .y = 67,
    };
    try expect(pt.x == 13);
    try expect(pt.y == 67);

    // non anon declaration
    var pt2 = Point {
        .x = 13,
        .y = 67,
    };
    try expect(pt2.x == 13);
    try expect(pt2.y == 67);
}

test "fully anonymous struct" {
    try dump(.{
        .int = @as(u32, 1234),
        .float = @as(f64, 12.34),
        .b = true,
        .s = "hi",
    });
}

fn dump(args: anytype) !void {
    try(expect(args.int == 1234));
    try(expect(args.float == 12.34));
    try(expect(args.b));
    try(expect(args.s[0] == 'h'));
    try(expect(args.s[1] == 'i'));
}

test "tuple" {
    const values = .{
        @as(u32, 1234),
        @as(f64, 12.34),
        true,
        "hi",
    } ++ .{false} ** 2;

    try expect(values[0] == 1234);
    try expect(values[4] == false);
    inline for (values) |v, i| {
        if (i != 2) continue;
        try expect(v);
    }
    try expect(values.len == 6);
    try expect(values.@"3"[0] == 'h');
}

test "sentinel termination" {
    const terminated = [3:0]u8{3, 2, 1};
    try expect(terminated.len == 3);
    try expect(@bitCast([4]u8, terminated)[3] == 0);
}

test "string literal" {
    try expect(@TypeOf("hello") == *const [5:0]u8);
}

test "sentinel termination coersion" {
    var a: [*:0]u8 = undefined;
    const b: [*]u8 = a;
    _ = b;

    var c: [5:0]u8 = undefined;
    const d: [5]u8 = c;
    _ = d;

    var e: [10]f32 = undefined;
    const f = e;
    _ = f;
}

