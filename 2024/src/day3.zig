const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;

const regex = @import("regex");

const allocator = std.heap.page_allocator;

pub fn part1() !void {
    const input: []const u8 = @embedFile("input/day3.txt");

    var sum: i64 = 0;

    var start: usize = 0;
    while (start < input.len) {
        var foundIndex = mem.indexOfPos(u8, input, start, "mul(");
        if (foundIndex == null) {
            break;
        }
        start = foundIndex.? + 4;

        foundIndex = mem.indexOfScalarPos(u8, input, start, ',');
        if (foundIndex == null) {
            break;
        }
        const firstNumSlice = input[start..foundIndex.?];
        if (mem.indexOfNone(u8, firstNumSlice, "0123456789") != null) {
            continue;
        }
        start = foundIndex.? + 1;

        foundIndex = mem.indexOfScalarPos(u8, input, start, ')');
        if (foundIndex == null) {
            break;
        }
        const secondNumSlice = input[start..foundIndex.?];
        if (mem.indexOfNone(u8, secondNumSlice, "0123456789") != null) {
            continue;
        }
        start = foundIndex.? + 1;

        if (fmt.parseInt(i32, firstNumSlice, 10)) |firstNum| {
            if (fmt.parseInt(i32, secondNumSlice, 10)) |secondNum| {
                sum += firstNum * secondNum;
            } else |_| {}
        } else |_| {}
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

pub fn part2() !void {}
