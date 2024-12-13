const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const math = std.math;
const mem = std.mem;
const Order = math.Order;
const PriorityQueue = std.PriorityQueue;

const PointDistanceCost = struct { x: i32, y: i32, distance: i32, cost: i32 };
const SearchNode = struct { x: i32, y: i32, cost: i32, heuristic: i32 };

var allocator: mem.Allocator = std.heap.page_allocator;

const input: []const u8 = @embedFile("input/day13.txt");

pub fn part1() !void {
    var sum: i64 = 0;

    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var l = line;
        var options: [3]PointDistanceCost = undefined;
        var i: u32 = 0;
        while (i < options.len) : (i += 1) {
            const ix = mem.indexOfScalar(u8, l, 'X').? + 2;
            const ic = mem.indexOfScalarPos(u8, l, ix, ',').?;
            const iy = mem.indexOfScalarPos(u8, l, ic + 1, 'Y').? + 2;

            const x = try fmt.parseInt(i32, l[ix..ic], 10);
            const y = try fmt.parseInt(i32, l[iy..], 10);

            options[i] = .{ .x = x, .y = y, .distance = x + y, .cost = 0 };

            l = linesSplit.next().?;
        }

        // Fill in the costs manually
        options[0].cost = 3;
        options[1].cost = 1;

        // The last one is the prize location
        const p = options[options.len - 1];

        const cost = try findBestCost(options[0..2], p.x, p.y);
        if (cost > 0) {
            std.debug.print("Found minimum cost: {}\n", .{cost});
        } else {
            std.debug.print("No cost found\n", .{});
        }
        sum += cost;
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

pub fn part2() !void {}

fn findBestCost(options: []PointDistanceCost, px: i32, py: i32) !i32 {
    var minCosts = try allocator.alloc(i32, @intCast(px * py));
    defer allocator.free(minCosts);
    @memset(minCosts, -1);

    var queue = PriorityQueue(SearchNode, ?bool, lessThan).init(allocator, null);
    defer queue.deinit();
    try queue.add(.{ .x = 0, .y = 0, .cost = 0, .heuristic = 0 });

    while (queue.removeOrNull()) |node| {
        if (node.x == px and node.y == py) {
            return node.cost;
        }

        const minCost = minCosts[@intCast(node.x * py + node.y)];
        if (node.cost < minCost or minCost < 0) {
            minCosts[@intCast(node.x * py + node.y)] = node.cost;
        } else {
            continue;
        }

        for (options) |option| {
            const x = node.x + option.x;
            const y = node.y + option.y;
            if (x > px or y > py) {
                continue;
            }

            if (try optimisticHeuristic(options, px - x, py - y)) |h| {
                const cost = node.cost + option.cost;
                try queue.add(.{ .x = x, .y = y, .cost = cost, .heuristic = cost + h });
            }
        }
    }
    return 0;
}

fn lessThan(_: ?bool, a: SearchNode, b: SearchNode) Order {
    return math.order(a.heuristic, b.heuristic);
}

fn optimisticHeuristic(options: []PointDistanceCost, px: i32, py: i32) !?i32 {
    const pDistance = px + py;
    if (pDistance == 0) {
        return 0;
    }

    var minCost: i32 = -1;
    for (options) |option| {
        if (option.x > px or option.y > py) {
            continue;
        }
        const cost = option.cost * @divTrunc(pDistance, option.distance);
        if (cost < minCost or minCost < 0) {
            minCost = cost;
        }
    }

    if (minCost >= 0) {
        return minCost;
    } else {
        return null;
    }
}
