const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;

const allocator = std.heap.page_allocator;

pub fn part1() !void {
    const input: []const u8 = @embedFile("input/day1_part1.txt");

    var list1 = ArrayList(i32).init(allocator);
    var list2 = ArrayList(i32).init(allocator);
    defer list1.deinit();
    defer list2.deinit();

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
