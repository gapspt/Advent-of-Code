const std = @import("std");
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;

const Plot = struct { plant: u8, root: *Plot, area: i32, perimeter: i32, corners: i32 };

const allocator: mem.Allocator = std.heap.page_allocator;

const input: []const u8 = @embedFile("input/day12.txt");

pub fn part1() !void {
    try calcCost(false);
}

pub fn part2() !void {
    try calcCost(true);
}

fn calcCost(useSides: bool) !void {
    var list = ArrayList([]Plot).init(allocator);
    defer list.deinit();
    var w: u32 = 0;
    var h: u32 = 0;

    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| : (h += 1) {
        if (line.len == 0) {
            break;
        }
        w = @intCast(line.len);

        const arr = try allocator.alloc(Plot, w);

        var x: u32 = 0;
        while (x < w) : (x += 1) {
            arr[x] = .{ .plant = line[x], .root = undefined, .area = 0, .perimeter = 0, .corners = 0 };
            const plot = &arr[x];

            var root = plot;
            if (x > 0) {
                const other = &arr[x - 1];
                if (plot.plant == other.plant) {
                    root = findRoot(other);
                }
            }
            if (h > 0) {
                const other = &list.items[h - 1][x];
                if (plot.plant == other.plant) {
                    if (root == plot) {
                        root = findRoot(other);
                    } else {
                        findRoot(other).root = root;
                    }
                }
            }
            plot.root = root;
        }

        try list.append(arr);
    }

    const items = list.items;

    var y: u32 = 0;
    while (y < h) : (y += 1) {
        const row = items[y];

        var x: u32 = 0;
        while (x < w) : (x += 1) {
            const plot = &row[x];
            const plant = plot.plant;
            const root = findRoot(plot);

            root.area += 1;

            const borderLeft = x == 0 or row[x - 1].plant != plant;
            const borderRight = x + 1 == w or row[x + 1].plant != plant;
            const borderTop = y == 0 or items[y - 1][x].plant != plant;
            const borderBottom = y + 1 == h or items[y + 1][x].plant != plant;

            if (useSides) {
                if (borderLeft and (borderTop or (x != 0 and items[y - 1][x - 1].plant == plant))) {
                    root.corners += 1;
                }
                if (borderRight and (borderBottom or (x + 1 != w and items[y + 1][x + 1].plant == plant))) {
                    root.corners += 1;
                }
                if (borderTop and (borderRight or (y != 0 and items[y - 1][x + 1].plant == plant))) {
                    root.corners += 1;
                }
                if (borderBottom and (borderLeft or (y + 1 != h and items[y + 1][x - 1].plant == plant))) {
                    root.corners += 1;
                }
            } else {
                if (borderLeft) {
                    root.perimeter += 1;
                }
                if (borderRight) {
                    root.perimeter += 1;
                }
                if (borderTop) {
                    root.perimeter += 1;
                }
                if (borderBottom) {
                    root.perimeter += 1;
                }
            }
        }
    }

    var sum: i64 = 0;

    for (items) |row| {
        var x: u32 = 0;
        while (x < w) : (x += 1) {
            const plot = &row[x];
            if (plot == plot.root) {
                if (useSides) {
                    // Note: There are as many sides as there are corners, so we count the corners since that is easier
                    sum += plot.area * plot.corners;
                } else {
                    sum += plot.area * plot.perimeter;
                }
            }
        }
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

fn findRoot(plot: *Plot) *Plot {
    if (plot == plot.root) {
        return plot;
    }
    plot.root = findRoot(plot.root);
    return plot.root;
}
