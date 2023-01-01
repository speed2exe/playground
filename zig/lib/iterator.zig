pub fn Iterator(comptime T: type) type {
    return struct {
        const Self = @This();

        elems: []T,

        pub fn init(elems: []T) Self {
            return Self{
                .elems = elems,
            };
        }

        pub fn next(self: *Self) ?T {
            if (self.elems.len == 0) {
                return null;
            }
            var result = self.elems[0];
            self.elems = self.elems[1..];
            return result;
        }
    };
}
