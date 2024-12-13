const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const math = std.math;
const mem = std.mem;

const input: []const u8 = @embedFile("input/day13.txt");

pub fn part1() !void {
    try sumBestCosts(0, 0);
}

pub fn part2() !void {
    try sumBestCosts(10000000000000, 10000000000000);
}

fn sumBestCosts(offsetX: u64, offsetY: u64) !void {
    var sum: u64 = 0;

    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var x: [3]u64 = undefined;
        var y: [3]u64 = undefined;
        var l = line;
        var i: u32 = 0;
        while (i < x.len) : (i += 1) {
            const ix = mem.indexOfScalar(u8, l, 'X').? + 2;
            const ic = mem.indexOfScalarPos(u8, l, ix, ',').?;
            const iy = mem.indexOfScalarPos(u8, l, ic + 1, 'Y').? + 2;

            x[i] = try fmt.parseInt(u64, l[ix..ic], 10);
            y[i] = try fmt.parseInt(u64, l[iy..], 10);

            l = linesSplit.next().?;
        }

        const ax = x[0];
        const ay = y[0];
        const bx = x[1];
        const by = y[1];
        const px = x[2];
        const py = y[2];

        const cost = try findBestCost(ax, ay, bx, by, px + offsetX, py + offsetY);
        if (cost > 0) {
            //std.debug.print("Found minimum cost: {}\n", .{cost});
        } else {
            //std.debug.print("No cost found\n", .{});
        }
        sum += cost;
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

fn findBestCost(ax: u64, ay: u64, bx: u64, by: u64, px: u64, py: u64) !u64 {
    const aCost: u64 = 3;
    const bCost: u64 = 1;

    const ax128: u128 = ax;
    const ay128: u128 = ay;
    const bx128: u128 = bx;
    const by128: u128 = by;
    const px128: u128 = px;
    const py128: u128 = py;
    const aIsLeft = ax128 * py128 < px128 * ay128;
    const bIsLeft = bx128 * py128 < px128 * by128;
    const aIsRight = ax128 * py128 > px128 * ay128;
    const bIsRight = bx128 * py128 > px128 * by128;

    if ((aIsLeft and bIsLeft) or (aIsRight and bIsRight)) {
        return 0;
    }

    const aIsStraight = !aIsLeft and !aIsRight;
    const bIsStraight = !bIsLeft and !bIsRight;
    if (aIsStraight or bIsStraight) {
        // At least one of the directions points straight at the prize

        if (!bIsStraight) {
            if (px % ax == 0) {
                return px / ax * aCost;
            }
            return 0;
        }
        if (!aIsStraight) {
            if (px % bx == 0) {
                return px / bx * bCost;
            }
            return 0;
        }

        // Both directions point straight at the prize...
        // It is not worth implementing this for now, since the data doesn't contain this edge case.
        unreachable;
    }

    var lx: u64 = undefined;
    var ly: u64 = undefined;
    var lCost: u64 = undefined;
    var rx: u64 = undefined;
    var ry: u64 = undefined;
    var rCost: u64 = undefined;
    if (aIsLeft and bIsRight) {
        lx = ax;
        ly = ay;
        lCost = aCost;
        rx = bx;
        ry = by;
        rCost = bCost;
    } else if (aIsRight and bIsLeft) {
        lx = bx;
        ly = by;
        lCost = bCost;
        rx = ax;
        ry = ay;
        rCost = aCost;
    } else {
        unreachable;
    }

    var lCountMin: u64 = 0;
    var lCountMax: u64 = try math.divCeil(u64, py, ly);
    while (lCountMin <= lCountMax) {
        const lCount = (lCountMin + lCountMax) / 2;
        const yDist = py - (lCount * ly);
        const rCount = try math.divCeil(u64, yDist, ry);
        const x = (lCount * lx) + (rCount * rx);
        const y = (lCount * ly) + (rCount * ry);
        if (x == px and y == py) {
            return lCount * lCost + rCount * rCost;
        }

        if (lCount == lCountMin) {
            lCountMin += 1;
            continue;
        } else if (lCount == lCountMax) {
            lCountMax -= 1;
            continue;
        }

        // rCount = yDist / ry
        const rCountNumerator: u128 = yDist;
        const rCountDenominator: u128 = ry;
        // x = (lCount * lx) + (rCount * rx)
        const xNumerator: u128 = ((lCount * lx) * rCountDenominator) + (rCountNumerator * rx);
        const xDenominator: u128 = rCountDenominator;
        // if x < px
        if (xNumerator < px * xDenominator) { // Landed on the left
            lCountMax = lCount;
        } else { // Landed on the right
            lCountMin = lCount;
        }
    }
    return 0;
}
