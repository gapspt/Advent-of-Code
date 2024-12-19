// https://adventofcode.com/2024/day/19

const std = @import("std");
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;

var allocator: mem.Allocator = std.heap.page_allocator;

const input: []const u8 = @embedFile("input/day19.txt");

pub fn part1() !void {
    var list = ArrayList([]const u8).init(allocator);
    defer list.deinit();

    var linesSplit = mem.splitScalar(u8, input, '\n');

    var valuesSplit = mem.split(u8, linesSplit.first(), ", ");
    while (valuesSplit.next()) |value| {
        try list.append(value);
    }
    _ = linesSplit.next();

    var items = list.items;

    // Prune patterns that are made of other patterns
    var len = items.len;
    var i: u32 = 0;
    while (i < len) {
        const item = items[i];
        const lastItem = items[len - 1];
        items[i] = lastItem;

        if (canMatch(items[0..(len - 1)], item)) {
            len -= 1;
        } else {
            items[i] = item;
            items[len - 1] = lastItem;
            i += 1;
        }
    }
    items = items[0..len];

    var sum: i32 = 0;
    while (linesSplit.next()) |line| {
        if (line.len == 0) {
            break;
        }

        if (canMatch(items, line)) {
            sum += 1;
        }
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

pub fn part2() !void {}

fn canMatch(patterns: [][]const u8, design: []const u8) bool {
    for (patterns) |pattern| {
        if (mem.startsWith(u8, design, pattern)) {
            if (pattern.len == design.len or canMatch(patterns, design[pattern.len..])) {
                return true;
            }
        }
    }
    return false;
}
