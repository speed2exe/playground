const std = @import("std");
const mymod = @import("mymodule");

pub fn main() !void {
    mymod.myfunc();
}
