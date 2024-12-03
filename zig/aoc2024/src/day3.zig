const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

pub fn day3() !void {
    const input = try std.io.getStdIn().readToEndAlloc(std.heap.page_allocator, std.math.maxInt(usize));
    {
        var parser: MulParser = .{ .input = input };
        var sum: u64 = 0;
        while (try parser.next()) |mul| {
            sum += mul;
        }
        print("part1: {d}\n", .{sum});
    }

    {
        var parser: MulParserDoDont = .{ .input = input };
        var sum: u64 = 0;
        while (try parser.next()) |mul| {
            sum += mul;
        }
        print("part2: {d}\n", .{sum});
    }
}

const MulParserDoDont = struct {
    input: []const u8,
    pos: usize = 0,
    enabled: bool = true,

    fn next(m: *MulParserDoDont) !?u32 {
        while (true) {
            if (m.pos >= m.input.len) return null;

            var final_pos: usize = undefined;
            var res: u32 = undefined;

            if (m.enabled) {
                final_pos, res = try parseMulExpr(m.input, m.pos) orelse {
                    final_pos = parseDont(m.input, m.pos) orelse {
                        m.pos += 1;
                        continue;
                    };
                    m.pos = final_pos;
                    m.enabled = false;
                    continue;
                };
                assert(final_pos > m.pos);
                m.pos = final_pos;
                return res;
            } else {
                final_pos = parseDo(m.input, m.pos) orelse {
                    m.pos += 1; // very naive
                    continue;
                };
                m.enabled = true;
                m.pos = final_pos;
                continue;
            }
        }
    }
};

const MulParser = struct {
    input: []const u8,
    pos: usize = 0,

    fn next(m: *MulParser) !?u32 {
        while (true) {
            if (m.pos >= m.input.len) return null;
            const final_pos, const res = try parseMulExpr(m.input, m.pos) orelse {
                m.pos += 1;
                continue;
            };
            assert(final_pos > m.pos);
            m.pos = final_pos;
            return res;
        }
    }
};

fn parseDo(input: []const u8, pos: usize) ?usize {
    var pos_mut = pos;
    pos_mut = parsePrefix(input, pos_mut, "do(") orelse return null;
    pos_mut = parseChar(input, pos_mut, ')') orelse return null;
    return pos_mut;
}

fn parseDont(input: []const u8, pos: usize) ?usize {
    var pos_mut = pos;
    pos_mut = parsePrefix(input, pos_mut, "don't(") orelse return null;
    pos_mut = parseChar(input, pos_mut, ')') orelse return null;
    return pos_mut;
}

fn parseMulExpr(input: []const u8, pos: usize) !?struct { usize, u32 } {
    var pos_mut = pos;
    pos_mut = parsePrefix(input, pos_mut, "mul(") orelse return null;
    pos_mut, const num1_str = parseNumber(input, pos_mut) orelse return null;
    pos_mut = parseChar(input, pos_mut, ',') orelse return null;
    pos_mut, const num2_str = parseNumber(input, pos_mut) orelse return null;
    pos_mut = parseChar(input, pos_mut, ')') orelse return null;

    const num1 = try std.fmt.parseInt(u32, num1_str, 10);
    const num2 = try std.fmt.parseInt(u32, num2_str, 10);
    return .{ pos_mut, num1 * num2 };
}

fn parseNumber(input: []const u8, pos: usize) ?struct { usize, []const u8 } {
    var i: usize = 0;
    for (input[pos..]) |b| {
        if (b >= '0' and b <= '9') {
            i += 1;
            continue;
        }
        break;
    }
    return .{ pos + i, input[pos .. pos + i] };
}

fn parsePrefix(input: []const u8, pos: usize, prefix: []const u8) ?usize {
    const final_pos = pos + prefix.len;
    if (input.len <= final_pos) return null;
    const maybe_mul = input[pos..final_pos];
    if (std.mem.eql(u8, prefix, maybe_mul)) {
        return final_pos;
    }
    return null;
}

fn parseChar(input: []const u8, pos: usize, char: u8) ?usize {
    if (pos >= input.len) return null;
    if (input[pos] == char) return pos + 1;
    return null;
}
