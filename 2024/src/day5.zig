const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;

const allocator = std.heap.page_allocator;
const maxValue = 255;

pub fn part1() !void {
    try sumMiddlePages(true);
}

pub fn part2() !void {
    try sumMiddlePages(false);
}

pub fn sumMiddlePages(correct: bool) !void {
    var matrix: [maxValue + 1][maxValue + 1]bool = undefined;
    for (&matrix) |*row| {
        @memset(row, false);
    }

    var list = ArrayList(u32).init(allocator);
    defer list.deinit();

    var sum: u32 = 0;

    const input: []const u8 = @embedFile("input/day5.txt");

    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| {
        if (mem.indexOfScalar(u8, line, '|') == null) {
            break;
        }

        var valuesSplit = mem.splitScalar(u8, line, '|');
        const x = try fmt.parseInt(u32, valuesSplit.next().?, 10);
        const y = try fmt.parseInt(u32, valuesSplit.next().?, 10);
        matrix[x][y] = true;
    }

    while (linesSplit.next()) |line| {
        if (mem.indexOfScalar(u8, line, ',') == null) {
            continue;
        }

        var valuesSplit = mem.splitScalar(u8, line, ',');
        while (valuesSplit.next()) |value| {
            const v = try fmt.parseInt(u32, value, 10);
            try list.append(v);
        }

        var valid = true;

        const items = list.items;
        var i: usize = 1;
        while (valid and i < items.len) : (i += 1) {
            var j: usize = 0;
            while (j < i) : (j += 1) {
                if (matrix[items[i]][items[j]]) {
                    valid = false;
                    break;
                }
            }
        }

        if (valid and correct) {
            sum += items[items.len / 2];
        } else if (!valid and !correct) {
            // Naive way of fixing the pages' order
            while (!valid) {
                valid = true;
                i = 0;
                while (i < items.len) : (i += 1) {
                    var j: usize = 0;
                    while (j < i) : (j += 1) {
                        if (matrix[items[i]][items[j]]) {
                            valid = false;
                            const temp = items[i];
                            items[i] = items[j];
                            items[j] = temp;
                            break;
                        }
                    }
                }
            }

            sum += items[items.len / 2];
        }

        try list.resize(0);
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}
