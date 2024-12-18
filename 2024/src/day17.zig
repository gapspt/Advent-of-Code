// https://adventofcode.com/2024/day/17

const std = @import("std");
const io = std.io;
const mem = std.mem;

var allocator: mem.Allocator = std.heap.page_allocator;

pub fn part1() !void {
    const out = io.getStdOut().writer();

    const program: [16]u8 = .{ 2, 4, 1, 3, 7, 5, 0, 3, 4, 1, 1, 5, 5, 5, 3, 0 };

    var hasOutput = false;

    var a: u64 = 45483412;
    var b: u64 = 0;
    var c: u64 = 0;

    while (true) {
        const it = iteration(&a, &b, &c, &program);

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
    const program: [16]u8 = .{ 2, 4, 1, 3, 7, 5, 0, 3, 4, 1, 1, 5, 5, 5, 3, 0 };

    const a = findMatchingA(&program, &program, 0);

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{a.?});

    try challenge();
}

fn challenge() !void {
    const out = io.getStdOut().writer();

    var program = try allocator.alloc(u8, 16);
    defer allocator.free(program);

    var quines: u64 = 0;
    var fails: u64 = 0;

    // Using my own input as a template
    program[0] = 2;
    program[1] = 4; // Iterate
    program[2] = 1;
    program[3] = 3; // Iterate
    program[4] = 7;
    program[5] = 5; // Iterate
    program[6] = 0;
    program[7] = 3;
    program[8] = 4;
    program[9] = 1; // Iterate
    program[10] = 1;
    program[11] = 5; // Iterate
    program[12] = 5;
    program[13] = 5;
    program[14] = 3;
    program[15] = 0;

    // Yep, we're doing this insane amount of chained cycles boys, IDC :)
    program[1] = 0;
    while (program[1] < 8) : (program[1] += 1) {
        program[3] = 0;
        while (program[3] < 8) : (program[3] += 1) {
            program[5] = 0;
            while (program[5] < 8) : (program[5] += 1) {
                program[9] = 0;
                while (program[9] < 8) : (program[9] += 1) {
                    program[11] = 0;
                    while (program[11] < 8) : (program[11] += 1) {
                        if (findMatchingA(program, program, 0)) |a| {
                            quines += 1;

                            // Change it to true to output every quine
                            if (false) {
                                var p: u64 = 0;
                                for (program) |n| {
                                    p = (p << 4) + n;
                                }
                                try out.print("P: {x} A: {}\n", .{ p, a });
                            }
                        } else {
                            fails += 1;
                        }
                    }
                }
            }
        }
    }

    try out.print("{} quines out of {} attempts\n", .{ quines, quines + fails });
}

fn iteration(pa: *u64, pb: *u64, pc: *u64, program: []const u8) struct { out: u8, jump: bool } {
    var a = pa.*;
    var b = pb.*;
    var c = pc.*;

    // 2,x => bst(x)
    var x: u64 = switch (program[1]) {
        4 => a,
        5 => b,
        6 => c,
        else => program[1],
    };
    b = x & 7;

    // 1,x => bxl(x)
    b ^= program[3];

    // 7,x => cdv(x)
    x = switch (program[5]) {
        4 => a,
        5 => b,
        6 => c,
        else => program[5],
    };
    c = if (x > 63) 0 else (a >> @intCast(x));

    // 0,3 => adv(3)
    a >>= 3;

    // 4,x => bxc(x)
    b ^= c;

    // 1,x => bxl(x)
    b ^= program[11];

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

fn findMatchingA(program: []const u8, expected: []const u8, aCurrent: u64) ?u64 {
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
        const it = iteration(&a, &b, &c, program);

        if (it.out == n) {
            if (findMatchingA(program, expected[0..(expected.len - 1)], aOriginal + j)) |aCorrect| {
                return aCorrect;
            }
        }
    }

    return null;
}
