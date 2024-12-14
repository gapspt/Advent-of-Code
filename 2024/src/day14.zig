const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;

const PositionVelocity = struct { x: i32, y: i32, vx: i32, vy: i32 };

const allocator: mem.Allocator = std.heap.page_allocator;

const input: []const u8 = @embedFile("input/day14.txt");

const width = 101;
const height = 103;

var list: ArrayList(PositionVelocity) = undefined;

pub fn part1() !void {
    const seconds = 100;

    try readList();
    defer freeList();

    simulate(seconds);

    var quadrants: [4]i32 = .{ 0, 0, 0, 0 };
    const xHalfIndex = width / 2;
    const yHalfIndex = height / 2;

    for (list.items) |it| {
        if (it.x < xHalfIndex) {
            if (it.y < yHalfIndex) {
                quadrants[0] += 1;
            } else if (it.y > yHalfIndex) {
                quadrants[1] += 1;
            } else {
                // Center ones are ignored
            }
        } else if (it.x > xHalfIndex) {
            if (it.y < yHalfIndex) {
                quadrants[2] += 1;
            } else if (it.y > yHalfIndex) {
                quadrants[3] += 1;
            } else {
                // Center ones are ignored
            }
        } else {
            // Center ones are ignored
        }
    }

    const sum = quadrants[0] * quadrants[1] * quadrants[2] * quadrants[3];

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

pub fn part2() !void {
    const initialSeconds = 0;

    try readList();
    defer freeList();

    const in = io.getStdIn().reader();
    const out = io.getStdOut().writer();

    var matrix: [height][width]bool = undefined;

    var seconds: i32 = initialSeconds;
    while (true) : (seconds += 1) {
        if (seconds == initialSeconds) {
            simulate(initialSeconds);
        } else {
            simulate(1);
        }

        var i: u32 = 0;
        while (i < matrix.len) : (i += 1) {
            @memset(matrix[i][0..], false);
        }

        for (list.items) |it| {
            matrix[@intCast(it.y)][@intCast(it.x)] = true;
        }

        // Check if there are a few in a row
        // Note: The value of 8 is here and it is known to be accurate only after finding the solution.
        //       Some different patterns were tried before arriving to a good one.
        const pattern: [8]bool = .{ true, true, true, true, true, true, true, true };
        var found = false;
        for (matrix) |row| {
            if (mem.indexOf(bool, row[0..], pattern[0..])) |_| {
                found = true;
            }
        }
        if (!found) {
            continue;
        }

        // Print it for human visual inspection
        for (matrix) |row| {
            for (row) |v| {
                try out.writeByte(if (v) '#' else ' ');
            }
            try out.writeByte('\n');
        }
        try out.print("\nAfter {} seconds.\nPress enter to continue...\n", .{seconds});

        // Wait for some input to continue
        while (true) {
            if (in.readByte()) |c| {
                if (c == '\n') {
                    break;
                }
            } else |_| {
                return;
            }
        }
    }
}

fn readList() !void {
    list = ArrayList(PositionVelocity).init(allocator);

    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| {
        if (line.len == 0) {
            break;
        }

        const numeric = "-0123456789";
        var values: [4]i32 = undefined;
        var i: u32 = 0;
        var pos: usize = 0;
        while (i < values.len) : (i += 1) {
            const start = mem.indexOfAnyPos(u8, line, pos, numeric).?;
            const end = mem.indexOfNonePos(u8, line, start + 1, numeric) orelse line.len;
            values[i] = try fmt.parseInt(i32, line[start..end], 10);
            pos = end + 1;
        }

        try list.append(.{
            .x = @mod(values[0], width),
            .y = @mod(values[1], height),
            .vx = @mod(values[2], width),
            .vy = @mod(values[3], height),
        });
    }
}

fn freeList() void {
    list.deinit();
}

fn simulate(seconds: i32) void {
    const items = list.items;
    var i: u32 = 0;
    while (i < items.len) : (i += 1) {
        const it = &items[i];
        it.x = @mod(it.x + (it.vx * seconds), width);
        it.y = @mod(it.y + (it.vy * seconds), height);
    }
}
