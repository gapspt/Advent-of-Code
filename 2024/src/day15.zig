const std = @import("std");
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;

const allocator: mem.Allocator = std.heap.page_allocator;

const robot = '@';
const box = 'O';
const wall = '#';
const empty = '.';

const left = '<';
const right = '>';
const up = '^';
const down = 'v';

const input: []const u8 = @embedFile("input/day15.txt");

pub fn part1() !void {
    var list = ArrayList([]u8).init(allocator);
    defer {
        for (list.items) |it| {
            allocator.free(it);
        }
        list.deinit();
    }

    var xRobot: i32 = 0;
    var yRobot: i32 = 0;

    var linesSplit = mem.splitScalar(u8, input, '\n');

    // Read the map
    var i: i32 = 0;
    while (linesSplit.next()) |line| : (i += 1) {
        if (line.len == 0) {
            break;
        }

        try list.append(try allocator.dupe(u8, line));

        if (mem.indexOfScalar(u8, line, robot)) |index| {
            xRobot = @intCast(index);
            yRobot = i;
        }
    }

    const map = list.items;

    // Read the movements
    while (linesSplit.next()) |line| {
        for (line) |direction| {
            var dx: i32 = 0;
            var dy: i32 = 0;
            switch (direction) {
                left => dx = -1,
                right => dx = 1,
                up => dy = -1,
                down => dy = 1,
                else => continue,
            }

            // Find the first wall or empty space
            var x = xRobot;
            var y = yRobot;
            while (true) {
                x += dx;
                y += dy;

                const c = map[@intCast(y)][@intCast(x)];
                if (c == wall) {
                    // Hit a wall, nothing to do
                    break;
                }
                if (c == empty) {
                    // Empty space, push the boxes in-between
                    map[@intCast(y)][@intCast(x)] = box;
                    map[@intCast(yRobot)][@intCast(xRobot)] = empty;
                    xRobot += dx;
                    yRobot += dy;
                    map[@intCast(yRobot)][@intCast(xRobot)] = robot;
                    break;
                }
            }
        }
    }

    var sum: i32 = 0;
    var y: i32 = 0;
    for (map) |row| {
        var x: i32 = 0;
        for (row) |c| {
            if (c == box) {
                sum += y + x;
            }
            x += 1;
        }
        y += 100;
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

pub fn part2() !void {}

fn print(map: [][]const u8) void {
    for (map) |row| {
        std.debug.print("{s}\n", .{row});
    }
}
