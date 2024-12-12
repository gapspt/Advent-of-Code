const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const DoublyLinkedList = std.DoublyLinkedList;

const ListNode = std.DoublyLinkedList(u64).Node;

const allocator = std.heap.page_allocator;

const input: []const u8 = @embedFile("input/day11.txt");

pub fn part1() !void {
    var list = DoublyLinkedList(u64){};

    var valuesSplit = mem.splitAny(u8, input, " \r\n");
    while (valuesSplit.next()) |valueStr| {
        if (valueStr.len == 0) {
            break;
        }

        const node = try allocator.create(ListNode);
        node.data = try fmt.parseInt(u64, valueStr, 10);
        list.append(node);
    }

    var n: i32 = 25;
    while (n > 0) : (n -= 1) {
        var next = list.first;
        while (next) |node| {
            next = node.next;

            var value = node.data;

            // - If the stone is engraved with the number 0, it is replaced by a stone engraved with the number 1.
            // - If the stone is engraved with a number that has an even number of digits, it is replaced by two stones.
            //   The left half of the digits are engraved on the new left stone, and the right half of the
            //   digits are engraved on the new right stone.
            //   (The new numbers don't keep extra leading zeroes: 1000 would become stones 10 and 0.)
            // - If none of the other rules apply, the stone is replaced by a new stone;
            //   the old stone's number multiplied by 2024 is engraved on the new stone.

            if (value == 0) {
                node.data = 1;
            } else {
                var digits: u32 = 1;
                var v = value;
                while (v > 9) : (v = @divTrunc(v, 10)) {
                    digits += 1;
                }

                if (digits % 2 == 0) {
                    const newNode = try allocator.create(ListNode);
                    list.insertAfter(node, newNode);

                    node.data = 0;
                    newNode.data = 0;

                    const halfDigits = digits / 2;
                    var mult: u64 = 1;
                    var i: u32 = 0;
                    while (i < halfDigits) : (i += 1) {
                        newNode.data += (value % 10) * mult;
                        value = @divTrunc(value, 10);
                        mult *= 10;
                    }
                    mult = 1;
                    while (i < digits) : (i += 1) {
                        node.data += (value % 10) * mult;
                        value = @divTrunc(value, 10);
                        mult *= 10;
                    }
                } else {
                    node.data = value * 2024;
                }
            }
        }
    }

    const sum = list.len;

    while (list.pop()) |node| {
        allocator.destroy(node);
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

pub fn part2() !void {}
