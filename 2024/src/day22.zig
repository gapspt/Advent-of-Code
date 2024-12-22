// https://adventofcode.com/2024/day/22

const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;

const input: []const u8 = @embedFile("input/day22.txt");

pub fn part1() !void {
    const secretEvolveTimes = 2000;

    var sum: u64 = 0;

    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var secret = try fmt.parseInt(u32, line, 10);

        var i: u32 = 0;
        while (i < secretEvolveTimes) : (i += 1) {
            secret = evolveSecret(secret);
        }

        sum += secret;
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

pub fn part2() !void {}

fn evolveSecret(secret: u32) u32 {
    var result: u32 = secret;
    result = (result ^ (result << 6)) & 0xFFFFFF;
    result = (result ^ (result >> 5)) & 0xFFFFFF;
    result = (result ^ (result << 11)) & 0xFFFFFF;
    return result;
}
