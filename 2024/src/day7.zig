const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;

const allocator = std.heap.page_allocator;

const input: []const u8 = @embedFile("input/day7.txt");

pub fn part1() !void {
    var sum: i64 = 0;

    var list = ArrayList(i32).init(allocator);
    defer list.deinit();

    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| {
        const splitIndex = mem.indexOf(u8, line, ": ");
        if (splitIndex == null) {
            break;
        }

        const result = try fmt.parseInt(i64, line[0..splitIndex.?], 10);

        var valuesSplit = mem.splitScalar(u8, line[splitIndex.? + 2 ..], ' ');
        while (valuesSplit.next()) |value| {
            try list.append(try fmt.parseInt(i32, value, 10));
        }

        if (findResult(result, list.items, list.items[0], 1)) {
            sum += result;
        }

        try list.resize(0);
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

pub fn part2() !void {}

fn findResult(result: i64, values: []i32, currentResult: i64, currentIndex: u32) bool {
    if (currentResult > result) {
        return false;
    }
    if (currentIndex == values.len) {
        return result == currentResult;
    }

    return findResult(result, values, currentResult + values[currentIndex], currentIndex + 1) or
        findResult(result, values, currentResult * values[currentIndex], currentIndex + 1);
}
