// https://adventofcode.com/2024/day/25

const std = @import("std");
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;

const input: []const u8 = @embedFile("input/day25.txt");

var allocator: mem.Allocator = undefined;

pub fn part1() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var keys = ArrayList([5]i32).init(allocator);
    var locks = ArrayList([5]i32).init(allocator);
    defer keys.deinit();
    defer locks.deinit();

    var pins: [5]i32 = .{0} ** 5;
    var pinsRead: u32 = 0;
    var readingLock = false;
    var readingKey = false;
    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        if (!readingKey and !readingLock) {
            if (line[0] == '.') {
                readingKey = true;
            } else if (line[0] == '#') {
                readingLock = true;
            } else {
                @panic("Invalid input");
            }

            @memset(pins[0..], 0);
            pinsRead = 0;
            continue;
        }

        if (pinsRead == 5) {
            if (readingKey) {
                try keys.append(pins);
                readingKey = false;
            } else if (readingLock) {
                try locks.append(pins);
                readingLock = false;
            } else {
                @panic("Invalid program logic");
            }
            continue;
        }

        var i: u32 = 0;
        while (i < pins.len) : (i += 1) {
            if ((readingKey and line[i] == '#') or (readingLock and line[i] == '.')) {
                pins[i] += 1;
            }
        }

        pinsRead += 1;
    }

    var sum: i32 = 0;

    for (keys.items) |key| {
        for (locks.items) |lock| {
            var fits = true;
            var i: u32 = 0;
            while (i < key.len) : (i += 1) {
                if (key[i] > lock[i]) {
                    fits = false;
                    break;
                }
            }
            if (fits) {
                sum += 1;
            }
        }
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

pub fn part2() !void {
    const out = io.getStdOut().writer();
    try out.print("Merry Christmas!\n", .{});
}
