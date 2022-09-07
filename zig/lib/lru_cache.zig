const std = @import("std");

pub fn LRUCache (
    comptime max_size: usize,
    comptime HashMapType: type,
) LRUCache {

    const Self = @This();
    list

    return struct {
        map: HashMapType

        fn init(h: HashMapType) Self {
            return Self {
                .map = h,
            };
        }

        fn get() T {
        }

    }

}
