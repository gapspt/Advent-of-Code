const std = @import("std");
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;

const allocator = std.heap.page_allocator;

const input: []const u8 = @embedFile("input/day6.txt");

var list: ?ArrayList([]u8) = null;
var w: i32 = 0;
var h: i32 = 0;
var xStart: i32 = 0;
var yStart: i32 = 0;

pub fn part1() !void {
    try readMap();
    defer freeMap();

    var items = list.?.items;
    var x: i32 = xStart;
    var y: i32 = yStart;

    var direction: u8 = 0;
    var sum: i32 = 1;
    while (true) {
        items[@intCast(y)][@intCast(x)] = 'X';

        const xNext = switch (direction) {
            1 => x + 1,
            3 => x - 1,
            else => x,
        };
        const yNext = switch (direction) {
            0 => y - 1,
            2 => y + 1,
            else => y,
        };

        if (xNext < 0 or xNext >= w or yNext < 0 or yNext >= h) {
            break;
        }
        switch (items[@intCast(yNext)][@intCast(xNext)]) {
            '.' => sum += 1,
            '#' => {
                direction = (direction + 1) % 4;
                continue;
            },
            else => {},
        }

        x = xNext;
        y = yNext;
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

pub fn part2() !void {}

fn readMap() !void {
    list = ArrayList([]u8).init(allocator);

    var linesSplit = mem.splitScalar(u8, input, '\n');
    h = 0;
    while (linesSplit.next()) |line| : (h += 1) {
        if (line.len == 0) {
            break;
        }

        try list.?.append(try allocator.dupe(u8, line));

        if (mem.indexOfScalar(u8, line, '^')) |index| {
            xStart = @intCast(index);
            yStart = h;
            w = @intCast(line.len);
        }
    }
}

fn freeMap() void {
    if (list == null) {
        return;
    }

    for (list.?.items) |item| {
        allocator.free(item);
    }

    list.?.deinit();
    list = null;
}
