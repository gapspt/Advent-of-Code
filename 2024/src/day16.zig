const std = @import("std");
const io = std.io;
const math = std.math;
const mem = std.mem;
const Order = math.Order;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const PriorityQueue = std.PriorityQueue;

const Direction = enum { north, south, east, west };

const SearchNode = struct { x: i32, y: i32, dir: Direction, cost: i32, heuristic: i32 };

var allocator: mem.Allocator = std.heap.page_allocator;

const input: []const u8 = @embedFile("input/day16.txt");

pub fn part1() !void {
    try findBestPath(false);
}

pub fn part2() !void {
    try findBestPath(true);
}

fn findBestPath(findAllBestLocations: bool) !void {
    var list = ArrayList([]const u8).init(allocator);
    defer list.deinit();

    const dirStart = Direction.east;
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

    var score = try findBestCost(list.items, dirStart, xStart, yStart, xEnd, yEnd);
    if (findAllBestLocations) {
        score = try findBestLocations(list.items, dirStart, xStart, yStart, xEnd, yEnd, score);
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{score});
}

fn findBestCost(map: [][]const u8, dirStart: Direction, xStart: i32, yStart: i32, xEnd: i32, yEnd: i32) !i32 {
    const h: i32 = @intCast(map.len);
    const w: i32 = @intCast(map[0].len);
    const a: i32 = h * w;

    var minCosts = try allocator.alloc(i32, @intCast(w * h * 4));
    defer allocator.free(minCosts);
    @memset(minCosts, -1);

    var queue = PriorityQueue(SearchNode, ?bool, lessThan).init(allocator, null);
    defer queue.deinit();
    try queue.add(.{ .x = xStart, .y = yStart, .dir = dirStart, .cost = 0, .heuristic = 0 });

    while (queue.removeOrNull()) |node| {
        if (node.x == xEnd and node.y == yEnd) {
            return node.cost;
        }

        const minCostsIndex: usize = @intCast(@intFromEnum(node.dir) * a + node.x * h + node.y);
        const minCost = minCosts[minCostsIndex];
        if (node.cost < minCost or minCost < 0) {
            minCosts[minCostsIndex] = node.cost;
        } else {
            continue;
        }

        var x = node.x;
        var y = node.y;
        var dir1: Direction = Direction.north;
        var dir2: Direction = Direction.south;
        if (node.dir == Direction.north or node.dir == Direction.south) {
            dir1 = Direction.east;
            dir2 = Direction.west;
        }
        var cost = node.cost + 1000;
        const heuristic1 = optimisticHeuristic(x, y, dir1, xEnd, yEnd);
        const heuristic2 = optimisticHeuristic(x, y, dir2, xEnd, yEnd);
        try queue.add(.{ .x = x, .y = y, .dir = dir1, .cost = cost, .heuristic = cost + heuristic1 });
        try queue.add(.{ .x = x, .y = y, .dir = dir2, .cost = cost, .heuristic = cost + heuristic2 });

        switch (node.dir) {
            Direction.north => y += -1,
            Direction.south => y += 1,
            Direction.east => x += 1,
            Direction.west => x += -1,
        }
        if (x >= 0 and x < w and y >= 0 and y < h and map[@intCast(y)][@intCast(x)] != '#') {
            const heuristic3 = optimisticHeuristic(x, y, node.dir, xEnd, yEnd);
            cost = node.cost + 1;
            try queue.add(.{ .x = x, .y = y, .dir = node.dir, .cost = cost, .heuristic = cost + heuristic3 });
        }
    }
    return -1;
}

fn findBestLocations(
    map: [][]const u8,
    dirStart: Direction,
    xStart: i32,
    yStart: i32,
    xEnd: i32,
    yEnd: i32,
    bestCost: i32,
) !i32 {
    const h: i32 = @intCast(map.len);
    const w: i32 = @intCast(map[0].len);
    const a: i32 = h * w;

    const minCosts = try allocator.alloc(i32, @intCast(w * h * 4));
    defer allocator.free(minCosts);
    @memset(minCosts, -1);

    var bestLocations = std.AutoHashMap(i32, bool).init(allocator);
    defer bestLocations.deinit();

    const node = .{ .x = xStart, .y = yStart, .dir = dirStart, .cost = 0, .heuristic = 0 };

    _ = try findBestLocationsVisit(map, h, w, a, minCosts, &bestLocations, xEnd, yEnd, bestCost, node);

    return @intCast(bestLocations.count());
}

