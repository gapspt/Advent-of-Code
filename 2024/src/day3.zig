const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;

const regex = @import("regex");

const allocator = std.heap.page_allocator;

pub fn part1() !void {
    try scanInput(false);
}

pub fn part2() !void {
    try scanInput(true);
}

pub fn scanInput(scanDoAndDont: bool) !void {
    const input: []const u8 = @embedFile("input/day3.txt");

    var sum: i64 = 0;
    var checkDoMul = scanDoAndDont;

    var start: usize = 0;
    while (start < input.len) {
        var foundIndex: ?usize = null;

        foundIndex = mem.indexOfPos(u8, input, start, "mul(");
        if (foundIndex == null) {
            break;
        }

        if (checkDoMul) {
            const dontIndex = mem.indexOfPos(u8, input, start, "don't()");
            if (dontIndex == null) {
                checkDoMul = false;
            } else if (dontIndex.? < foundIndex.?) {
                start = dontIndex.? + 7;

                foundIndex = mem.indexOfPos(u8, input, start, "do()");
                if (foundIndex == null) {
                    break;
                }
                start = foundIndex.? + 4;
                continue;
            }
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
