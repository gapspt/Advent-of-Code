// https://adventofcode.com/2024/day/17

const std = @import("std");
const io = std.io;

pub fn part1() !void {
    const out = io.getStdOut().writer();

    var hasOutput = false;

    var a: u64 = 45483412;
    var b: u64 = 0;
    var c: u64 = 0;

    while (true) {
        const it = iteration(&a, &b, &c);

        if (hasOutput) {
            try out.writeByte(',');
        }
        try out.writeByte('0' + it.out);
        hasOutput = true;

        if (!it.jump) {
            break;
        }
    }
    try out.writeByte('\n');
}

pub fn part2() !void {
    const expected: [16]u8 = .{ 2, 4, 1, 3, 7, 5, 0, 3, 4, 1, 1, 5, 5, 5, 3, 0 };

    const a = findMatchingA(&expected, 0);

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{a.?});
}

fn iteration(pa: *u64, pb: *u64, pc: *u64) struct { out: u8, jump: bool } {
    var a = pa.*;
    var b = pb.*;
    var c = pc.*;

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

    pa.* = a;
    pb.* = b;
    pc.* = c;

    return .{
        // 5,5 => out(5)
        .out = @intCast(b & 7),
        // 3,0 => jnz(0)
        .jump = a != 0,
    };
}

fn findMatchingA(expected: []const u8, aCurrent: u64) ?u64 {
    if (expected.len == 0) {
        return aCurrent;
    }
    const n = expected[expected.len - 1];

    const aOriginal: u64 = aCurrent << 3;

    // Each iteration shifts `a` by 3 bits, so we calculate each 3 bits of `a` separately.
    // There are several possibilities that yield the same output on each step, but not all will result in a viable
    // value overall, so we still need to find the right combination for all steps.
    var j: u8 = 0;
    while (j < 8) : (j += 1) {
        var a: u64 = aOriginal + j;
        var b: u64 = 0;
        var c: u64 = 0;
        const it = iteration(&a, &b, &c);

        if (it.out == n) {
            if (findMatchingA(expected[0..(expected.len - 1)], aOriginal + j)) |aCorrect| {
                return aCorrect;
            }
        }
    }

    return null;
}
