const std = @import("std");
const ext = @import("./ext.zig");

pub fn build(b: *std.Build) void {
    _ = b;
    ext.do();
}
