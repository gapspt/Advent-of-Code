const std = @import("std");
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;

const allocator = std.heap.page_allocator;

const input: []const u8 = @embedFile("input/day6.txt");

const spaceEmpty: u8 = 0;
const spaceWall: u8 = 1;

var list: ?ArrayList([]u8) = null;
var w: i32 = 0;
var h: i32 = 0;
var xStart: i32 = 0;
var yStart: i32 = 0;

pub fn part1() !void {
    try readMap();
    defer freeMap();

    const result = walkMap();

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{result.area});
}

pub fn part2() !void {
    try readMap();
    defer freeMap();

    var sum: i32 = 0;
    var y: i32 = 0;
    for (list.?.items) |line| {
        var x: u32 = 0;
        while (x < w) : (x += 1) {
            if ((x == xStart and y == yStart) or line[x] != spaceEmpty) {
                continue;
            }

            line[x] = spaceWall;
            const result = walkMap();
            if (result.cyclic) {
                sum += 1;
            }
            line[x] = spaceEmpty;
        }
        y += 1;
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

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

    list.?.items[@intCast(yStart)][@intCast(xStart)] = spaceEmpty;
    for (list.?.items) |line| {
        mem.replaceScalar(u8, line, '.', spaceEmpty);
        mem.replaceScalar(u8, line, '#', spaceWall);
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

fn walkMap() struct { cyclic: bool, area: i32 } {
    var items = list.?.items;
    var x: i32 = xStart;
    var y: i32 = yStart;

    var direction: u8 = 0;
    var area: i32 = 1;
    var cyclic = false;
    while (true) {
        const directionMask: u8 = @as(u8, 1) << @intCast(direction + 1);
        if ((items[@intCast(y)][@intCast(x)]) & directionMask != 0) {
            cyclic = true;
            break;
        }
        items[@intCast(y)][@intCast(x)] |= directionMask;

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
            spaceEmpty => area += 1,
            spaceWall => {
                direction = (direction + 1) % 4;
                continue;
            },
            else => {},
        }

        x = xNext;
        y = yNext;
    }

    // Restore the empty spaces
    for (list.?.items) |line| {
        x = 0;
        while (x < w) : (x += 1) {
            line[@intCast(x)] &= 1;
        }
    }

    return .{ .cyclic = cyclic, .area = area };
}
