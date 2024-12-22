// https://adventofcode.com/2024/day/21

const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;

const Position = struct { x: i8, y: i8 };

const input: []const u8 = @embedFile("input/day21.txt");

var allocator: mem.Allocator = undefined;

var cache: []u64 = undefined;

pub fn part1() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    allocator = gpa.allocator();
    defer _ = gpa.deinit();

    try calcSum(3);
}

pub fn part2() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    allocator = gpa.allocator();
    defer _ = gpa.deinit();

    try calcSum(26);
}

fn calcSum(numRobots: u8) !void {
    try createCache(numRobots);
    defer freeCache();

    var sum: u64 = 0;

    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var count: u64 = 0;
        var prevButtonRobot0: u8 = 'A';
        for (line) |c| {
            count += findMinPresses(numRobots, 0, prevButtonRobot0, c);
            prevButtonRobot0 = c;
        }

        sum += count * try fmt.parseInt(u32, line[0..(line.len - 1)], 10);
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

fn findMinPresses(numRobots: u8, robotIndex: u8, currentButton: u8, wantedButton: u8) u64 {
    const cacheIndex = getCacheIndex(robotIndex, currentButton, wantedButton);
    if (getFromCache(cacheIndex)) |value| {
        return value;
    }

    const firstRobot = robotIndex == 0;
    const lastRobot = robotIndex + 1 == numRobots;

    const getPosition: *const fn (u8) Position = if (firstRobot) &getPositionNumeric else &getPositionDirectional;

    const wantedPos = getPosition(wantedButton);
    const currentPos = getPosition(currentButton);

    const dist = @abs(wantedPos.x - currentPos.x) + @abs(wantedPos.y - currentPos.y);

    if (lastRobot or dist == 0) {
        return putInCache(cacheIndex, dist + 1);
    }

    const nextRobotIndex = robotIndex + 1;
    const nextWantedButtonX: u8 = if (currentPos.x < wantedPos.x) '>' else if (currentPos.x > wantedPos.x) '<' else 0;
    const nextWantedButtonY: u8 = if (currentPos.y < wantedPos.y) 'v' else if (currentPos.y > wantedPos.y) '^' else 0;

    if (nextWantedButtonX == 0) {
        return putInCache(cacheIndex, dist - 1 +
            findMinPresses(numRobots, nextRobotIndex, 'A', nextWantedButtonY) +
            findMinPresses(numRobots, nextRobotIndex, nextWantedButtonY, 'A'));
    }

    if (nextWantedButtonY == 0) {
        return putInCache(cacheIndex, dist - 1 +
            findMinPresses(numRobots, nextRobotIndex, 'A', nextWantedButtonX) +
            findMinPresses(numRobots, nextRobotIndex, nextWantedButtonX, 'A'));
    }

    const invalidPos: Position = .{ .x = 0, .y = if (firstRobot) 3 else 0 };

    var firstDoButtonX: u64 = 0;
    var firstDoButtonY: u64 = 0;
    var min: u64 = 0;
    if (currentPos.y != invalidPos.y or wantedPos.x != invalidPos.x) {
        firstDoButtonX =
            findMinPresses(numRobots, nextRobotIndex, 'A', nextWantedButtonX) +
            findMinPresses(numRobots, nextRobotIndex, nextWantedButtonX, nextWantedButtonY) +
            findMinPresses(numRobots, nextRobotIndex, nextWantedButtonY, 'A');
        min = firstDoButtonX;
    }
    if (currentPos.x != invalidPos.x or wantedPos.y != invalidPos.y) {
        firstDoButtonY =
            findMinPresses(numRobots, nextRobotIndex, 'A', nextWantedButtonY) +
            findMinPresses(numRobots, nextRobotIndex, nextWantedButtonY, nextWantedButtonX) +
            findMinPresses(numRobots, nextRobotIndex, nextWantedButtonX, 'A');
        if (min == 0 or firstDoButtonY < min) {
            min = firstDoButtonY;
        }
    }
    return putInCache(cacheIndex, dist - 2 + min);
}

fn getPositionNumeric(b: u8) Position {
    return switch (b) {
        '7' => .{ .x = 0, .y = 0 },
        '8' => .{ .x = 1, .y = 0 },
        '9' => .{ .x = 2, .y = 0 },
        '4' => .{ .x = 0, .y = 1 },
        '5' => .{ .x = 1, .y = 1 },
        '6' => .{ .x = 2, .y = 1 },
        '1' => .{ .x = 0, .y = 2 },
        '2' => .{ .x = 1, .y = 2 },
        '3' => .{ .x = 2, .y = 2 },
        '0' => .{ .x = 1, .y = 3 },
        'A' => .{ .x = 2, .y = 3 },
        else => @panic("Invalid numeric button"),
    };
}

fn getPositionDirectional(c: u8) Position {
    return switch (c) {
        '^' => .{ .x = 1, .y = 0 },
        'A' => .{ .x = 2, .y = 0 },
        '<' => .{ .x = 0, .y = 1 },
        'v' => .{ .x = 1, .y = 1 },
        '>' => .{ .x = 2, .y = 1 },
        else => @panic("Invalid directional button"),
    };
}

fn createCache(numRobots: u8) !void {
    cache = try allocator.alloc(u64, @as(u16, numRobots) << 8);
    @memset(cache, 0);
}

fn freeCache() void {
    allocator.free(cache);
}

fn getCacheIndex(robotIndex: u8, currentButton: u8, wantedButton: u8) u16 {
    const r: u16 = robotIndex;
    const c: u16 = getButtonCacheIndex(currentButton);
    const w: u16 = getButtonCacheIndex(wantedButton);
    return (r << 8) | (c << 4) | w;
}

fn getFromCache(cacheIndex: u16) ?u64 {
    const val = cache[cacheIndex];
    return if (val != 0) val else null;
}

fn putInCache(cacheIndex: u16, val: u64) u64 {
    cache[cacheIndex] = val;
    return val;
}

fn getButtonCacheIndex(b: u8) u4 {
    return switch (b) {
        'A' => 0,
        '1' => 1,
        '2' => 2,
        '3' => 3,
        '4' => 4,
        '5' => 5,
        '6' => 6,
        '7' => 7,
        '8' => 8,
        '9' => 9,
        '0' => 10,
        '^' => 1,
        '<' => 2,
        'v' => 3,
        '>' => 4,
        else => @panic("Invalid button"),
    };
}
