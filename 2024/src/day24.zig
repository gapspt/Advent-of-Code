// https://adventofcode.com/2024/day/24

const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const StringHashMap = std.StringHashMap;

const GateType = enum(u8) { And = 'A', Or = 'O', Xor = 'X' };

const Gate = struct {
    type: GateType,
    in1: []const u8,
    in2: []const u8,
    inCount: u2,
    val1: bool,
    out: bool,
    outputs: ArrayList(*Gate),
};

const Wire = struct {
    value: bool,
    outputs: ArrayList(*Gate),
};

const input: []const u8 = @embedFile("input/day24.txt");

const resultGatePrefix = 'z';

var allocator: mem.Allocator = undefined;

pub fn part1() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var initialWires = StringHashMap(Wire).init(allocator);
    var gates = StringHashMap(*Gate).init(allocator);
    defer {
        var itWires = initialWires.iterator();
        while (itWires.next()) |wire| {
            wire.value_ptr.outputs.deinit();
        }
        initialWires.deinit();

        var itGates = gates.iterator();
        while (itGates.next()) |entry| {
            entry.value_ptr.*.outputs.deinit();
            allocator.destroy(entry.value_ptr.*);
        }
        gates.deinit();
    }

    var linesSplit = mem.splitScalar(u8, input, '\n');

    // Read initial wire values
    while (linesSplit.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var valueSplit = mem.split(u8, line, ": ");
        const wire = valueSplit.first();
        const value = (try fmt.parseInt(u1, valueSplit.next().?, 2)) != 0;

        try initialWires.put(wire, .{
            .value = value,
            .outputs = ArrayList(*Gate).init(allocator),
        });
    }

    // Read gate connections
    while (linesSplit.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var valueSplit = mem.splitScalar(u8, line, ' ');
        const in1 = valueSplit.first();
        const gateType: GateType = @enumFromInt(valueSplit.next().?[0]);
        const in2 = valueSplit.next().?;
        _ = valueSplit.next(); // Ignore the "->"
        const out = valueSplit.next().?;

        const gate = try allocator.create(Gate);
        gate.* = .{
            .type = gateType,
            .in1 = in1,
            .in2 = in2,
            .inCount = 0,
            .val1 = false,
            .out = false,
            .outputs = ArrayList(*Gate).init(allocator),
        };
        try gates.put(out, gate);
    }

    // Connect the gates
    var itGates = gates.iterator();
    while (itGates.next()) |entry| {
        const gate = entry.value_ptr.*;
        if (gates.get(gate.in1)) |outGate| {
            try outGate.outputs.append(gate);
        } else if (initialWires.getEntry(gate.in1)) |wire| {
            try wire.value_ptr.outputs.append(gate);
        }

        if (gates.get(gate.in2)) |outGate| {
            try outGate.outputs.append(gate);
        } else if (initialWires.getEntry(gate.in2)) |wire| {
            try wire.value_ptr.outputs.append(gate);
        }
    }

    // Propagate the initial wire values through the gates
    var itWires = initialWires.iterator();
    while (itWires.next()) |entry| {
        setGateInputValue(entry.value_ptr.outputs.items, entry.value_ptr.value);
    }

    // Read the output of the z gates and create a binary number
    var num: u64 = 0;
    itGates = gates.iterator();
    while (itGates.next()) |entry| {
        const key = entry.key_ptr.*;
        if (key[0] != resultGatePrefix) {
            continue;
        }

        const gate = entry.value_ptr.*;
        if (gate.inCount != 2) {
            @panic("The gate needs to have 2 inputs");
        }
        if (gate.out) {
            const digit = try fmt.parseInt(u6, key[1..], 10);
            num |= @as(u64, 1) << digit;
        }
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{num});
}

pub fn part2() !void {}

fn setGateInputValue(gates: []*Gate, value: bool) void {
    for (gates) |gate| {
        gate.inCount += 1;
        if (gate.inCount == 1) {
            gate.val1 = value;
        } else if (gate.inCount == 2) {
            gate.out = switch (gate.type) {
                GateType.And => gate.val1 and value,
                GateType.Or => gate.val1 or value,
                GateType.Xor => gate.val1 != value,
            };
            setGateInputValue(gate.outputs.items, gate.out);
        } else {
            @panic("The gate cannot have more than 2 inputs");
        }
    }
}
