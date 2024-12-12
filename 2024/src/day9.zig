const std = @import("std");
const io = std.io;

const allocator = std.heap.page_allocator;

const input: []const u8 = @embedFile("input/day9.txt");

pub fn part1() !void {
    var len = input.len;
    var arr: []u8 = try allocator.alloc(u8, len);
    defer allocator.free(arr);

    var i: u32 = 0;
    while (i < len) : (i += 1) {
        const c = input[i];
        if (c < '0' or c > '9') {
            len = i;
            break;
        }
        arr[i] = c - '0';
    }

    var sum: i64 = 0;

    var pos: i64 = 0;
    i = 0;
    var j: u32 = @intCast(len - 1);
    j -= j % 2;

    while (i <= j) {
        var id: i64 = i / 2;
        var n: u8 = arr[i];
        if (i % 2 == 0) {
            i += 1;
        } else {
            id = j / 2;
            if (arr[j] >= n) {
                arr[j] -= n;
                i += 1;
            } else {
                n = arr[j];
                arr[i] -= n;
                j -= 2;
            }
        }

        if (n == 0) {
            continue;
        }

        //while (n > 0) : (n -= 1) {
        //    sum += pos * id;
        //    pos += 1;
        //}
        sum += id * ((pos * n) + @divExact(n * (n - 1), 2));
        pos += n;
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

pub fn part2() !void {}
