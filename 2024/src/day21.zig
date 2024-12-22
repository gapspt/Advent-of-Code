// https://adventofcode.com/2024/day/21

const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;

const Position = struct { x: i8, y: i8 };

const input: []const u8 = @embedFile("input/day21.txt");

pub fn part1() !void {
    var sum: u64 = 0;

    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var count: u64 = 0;
        var prevButtonRobot0: u8 = 'A';
        for (line) |c| {
            count += findMinPresses(0, prevButtonRobot0, c);
            prevButtonRobot0 = c;
        }

        sum += count * try fmt.parseInt(u32, line[0..(line.len - 1)], 10);
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

pub fn part2() !void {}

fn findMinPresses(robotIndex: u8, currentButton: u8, wantedButton: u8) u64 {
    const firstRobot = robotIndex == 0;
    const lastRobot = robotIndex == 2;

    const getPosition: *const fn (u8) Position = if (firstRobot) &getPositionNumeric else &getPositionDirectional;

    const wantedPos = getPosition(wantedButton);
    const currentPos = getPosition(currentButton);

    const dist = @abs(wantedPos.x - currentPos.x) + @abs(wantedPos.y - currentPos.y);

    if (lastRobot or dist == 0) {
        return dist + 1;
    }

    const nextRobotIndex = robotIndex + 1;
    const nextWantedButtonX: u8 = if (currentPos.x < wantedPos.x) '>' else if (currentPos.x > wantedPos.x) '<' else 0;
    const nextWantedButtonY: u8 = if (currentPos.y < wantedPos.y) 'v' else if (currentPos.y > wantedPos.y) '^' else 0;

    if (nextWantedButtonX == 0) {
        return dist - 1 +
            findMinPresses(nextRobotIndex, 'A', nextWantedButtonY) +
            findMinPresses(nextRobotIndex, nextWantedButtonY, 'A');
    }

    if (nextWantedButtonY == 0) {
        return dist - 1 +
            findMinPresses(nextRobotIndex, 'A', nextWantedButtonX) +
            findMinPresses(nextRobotIndex, nextWantedButtonX, 'A');
    }

    const invalidPos: Position = .{ .x = 0, .y = if (firstRobot) 3 else 0 };

    var firstDoButtonX: u64 = 0;
    var firstDoButtonY: u64 = 0;
    var min: u64 = 0;
    if (currentPos.y != invalidPos.y or wantedPos.x != invalidPos.x) {
        firstDoButtonX =
            findMinPresses(nextRobotIndex, 'A', nextWantedButtonX) +
            findMinPresses(nextRobotIndex, nextWantedButtonX, nextWantedButtonY) +
            findMinPresses(nextRobotIndex, nextWantedButtonY, 'A');
        min = firstDoButtonX;
    }
    if (currentPos.x != invalidPos.x or wantedPos.y != invalidPos.y) {
        firstDoButtonY =
            findMinPresses(nextRobotIndex, 'A', nextWantedButtonY) +
            findMinPresses(nextRobotIndex, nextWantedButtonY, nextWantedButtonX) +
            findMinPresses(nextRobotIndex, nextWantedButtonX, 'A');
        if (min == 0 or firstDoButtonY < min) {
            min = firstDoButtonY;
        }
    }
    return dist - 2 + min;
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
