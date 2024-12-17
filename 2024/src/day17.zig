// https://adventofcode.com/2024/day/17

const std = @import("std");
const io = std.io;

pub fn part1() !void {
    const out = io.getStdOut().writer();

    var hasOutput = false;

    var a: u32 = 45483412;
    var b: u32 = 0;
    var c: u32 = 0;

    while (true) {
        // 2,4 => bst(4)
        b = a & 7;

        // 1,3 => bxl(3)
        b ^= 3;

        // 7,5 => cdv(5)
        c = a >> @intCast(b);

        // 0,3 => adv(3)
        a >>= 3;

        // 4,1 => bxc(1)
        b ^= c;

        // 1,5 => bxl(5)
        b ^= 5;

        // 5,5 => out(5)
        if (hasOutput) {
            try out.writeByte(',');
        }
        try out.writeByte('0' + @as(u8, @intCast(b & 7)));
        hasOutput = true;

        // 3,0 => jnz(0)
        if (a == 0) {
            break;
        }
    }
    try out.writeByte('\n');
}

pub fn part2() !void {}
