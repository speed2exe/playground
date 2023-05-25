const std = @import("std");
test "1" {
    const myFunc = struct {
        fn f() i8 {
            return 1;
        }
    }.f;

    var a = myFunc();
    std.log.warn("a: {}", .{a});

    const fiveStr = "5";

    const

}
