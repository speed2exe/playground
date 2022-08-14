const std = @import("std");

fn fibonacci(x: u32) u32 {
    if (x <= 1) return x;
    return fibonacci(x - 1) + fibonacci(x - 2);
}

test "fib example" {
    const x = comptime fibonacci(7);
    const array: [x]i32 = undefined;
    @compileLog(array.len);
}
