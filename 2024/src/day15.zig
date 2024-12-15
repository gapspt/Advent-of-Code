const std = @import("std");
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;

const allocator: mem.Allocator = std.heap.page_allocator;

const robot = '@';
const box = 'O';
const boxLeft = '[';
const boxRight = ']';
const wall = '#';
const empty = '.';

const left = '<';
const right = '>';
const up = '^';
const down = 'v';

const input: []const u8 = @embedFile("input/day15.txt");

pub fn part1() !void {
    try sumCoordinates(false);
}

pub fn part2() !void {
    try sumCoordinates(true);
}

fn sumCoordinates(wideBoxes: bool) !void {
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

        var row: []u8 = undefined;
        if (wideBoxes) {
            row = try allocator.alloc(u8, line.len * 2);
            var j: u32 = 0;
            while (j < line.len) : (j += 1) {
                const c = line[j];
                switch (c) {
                    box => {
                        row[j * 2] = boxLeft;
                        row[j * 2 + 1] = boxRight;
                    },
                    else => {
                        row[j * 2] = c;
                        row[j * 2 + 1] = c;
                    },
                }
            }
        } else {
            row = try allocator.dupe(u8, line);
        }

        try list.append(row);

        if (mem.indexOfScalar(u8, line, robot)) |index| {
            xRobot = @intCast(index);
            yRobot = i;
            if (wideBoxes) {
                xRobot *= 2;
                row[@intCast(xRobot + 1)] = empty;
            }
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

            if (pushBox(map, xRobot, yRobot, dx, dy, false)) {
                _ = pushBox(map, xRobot, yRobot, dx, dy, true);
                xRobot += dx;
                yRobot += dy;
            }
        }
    }

    var sum: i32 = 0;
    var y: i32 = 0;
    for (map) |row| {
        var x: i32 = 0;
        for (row) |c| {
            if (c == box or c == boxLeft) {
                sum += y + x;
            }
            x += 1;
        }
        y += 100;
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

fn pushBox(map: [][]u8, x: i32, y: i32, dx: i32, dy: i32, applyChanges: bool) bool {
    const c = map[@intCast(y)][@intCast(x)];
    switch (c) {
        robot, box => {
            const success = pushBox(map, x + dx, y + dy, dx, dy, applyChanges);
            if (success and applyChanges) {
                map[@intCast(y)][@intCast(x)] = empty;
                map[@intCast(y + dy)][@intCast(x + dx)] = c;
            }
            return success;
        },
        boxLeft => {
            var success = false;
            if (dy == 0) {
                if (dx < 0) {
                    success = pushBox(map, x + dx, y + dy, dx, dy, applyChanges);
                } else {
                    success = pushBox(map, x + 1 + dx, y + dy, dx, dy, applyChanges);
                }
            } else {
                success = pushBox(map, x + dx, y + dy, dx, dy, applyChanges) and
                    pushBox(map, x + 1 + dx, y + dy, dx, dy, applyChanges);
            }
            if (success and applyChanges) {
                map[@intCast(y)][@intCast(x)] = empty;
                map[@intCast(y)][@intCast(x + 1)] = empty;
                map[@intCast(y + dy)][@intCast(x + dx)] = c;
                map[@intCast(y + dy)][@intCast(x + 1 + dx)] = boxRight;
            }
            return success;
        },
        boxRight => return pushBox(map, x - 1, y, dx, dy, applyChanges),
        wall => return false,
        else => return true,
    }
    return false;
}

fn print(map: [][]const u8) void {
    for (map) |row| {
        std.debug.print("{s}\n", .{row});
    }
}
