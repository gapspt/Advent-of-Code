const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;

const allocator = std.heap.page_allocator;

var list1 = ArrayList(i32).init(allocator);
var list2 = ArrayList(i32).init(allocator);
var listsRead = false;

pub fn part1() !void {
    try readLists();

    var sum: i32 = 0;
    for (list1.items, 0..) |value1, index| {
        const diff = value1 - list2.items[index];
        if (diff >= 0) {
            sum += diff;
        } else {
            sum -= diff;
        }
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

pub fn part2() !void {
    try readLists();

    var sum: i64 = 0;
    var lastValue: i32 = 0;
    var lastPartialSum: i64 = 0;
    var index2: usize = 0;
    for (list1.items) |value1| {
        if (value1 == lastValue) {
            sum += lastPartialSum;
            continue;
        }
        lastValue = value1;

        lastPartialSum = 0;
        while (index2 < list2.items.len and list2.items[index2] <= value1) : (index2 += 1) {
            if (list2.items[index2] == value1) {
                lastPartialSum += value1;
            }
        }
        sum += lastPartialSum;
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

fn readLists() !void {
    if (listsRead) {
        return;
    }

    const input: []const u8 = @embedFile("input/day1.txt");

    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| {
        var valuesSplit = mem.splitScalar(u8, line, ' ');
        while (valuesSplit.next()) |value| {
            if (fmt.parseInt(i32, value, 10)) |i| {
                var list = &list1;
                if (list1.items.len != list2.items.len) {
                    list = &list2;
                }

                try list.*.append(i);

                if (list1.items.len == list2.items.len) {
                    break;
                }
            } else |_| {}
        }
    }

    sortList(list1);
    sortList(list2);

    listsRead = true;
}

fn sortList(list: ArrayList(i32)) void {
    mem.sort(
        i32,
        list.items,
        {},
        struct {
            fn func(_: void, lhs: i32, rhs: i32) bool {
                return lhs < rhs;
            }
        }.func,
    );
}
