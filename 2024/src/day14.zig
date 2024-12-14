const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;

const input: []const u8 = @embedFile("input/day14.txt");

pub fn part1() !void {
    const width = 101;
    const height = 103;
    const seconds = 100;

    var quadrants: [4]i32 = .{ 0, 0, 0, 0 };

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

        var x = values[0];
        var y = values[1];
        const vx = values[2];
        const vy = values[3];

        x = @mod(x + (vx * seconds), width);
        y = @mod(y + (vy * seconds), height);

        const xHalfIndex = width / 2;
        const yHalfIndex = height / 2;

        if (x < xHalfIndex) {
            if (y < yHalfIndex) {
                quadrants[0] += 1;
            } else if (y > yHalfIndex) {
                quadrants[1] += 1;
            } else {
                // Center ones are ignored
            }
        } else if (x > xHalfIndex) {
            if (y < yHalfIndex) {
                quadrants[2] += 1;
            } else if (y > yHalfIndex) {
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

pub fn part2() !void {}
