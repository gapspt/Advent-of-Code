// https://adventofcode.com/2024/day/19

const std = @import("std");
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;

var allocator: mem.Allocator = std.heap.page_allocator;

const input: []const u8 = @embedFile("input/day19.txt");

pub fn part1() !void {
    try findPossiblePatterns(true);
}

pub fn part2() !void {
    try findPossiblePatterns(false);
}

pub fn findPossiblePatterns(firstOnly: bool) !void {
    var list = ArrayList([]const u8).init(allocator);
    defer list.deinit();

    var linesSplit = mem.splitScalar(u8, input, '\n');

    var valuesSplit = mem.split(u8, linesSplit.first(), ", ");
    while (valuesSplit.next()) |value| {
        try list.append(value);
    }
    _ = linesSplit.next();

    const items = list.items;

    var sum: i64 = 0;
    while (linesSplit.next()) |line| {
        if (line.len == 0) {
            break;
        }

        sum += try countMatches(items, line, firstOnly);
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

fn countMatches(patterns: [][]const u8, design: []const u8, firstOnly: bool) !i64 {
    const counts = try allocator.alloc(i64, design.len + 1);
    defer allocator.free(counts);
    @memset(counts, -1);
    return countMatchesAux(patterns, design, firstOnly, counts);
}
fn countMatchesAux(patterns: [][]const u8, design: []const u8, firstOnly: bool, counts: []i64) i64 {
    if (counts[design.len] >= 0) {
        return counts[design.len];
    }

    var count: i64 = 0;
    for (patterns) |pattern| {
        if (mem.startsWith(u8, design, pattern)) {
            if (pattern.len == design.len) {
                count += 1;
            } else {
                count += countMatchesAux(patterns, design[pattern.len..], firstOnly, counts);
            }

            if (firstOnly and count > 0) {
                break;
            }
        }
    }
    counts[design.len] = count;
    return count;
}
