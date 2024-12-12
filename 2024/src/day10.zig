const std = @import("std");
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const Node = struct { value: u8, reachable: ?AutoHashMap(u32, bool) };

const allocator = std.heap.page_allocator;

const input: []const u8 = @embedFile("input/day10.txt");

pub fn part1() !void {
    var list = ArrayList([]Node).init(allocator);
    defer list.deinit();
    var w: u32 = 0;
    var h: u32 = 0;

    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| : (h += 1) {
        if (line.len == 0) {
            break;
        }
        w = @intCast(line.len);

        const arr = try allocator.alloc(Node, line.len);
        var x: u32 = 0;
        while (x < w) : (x += 1) {
            arr[x] = .{ .value = line[x] - '0', .reachable = null };
        }

        try list.append(arr);
    }

    const items = list.items;
    var neighboursBuffer: [4]?*Node = .{ null, null, null, null };
    var sum: u32 = 0;

    var n: i32 = 9;
    while (n >= 0) : (n -= 1) {
        var y: u32 = 0;
        while (y < h) : (y += 1) {
            const row = items[y];

            var x: u32 = 0;
            while (x < w) : (x += 1) {
                const node = &row[x];
                if (node.value != n) {
                    continue;
                }

                if (node.value == 9) {
                    node.reachable = AutoHashMap(u32, bool).init(allocator);
                    try node.reachable.?.put(y * w + x, false);
                    continue;
                }

                var neighboursLength: u32 = 0;
                if (x > 0) {
                    neighboursBuffer[neighboursLength] = &row[x - 1];
                    neighboursLength += 1;
                }
                if (x + 1 < w) {
                    neighboursBuffer[neighboursLength] = &row[x + 1];
                    neighboursLength += 1;
                }
                if (y > 0) {
                    neighboursBuffer[neighboursLength] = &items[y - 1][x];
                    neighboursLength += 1;
                }
                if (y + 1 < h) {
                    neighboursBuffer[neighboursLength] = &items[y + 1][x];
                    neighboursLength += 1;
                }

                while (neighboursLength > 0) {
                    neighboursLength -= 1;
                    const neighbour = neighboursBuffer[neighboursLength];
                    if (neighbour.?.value == node.value + 1 and neighbour.?.reachable != null) {
                        if (node.reachable == null) {
                            node.reachable = AutoHashMap(u32, bool).init(allocator);
                        }

                        var iterator = neighbour.?.reachable.?.iterator();
                        while (iterator.next()) |entry| {
                            try node.reachable.?.put(entry.key_ptr.*, false);
                        }
                    }
                    neighboursBuffer[neighboursLength] = null;
                }

                if (node.value == 0 and node.reachable != null) {
                    sum += node.reachable.?.count();
                }
            }
        }
    }

    for (items) |row| {
        var x: u32 = 0;
        while (x < w) : (x += 1) {
            if (row[x].reachable != null) {
                row[x].reachable.?.deinit();
            }
        }
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

pub fn part2() !void {}
