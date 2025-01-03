const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;

pub fn part1() !void {
    try checkReports(0);
}

pub fn part2() !void {
    try checkReports(1);
}

pub fn checkReports(tolerance: i32) !void {
    const input: []const u8 = @embedFile("input/day2.txt");

    var sum: i32 = 0;

    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| {
        if (try checkReport(line, tolerance)) {
            sum += 1;
        }
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

fn checkReport(report: []const u8, tolerance: i32) !bool {
    var remainingTolerance = tolerance;
    var previous: i32 = 0;
    var direction: i32 = 0;

    var valuesSplit = mem.splitScalar(u8, report, ' ');

    const first = fmt.parseInt(i32, valuesSplit.first(), 10);
    if (first) |value| {
        previous = value;
    } else |_| {
        return false;
    }

    while (valuesSplit.next()) |value| {
        if (fmt.parseInt(i32, value, 10)) |current| {
            if (current < previous and direction <= 0 and current >= previous - 3) {
                direction = -1;
            } else if (current > previous and direction >= 0 and current <= previous + 3) {
                direction = 1;
            } else {
                remainingTolerance -= 1;
                if (remainingTolerance < 0) {
                    return false;
                }
            }
            previous = current;
        } else |_| {}
    }
    return true;
}
