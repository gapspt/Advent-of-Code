// https://adventofcode.com/2024/day/22

const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;

const input: []const u8 = @embedFile("input/day22.txt");

const secretEvolveTimes = 2000;

pub fn part1() !void {
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

pub fn part2() !void {
    const pricesLen = 4;
    const iLastPrice = pricesLen - 1;

    // Note: This only works this way because we know that the sequence is small enough, higher values will break this.
    // (4 prices, 5 bits each, 20 bits total, 1M values, 4 MB of memory space)
    var sequencesValues: [1 << (pricesLen * 5)]i32 = undefined;
    var sequencesSeen: [1 << (pricesLen * 5)]bool = undefined;
    @memset(sequencesValues[0..], 0);

    var prices: [pricesLen]i32 = undefined;
    var changes: [pricesLen]i32 = undefined;

    var maxValue: i32 = 0;

    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| {
        if (line.len == 0) {
            break;
        }

        @memset(sequencesSeen[0..], false);

        var secret = try fmt.parseInt(u32, line, 10);

        prices[iLastPrice] = @intCast(secret % 10);

        var i: u32 = 0;
        while (i < secretEvolveTimes) : (i += 1) {
            secret = evolveSecret(secret);

            var j: u32 = 1;
            while (j < pricesLen) : (j += 1) {
                prices[j - 1] = prices[j];
                changes[j - 1] = changes[j];
            }
            prices[iLastPrice] = @intCast(secret % 10);
            changes[iLastPrice] = prices[iLastPrice] - prices[iLastPrice - 1];

            if (i < pricesLen) {
                continue;
            }

            var index: u32 = 0;
            j = 0;
            while (j < pricesLen) : (j += 1) {
                index = (index << 5) | @as(u5, @intCast(changes[j] & 0x1F));
            }
            if (sequencesSeen[index]) {
                continue;
            }
            sequencesSeen[index] = true;
            sequencesValues[index] += prices[iLastPrice];

            maxValue = @max(sequencesValues[index], maxValue);
        }
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{maxValue});
}

fn evolveSecret(secret: u32) u32 {
    var result: u32 = secret;
    result = (result ^ (result << 6)) & 0xFFFFFF;
    result = (result ^ (result >> 5)) & 0xFFFFFF;
    result = (result ^ (result << 11)) & 0xFFFFFF;
    return result;
}
