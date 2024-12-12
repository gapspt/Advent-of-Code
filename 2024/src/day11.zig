const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const AutoHashMap = std.AutoHashMap;

var allocator: mem.Allocator = std.heap.page_allocator;

const input: []const u8 = @embedFile("input/day11.txt");

var map: AutoHashMap(u64, []u64) = undefined;

pub fn part1() !void {
    try countStones(25);
}

pub fn part2() !void {
    try countStones(75);
}

fn countStones(times: u32) !void {
    map = AutoHashMap(u64, []u64).init(allocator);
    defer map.deinit();

    var sum: u64 = 0;

    var valuesSplit = mem.splitAny(u8, input, " \r\n");
    while (valuesSplit.next()) |valueStr| {
        if (valueStr.len == 0) {
            break;
        }

        const value = try fmt.parseInt(u64, valueStr, 10);
        sum += try countStone(value, times);
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

fn countStone(value: u64, times: u32) !u64 {
    if (times == 0) {
        return 1;
    }

    const getOrPut = try map.getOrPut(value);
    if (!getOrPut.found_existing) {
        getOrPut.value_ptr.* = try allocator.alloc(u64, times);
        @memset(getOrPut.value_ptr.*, 0);
    }
    var arr = getOrPut.value_ptr.*;
    if (arr.len < times) {
        const len = arr.len;
        arr = try allocator.alloc(u64, times);
        @memcpy(arr[0..len], getOrPut.value_ptr.*[0..len]);
        @memset(arr[len..], 0);
        allocator.free(getOrPut.value_ptr.*);
        getOrPut.value_ptr.* = arr;
    }

    const newTimes = times - 1;
    if (arr[newTimes] != 0) {
        return arr[newTimes];
    }

    var count: u64 = undefined;

    // - If the stone is engraved with the number 0, it is replaced by a stone engraved with the number 1.
    // - If the stone is engraved with a number that has an even number of digits, it is replaced by two stones.
    //   The left half of the digits are engraved on the new left stone, and the right half of the
    //   digits are engraved on the new right stone.
    //   (The new numbers don't keep extra leading zeroes: 1000 would become stones 10 and 0.)
    // - If none of the other rules apply, the stone is replaced by a new stone;
    //   the old stone's number multiplied by 2024 is engraved on the new stone.

    if (value == 0) {
        count = try countStone(1, newTimes);
    } else {
        var digits: u32 = 1;
        var v = value;
        while (v > 9) : (v = @divTrunc(v, 10)) {
            digits += 1;
        }

        if (digits % 2 == 0) {
            var value1: u64 = value;
            var value2: u64 = 0;

            const halfDigits = digits / 2;
            var mult: u64 = 1;
            var i: u32 = 0;
            while (i < halfDigits) : (i += 1) {
                value2 += (value1 % 10) * mult;
                value1 /= 10;
                mult *= 10;
            }

            count = try countStone(value1, newTimes) + try countStone(value2, newTimes);
        } else {
            count = try countStone(value * 2024, newTimes);
        }
    }

    arr[newTimes] = count;
    return arr[newTimes];
}
