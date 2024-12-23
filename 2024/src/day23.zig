// https://adventofcode.com/2024/day/23

const std = @import("std");
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const StringArrayHashMap = std.StringArrayHashMap;

const input: []const u8 = @embedFile("input/day23.txt");

var allocator: mem.Allocator = undefined;

pub fn part1() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var names = StringArrayHashMap(u32).init(allocator);
    defer names.deinit();
    var connections = ArrayList([2]u32).init(allocator);
    defer connections.deinit();

    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var valueSplit = mem.splitScalar(u8, line, '-');

        const aName = valueSplit.first();
        const aEntry = try names.getOrPutValue(aName, @intCast(names.count()));
        const a = aEntry.value_ptr.*;

        const bName = valueSplit.next().?;
        const bEntry = try names.getOrPutValue(bName, @intCast(names.count()));
        const b = bEntry.value_ptr.*;

        try connections.append(.{ a, b });
    }

    const namesArray = names.iterator().keys;
    const count = names.count();

    var connectionMap = try allocator.alloc(bool, count * count);
    defer allocator.free(connectionMap);

    for (connections.items) |connection| {
        connectionMap[connection[0] * count + connection[1]] = true;
        connectionMap[connection[1] * count + connection[0]] = true;
    }

    var sum: i32 = 0;

    var i: u32 = 0;
    while (i < count) : (i += 1) {
        const iIndexMult = i * count;

        var j: u32 = i + 1;
        while (j < count) : (j += 1) {
            if (!connectionMap[iIndexMult + j]) {
                continue;
            }

            const jIndexMult = j * count;

            var k: u32 = j + 1;
            while (k < count) : (k += 1) {
                if (connectionMap[iIndexMult + k] and connectionMap[jIndexMult + k] and
                    (namesArray[i][0] == 't' or namesArray[j][0] == 't' or namesArray[k][0] == 't'))
                {
                    sum += 1;
                }
            }
        }
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

pub fn part2() !void {}
