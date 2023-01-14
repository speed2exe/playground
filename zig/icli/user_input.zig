pub const UserInput = struct {
    pre_cursor: []const u8,
    post_cursor: []const u8,

    pub fn init(pre: []const u8, post: []const u8) UserInput {
        return .{
            .pre_cursor = pre,
            .post_cursor = post,
        };
    }
};
