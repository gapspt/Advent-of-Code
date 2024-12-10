const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;

const allocator = std.heap.page_allocator;

const input: []const u8 = @embedFile("input/day7.txt");

pub fn part1() !void {
    try checkPossibleEquation(false);
}

pub fn part2() !void {
    try checkPossibleEquation(true);
}

fn checkPossibleEquation(allowConcatenation: bool) !void {
    var sum: i64 = 0;

    var list = ArrayList(i32).init(allocator);
    defer list.deinit();
    var listStr = ArrayList([]const u8).init(allocator);
    defer listStr.deinit();

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
            try listStr.append(value);
        }

        if (findResult(result, list.items, listStr.items, list.items[0], 1, allowConcatenation)) {
            sum += result;
        }

        try list.resize(0);
        try listStr.resize(0);
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

fn findResult(
    result: i64,
    values: []i32,
    valuesStr: [][]const u8,
    currentResult: i64,
    currentIndex: u32,
    allowConcatenation: bool,
) bool {
    if (currentResult > result) {
        return false;
    }
    if (currentIndex == values.len) {
        return result == currentResult;
    }

    const v = values[currentIndex];

    if (findResult(result, values, valuesStr, currentResult + v, currentIndex + 1, allowConcatenation) or
        findResult(result, values, valuesStr, currentResult * v, currentIndex + 1, allowConcatenation))
    {
        return true;
    }
    if (allowConcatenation) {
        const concatResult = currentResult * exp10(@intCast(valuesStr[currentIndex].len)) + v;
        return findResult(result, values, valuesStr, concatResult, currentIndex + 1, allowConcatenation);
    }
    return false;
}

fn exp10(exponent: u32) u32 {
    var exp = exponent;
    var result: u32 = 1;
    while (exp > 0) : (exp -= 1) {
        result *= 10;
    }
    return result;
}
