// https://adventofcode.com/2024/day/18

const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const math = std.math;
const mem = std.mem;
const Order = math.Order;
const PriorityQueue = std.PriorityQueue;

const SearchNode = struct { x: i32, y: i32, cost: i32, heuristic: i32 };

var allocator: mem.Allocator = std.heap.page_allocator;

const input: []const u8 = @embedFile("input/day18.txt");

pub fn part1() !void {
    const w = 71;
    const h = 71;

    var map: [w * h]bool = undefined;
    @memset(map[0..], false);

    var remaining: i32 = 1024;

    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| : (remaining -= 1) {
        if (line.len == 0 or remaining <= 0) {
            break;
        }

        var valuesSplit = mem.splitScalar(u8, line, ',');
        const x = try fmt.parseInt(u32, valuesSplit.first(), 10);
        const y = try fmt.parseInt(u32, valuesSplit.next().?, 10);
        map[x + (y * w)] = true;
    }

    const score = try findBestCost(&map, w, h, 0, 0, w - 1, h - 1);

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{score});
}

pub fn part2() !void {
    const w = 71;
    const h = 71;

    var map: [w * h]bool = undefined;
    @memset(map[0..], false);

    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var valuesSplit = mem.splitScalar(u8, line, ',');
        const x = try fmt.parseInt(u32, valuesSplit.first(), 10);
        const y = try fmt.parseInt(u32, valuesSplit.next().?, 10);
        map[x + (y * w)] = true;

        const score = try findBestCost(&map, w, h, 0, 0, w - 1, h - 1);
        if (score < 0) {
            const out = io.getStdOut().writer();
            try out.print("{s}\n", .{line});
            break;
        }
    }
}

fn findBestCost(map: []const bool, w: i32, h: i32, xStart: i32, yStart: i32, xEnd: i32, yEnd: i32) !i32 {
    var minCosts = try allocator.alloc(i32, @intCast(w * h * 4));
    defer allocator.free(minCosts);
    @memset(minCosts, -1);

    var queue = PriorityQueue(SearchNode, ?bool, lessThan).init(allocator, null);
    defer queue.deinit();
    try queue.add(.{ .x = xStart, .y = yStart, .cost = 0, .heuristic = 0 });

    while (queue.removeOrNull()) |node| {
        const x = node.x;
        const y = node.y;

        if (x == xEnd and y == yEnd) {
            return node.cost;
        }

        const minCostsIndex: usize = @intCast(x + (y * w));
        const minCost = minCosts[minCostsIndex];
        if (node.cost < minCost or minCost < 0) {
            minCosts[minCostsIndex] = node.cost;
        } else {
            continue;
        }

        const cost = node.cost + 1;
        const children: [4]SearchNode = .{
            .{ .x = x + 1, .y = y, .cost = cost, .heuristic = 0 },
            .{ .x = x - 1, .y = y, .cost = cost, .heuristic = 0 },
            .{ .x = x, .y = y + 1, .cost = cost, .heuristic = 0 },
            .{ .x = x, .y = y - 1, .cost = cost, .heuristic = 0 },
        };
        var i: u32 = 0;
        while (i < children.len) : (i += 1) {
            var child = children[i];
            const x2 = child.x;
            const y2 = child.y;
            if (x2 >= 0 and x2 < w and y2 >= 0 and y2 < h and !map[@intCast(x2 + (y2 * w))]) {
                child.heuristic = cost + optimisticHeuristic(x2, y2, xEnd, yEnd);
                try queue.add(child);
            }
        }
    }
    return -1;
}

fn lessThan(_: ?bool, a: SearchNode, b: SearchNode) Order {
    // Order first by the heuristic low to high
    const hOrder = math.order(a.heuristic, b.heuristic);
    if (hOrder == Order.eq) {
        // If the heuristic is the same, order by the cost high to low (so nodes further down the path are prioritized)
        return math.order(b.cost, a.cost);
    }
    return hOrder;
}

fn optimisticHeuristic(x: i32, y: i32, xEnd: i32, yEnd: i32) i32 {
    return @intCast(@abs(xEnd - x) + @abs(yEnd - y));
}