fn findBestLocationsVisit(
    map: [][]const u8,
    h: i32,
    w: i32,
    a: i32,
    minCosts: []i32,
    bestLocations: *AutoHashMap(i32, bool),
    xEnd: i32,
    yEnd: i32,
    bestCost: i32,
    node: SearchNode,
) !bool {
    if (node.heuristic > bestCost) {
        return false;
    }

    const minCostsIndex: usize = @intCast(@intFromEnum(node.dir) * a + node.x * h + node.y);
    const minCost = minCosts[minCostsIndex];
    if (node.cost < minCost or minCost < 0) {
        minCosts[minCostsIndex] = node.cost;
    } else if (node.cost > minCost) {
        return false;
    }

    if (node.x == xEnd and node.y == yEnd) {
        try bestLocations.put(node.x * h + node.y, true);
        return true;
    }

    var found = false;

    var x = node.x;
    var y = node.y;
    var dir1: Direction = Direction.north;
    var dir2: Direction = Direction.south;
    if (node.dir == Direction.north or node.dir == Direction.south) {
        dir1 = Direction.east;
        dir2 = Direction.west;
    }
    var cost = node.cost + 1000;
    const heuristic1 = optimisticHeuristic(x, y, dir1, xEnd, yEnd);
    const heuristic2 = optimisticHeuristic(x, y, dir2, xEnd, yEnd);
    const child1: SearchNode = .{ .x = x, .y = y, .dir = dir1, .cost = cost, .heuristic = cost + heuristic1 };
    const child2: SearchNode = .{ .x = x, .y = y, .dir = dir2, .cost = cost, .heuristic = cost + heuristic2 };
    if (try findBestLocationsVisit(map, h, w, a, minCosts, bestLocations, xEnd, yEnd, bestCost, child1)) {
        found = true;
    }
    if (try findBestLocationsVisit(map, h, w, a, minCosts, bestLocations, xEnd, yEnd, bestCost, child2)) {
        found = true;
    }

    switch (node.dir) {
        Direction.north => y += -1,
        Direction.south => y += 1,
        Direction.east => x += 1,
        Direction.west => x += -1,
    }
    if (x >= 0 and x < w and y >= 0 and y < h and map[@intCast(y)][@intCast(x)] != '#') {
        const heuristic3 = optimisticHeuristic(x, y, node.dir, xEnd, yEnd);
        cost = node.cost + 1;
        const child3: SearchNode = .{ .x = x, .y = y, .dir = node.dir, .cost = cost, .heuristic = cost + heuristic3 };
        if (try findBestLocationsVisit(map, h, w, a, minCosts, bestLocations, xEnd, yEnd, bestCost, child3)) {
            found = true;
        }
    }

    if (found) {
        try bestLocations.put(node.x * h + node.y, true);
    }

    return found;
}

fn lessThan(_: ?bool, a: SearchNode, b: SearchNode) Order {
    return math.order(a.heuristic, b.heuristic);
}

fn optimisticHeuristic(x: i32, y: i32, dir: Direction, xEnd: i32, yEnd: i32) i32 {
    const dist: i32 = @intCast(@abs(xEnd - x) + @abs(yEnd - y));

    if (dist == 0) {
        return 0;
    }

    return dist + switch (dir) {
        Direction.north => @as(i32, if (y < yEnd) 2000 else if (x == xEnd) 0 else 1000),
        Direction.south => @as(i32, if (y > yEnd) 2000 else if (x == xEnd) 0 else 1000),
        Direction.east => @as(i32, if (x > xEnd) 2000 else if (y == yEnd) 0 else 1000),
        Direction.west => @as(i32, if (x < xEnd) 2000 else if (y == yEnd) 0 else 1000),
    };
}
