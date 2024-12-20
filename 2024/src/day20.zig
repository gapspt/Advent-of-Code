// https://adventofcode.com/2024/day/20

const std = @import("std");
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;

var allocator: mem.Allocator = std.heap.page_allocator;

const input: []const u8 = @embedFile("input/day20.txt");

pub fn part1() !void {
    try printCheats(2, 100);
}

pub fn part2() !void {
    try printCheats(20, 100);
}

fn printCheats(jumpLen: i32, minCostSave: i32) !void {
    var list = ArrayList([]const u8).init(allocator);
    defer list.deinit();

    var xStart: i32 = 0;
    var yStart: i32 = 0;
    var xEnd: i32 = 0;
    var yEnd: i32 = 0;

    var y: i32 = 0;
    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| : (y += 1) {
        if (line.len == 0) {
            break;
        }

        try list.append(line);

        if (mem.indexOfScalar(u8, line, 'S')) |index| {
            xStart = @intCast(index);
            yStart = y;
        }
        if (mem.indexOfScalar(u8, line, 'E')) |index| {
            xEnd = @intCast(index);
            yEnd = y;
        }
    }

    const map = list.items;
    const h: i32 = @intCast(map.len);
    const w: i32 = @intCast(map[0].len);

    const costs = try findCosts(map, w, h, xStart, yStart, xEnd, yEnd);
    defer allocator.free(costs);

    const cheats = findCheats(costs, w, h, jumpLen, minCostSave);

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{cheats});
}

fn findCosts(map: [][]const u8, w: i32, h: i32, xStart: i32, yStart: i32, xEnd: i32, yEnd: i32) ![]i32 {
    const costs = try allocator.alloc(i32, @intCast(w * h));
    @memset(costs, -1);

    var costIndex: u32 = @intCast(xStart + (yStart * w));
    costs[costIndex] = 0;

    var x = xStart;
    var y = yStart;
    var xPrevious = x;
    var yPrevious = y;
    var cost: i32 = 0;
    while (x != xEnd or y != yEnd) {
        var possiblePaths: i32 = 0;
        var xNext = x;
        var yNext = y;
        if (xPrevious != x + 1 and map[@intCast(y)][@intCast(x + 1)] != '#') {
            possiblePaths += 1;
            xNext += 1;
        }
        if (xPrevious != x - 1 and map[@intCast(y)][@intCast(x - 1)] != '#') {
            possiblePaths += 1;
            xNext -= 1;
        }
        if (yPrevious != y + 1 and map[@intCast(y + 1)][@intCast(x)] != '#') {
            possiblePaths += 1;
            yNext += 1;
        }
        if (yPrevious != y - 1 and map[@intCast(y - 1)][@intCast(x)] != '#') {
            possiblePaths += 1;
            yNext -= 1;
        }

        costIndex = @intCast(xNext + (yNext * w));

        if (possiblePaths != 1 or costs[costIndex] != -1) {
            @panic("Invalid input");
        }

        cost += 1;
        costs[costIndex] = cost;

        xPrevious = x;
        yPrevious = y;
        x = xNext;
        y = yNext;
    }

    return costs;
}

fn findCheats(costs: []const i32, w: i32, h: i32, jumpLen: i32, minCostSave: i32) i32 {
    var cheats: i32 = 0;
    var y: i32 = 0;
    while (y < h) : (y += 1) {
        var x: i32 = 0;
        while (x < w) : (x += 1) {
            const cost = costs[@intCast(x + (y * w))];
            if (cost < 0) {
                continue;
            }

            const xMax = @min(x + jumpLen, w - 1);
            const yMax = @min(y + jumpLen, h - 1);

            var y2 = @max(0, y - jumpLen);
            while (y2 <= yMax) : (y2 += 1) {
                const dy = @abs(y2 - y);

                var x2 = @max(0, x - jumpLen);
                while (x2 <= xMax) : (x2 += 1) {
                    const d: i32 = @intCast(@abs(x2 - x) + dy);
                    if (d > jumpLen) {
                        continue;
                    }

                    if (costs[@intCast(x2 + (y2 * w))] - cost - d >= minCostSave) {
                        cheats += 1;
                    }
                }
            }
        }
    }
    return cheats;
}
