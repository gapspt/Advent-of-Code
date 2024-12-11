const std = @import("std");
const io = std.io;
const math = std.math;
const mem = std.mem;
const ArrayList = std.ArrayList;

const Vec2 = struct { x: i16, y: i16 };

const allocator = std.heap.page_allocator;

const input: []const u8 = @embedFile("input/day8.txt");

var list: ?ArrayList([]bool) = null;
var mapping = [_]?ArrayList(Vec2){null} ** 256;
var w: i16 = 0;
var h: i16 = 0;

pub fn part1() !void {
    try calculate(false);
}

pub fn part2() !void {
    try calculate(true);
}

fn calculate(repeat: bool) !void {
    try readMap();
    defer freeMap();

    const items = list.?.items;

    var sum: i32 = 0;
    for (mapping) |mapList| {
        if (mapList != null and mapList.?.items.len > 1) {
            const mapItems = mapList.?.items;
            const len = mapItems.len;

            var i: u32 = 0;
            while (i < len) : (i += 1) {
                const pos1 = mapItems[i];

                var j: u32 = 0;
                while (j < len) : (j += 1) {
                    if (i == j) {
                        continue;
                    }

                    const pos2 = mapItems[j];

                    var dx: i16 = pos1.x - pos2.x;
                    var dy: i16 = pos1.y - pos2.y;
                    const gcd: i16 = @intCast(math.gcd(@max(1, @abs(dx)), @max(1, @abs(dy))));
                    dx = @divTrunc(dx, gcd);
                    dy = @divTrunc(dy, gcd);

                    var x: i16 = pos1.x;
                    var y: i16 = pos1.y;
                    if (!repeat) { // Count the antenas location only when repeat is true
                        x += dx;
                        y += dy;
                    }

                    while (x >= 0 and x < w and y >= 0 and y < h) {
                        if (!items[@intCast(y)][@intCast(x)]) {
                            items[@intCast(y)][@intCast(x)] = true;
                            sum += 1;
                        }

                        if (!repeat) {
                            break;
                        }

                        x += dx;
                        y += dy;
                    }
                }
            }
        }
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

fn readMap() !void {
    list = ArrayList([]bool).init(allocator);

    var linesSplit = mem.splitScalar(u8, input, '\n');
    h = 0;
    while (linesSplit.next()) |line| : (h += 1) {
        if (line.len == 0) {
            break;
        }
        w = @intCast(line.len);

        var x: i16 = 0;
        for (line) |c| {
            if (c != '.') {
                if (mapping[c] == null) {
                    mapping[c] = ArrayList(Vec2).init(allocator);
                }
                try mapping[c].?.append(.{ .x = x, .y = h });
            }
            x += 1;
        }
        const arr = try allocator.alloc(bool, line.len);
        @memset(arr, false);

        try list.?.append(arr);
    }
}

fn freeMap() void {
    if (list == null) {
        return;
    }

    for (list.?.items) |arr| {
        allocator.free(arr);
    }
    list.?.deinit();
    list = null;

    for (mapping) |item| {
        if (item != null) {
            item.?.deinit();
        }
    }
    @memset(mapping[0..], null);
}
