const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;

const allocator = std.heap.page_allocator;

var list = ArrayList([]const u8).init(allocator);

pub fn part1() !void {
    try readList();
    const items = list.items;

    var sum: i64 = 0;

    var r: i32 = 0;
    const rows = items.len;
    while (r < rows) : (r += 1) {
        const ur: usize = @intCast(r);
        const columns = items[ur].len;
        var c: i32 = 0;
        while (c < columns) : (c += 1) {
            if (checkXmas(items, r, c, 0, 1)) {
                sum += 1;
            }
            if (checkXmas(items, r, c, 0, -1)) {
                sum += 1;
            }
            if (checkXmas(items, r, c, 1, 0)) {
                sum += 1;
            }
            if (checkXmas(items, r, c, 1, 1)) {
                sum += 1;
            }
            if (checkXmas(items, r, c, 1, -1)) {
                sum += 1;
            }
            if (checkXmas(items, r, c, -1, 0)) {
                sum += 1;
            }
            if (checkXmas(items, r, c, -1, 1)) {
                sum += 1;
            }
            if (checkXmas(items, r, c, -1, -1)) {
                sum += 1;
            }
        }
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

pub fn part2() !void {}

fn readList() !void {
    const input: []const u8 = @embedFile("input/day4.txt");

    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| {
        try list.append(line);
    }
}

fn checkXmas(items: [][]const u8, r: i32, c: i32, rInc: i32, cInc: i32) bool {
    const rLimit: i32 = r + (rInc * 3);
    if (rLimit < 0 or rLimit >= items.len) {
        return false;
    }
    const ur0: usize = @intCast(r);
    const ur1: usize = @intCast(r + rInc);
    const ur2: usize = @intCast(rLimit - rInc);
    const ur3: usize = @intCast(rLimit);

    const cLimit: i32 = c + (cInc * 3);
    if (cLimit < 0 or cLimit >= items[ur3].len or
        c + cInc >= items[ur1].len or cLimit - cInc >= items[ur2].len)
    {
        return false;
    }
    const uc0: usize = @intCast(c);
    const uc1: usize = @intCast(c + cInc);
    const uc2: usize = @intCast(cLimit - cInc);
    const uc3: usize = @intCast(cLimit);

    return items[ur0][uc0] == 'X' and
        items[ur1][uc1] == 'M' and
        items[ur2][uc2] == 'A' and
        items[ur3][uc3] == 'S';
}
