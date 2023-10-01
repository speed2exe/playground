const std = @import("std");
pub const mymod = @import("mymodule.zig");

test "mytest" {
    std.testing.refAllDeclsRecursive(@This());
}
