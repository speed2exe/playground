const std = @import("std");
const assert = std.debug.assert;

fn foo() void {
    assert(2 + 2 != 4);
}

pub fn main() void {
    foo();
}
