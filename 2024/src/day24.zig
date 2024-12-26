// https://adventofcode.com/2024/day/24

const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const StringHashMap = std.StringHashMap;

const GateType = enum(u8) { And = 'A', Or = 'O', Xor = 'X' };

const Wire = struct {
    name: []const u8,
    hasValue: bool,
    value: bool,
    in: ?*Gate,
    out: ArrayList(*Gate),
};

const Gate = struct {
    type: GateType,
    inNames: [2][]const u8,
    in: [2]*Wire,
    out: *Wire,
};

const WireConnectionsData = struct {
    wires: StringHashMap(*Wire),
    gates: StringHashMap(*Gate),
};

const input: []const u8 = @embedFile("input/day24.txt");

const input0Prefix = 'x';
const input1Prefix = 'y';
const outputPrefix = 'z';

var allocator: mem.Allocator = undefined;

pub fn part1() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const data = try readData();
    defer freeData(data);

    var num: u64 = 0;

    var it = data.gates.valueIterator();
    while (it.next()) |gatePtr| {
        const wire = gatePtr.*.out;
        if (wire.name[0] == outputPrefix and getWireValue(wire)) {
            const digit = try fmt.parseInt(u6, wire.name[1..], 10);
            num |= @as(u64, 1) << digit;
        }
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{num});
}

pub fn part2() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const data = try readData();
    defer freeData(data);

    // To sum two numbers with N bits we need 2 gates for the least significant bit and 5 gates for all the other bits
    const bits = @divExact(data.gates.count() + 3, 5);

    const in0Wires = try allocator.alloc(*Wire, bits);
    const in1Wires = try allocator.alloc(*Wire, bits);
    const outWires = try allocator.alloc(*Wire, bits + 1);
    defer {
        allocator.free(in0Wires);
        allocator.free(in1Wires);
        allocator.free(outWires);
    }

    var it = data.wires.iterator();
    while (it.next()) |entry| {
        const key = entry.key_ptr.*;

        var wireArr: []*Wire = undefined;
        switch (key[0]) {
            input0Prefix => wireArr = in0Wires,
            input1Prefix => wireArr = in1Wires,
            outputPrefix => wireArr = outWires,
            else => continue,
        }

        const n = try fmt.parseInt(u32, key[1..], 10);
        wireArr[n] = entry.value_ptr.*;
    }

    var wrongOuputGates = StringHashMap(bool).init(allocator);
    defer wrongOuputGates.deinit();

    // To sum two numbers with N bits we need the following gates, where xn and yn are the nth inputs, zn is the nth
    // output, and cn is the carry bit output from the (n-1)th operation and input into the nth operation.
    // 2 gates for the least significant bit:
    // - x0 XOR y0 -> z0
    // - x0 AND y0 -> c1
    // 5 gates for all the other bits:
    // - xn XOR yn -> sn
    // - cn XOR sn -> zn
    // - xn AND yn -> an
    // - cn AND sn -> bn
    // - an OR bn -> c(n+1)
    // The last carry bit output (cN) corresponds to the most significant bit in the result (zN).
    //
    // We need to find the gates that are not connected together accordingly.

    var lastCarry: ?*Wire = undefined;

    // Bit 0
    {
        const x = in0Wires[0];
        const y = in1Wires[0];
        const z = outWires[0];
        const gatesX = x.out.items;
        var zGate = gatesX[0];
        var cGate = gatesX[1];
        if (zGate.type != GateType.Xor) {
            zGate = gatesX[1];
            cGate = gatesX[0];
        }
        if (gatesX.len != 2 or zGate.type != GateType.Xor or cGate.type != GateType.And or
            (zGate.in[0] != y and zGate.in[1] != y) or (cGate.in[0] != y and cGate.in[1] != y))
        {
            @panic("Invalid gate configuration");
        }

        if (zGate.out != z) {
            try wrongOuputGates.put(zGate.out.name, false);
        }

        if (z.out.items.len != 0) {
            try wrongOuputGates.put(z.name, false);
        }

        lastCarry = cGate.out;
    }

    // Bits [1; N-1]
    var i: u32 = 1;
    while (i < bits) : (i += 1) {
        const x = in0Wires[i];
        const y = in1Wires[i];
        const z = outWires[i];

        const gatesX = x.out.items;
        var sGate = gatesX[0];
        var aGate = gatesX[1];
        if (sGate.type != GateType.Xor) {
            sGate = gatesX[1];
            aGate = gatesX[0];
        }
        if (gatesX.len != 2 or sGate.type != GateType.Xor or aGate.type != GateType.And or
            (sGate.in[0] != y and sGate.in[1] != y) or (aGate.in[0] != y and aGate.in[1] != y))
        {
            @panic("Invalid gate configuration");
        }

        const gatesS = sGate.out.out.items;
        var maybeZGateFromS: ?*Gate = null;
        var maybeBGateFromS: ?*Gate = null;
        if (gatesS.len != 2) {
            try wrongOuputGates.put(sGate.out.name, false);
        } else {
            maybeZGateFromS = gatesS[0];
            maybeBGateFromS = gatesS[1];
            if (maybeZGateFromS.?.type != GateType.Xor) {
                maybeZGateFromS = gatesS[1];
                maybeBGateFromS = gatesS[0];
            }

            if (maybeZGateFromS.?.type != GateType.Xor or maybeBGateFromS.?.type != GateType.And) {
                try wrongOuputGates.put(sGate.out.name, false);
                maybeZGateFromS = null;
                maybeBGateFromS = null;
            }
        }

        var maybeZGateFromLastC: ?*Gate = null;
        var maybeBGateFromLastC: ?*Gate = null;
        if (lastCarry != null) {
            const gatesLastC = lastCarry.?.out.items;
            if (gatesLastC.len != 2) {
                try wrongOuputGates.put(lastCarry.?.name, false);
            } else {
                maybeZGateFromLastC = gatesLastC[0];
                maybeBGateFromLastC = gatesLastC[1];
                if (maybeZGateFromLastC.?.type != GateType.Xor) {
                    maybeZGateFromLastC = gatesLastC[1];
                    maybeBGateFromLastC = gatesLastC[0];
                }

                if (maybeZGateFromLastC.?.type != GateType.Xor or maybeBGateFromLastC.?.type != GateType.And) {
                    try wrongOuputGates.put(lastCarry.?.name, false);
                    maybeZGateFromLastC = null;
                    maybeBGateFromLastC = null;
                }
            }
        }

        var maybeZGateFromZ: ?*Gate = null;
        if (z.out.items.len != 0 or z.in.?.type != GateType.Xor) {
            try wrongOuputGates.put(z.name, false);
        } else {
            maybeZGateFromZ = z.in;
        }

        var likelyZGate: ?*Gate = null;
        var likelyBGate: ?*Gate = null;
        if (maybeZGateFromS == maybeZGateFromLastC or maybeZGateFromS == maybeZGateFromZ) {
            likelyZGate = maybeZGateFromS;
            likelyBGate = maybeBGateFromS;
        } else if (maybeZGateFromLastC == maybeZGateFromZ) {
            likelyZGate = maybeZGateFromLastC;
            likelyBGate = maybeBGateFromLastC;
        }

        if (likelyZGate != null) {
            if (likelyZGate.?.type != GateType.Xor) {
                @panic("Invalid program logic");
            }

            if (maybeZGateFromS != null and maybeZGateFromS != likelyZGate) {
                try wrongOuputGates.put(sGate.out.name, false);
                maybeZGateFromS = null;
                maybeBGateFromS = null;
            } else if (maybeZGateFromLastC != null and maybeZGateFromLastC != likelyZGate) {
                try wrongOuputGates.put(lastCarry.?.name, false);
                lastCarry = null;
                maybeZGateFromLastC = null;
                maybeBGateFromLastC = null;
            } else if (maybeZGateFromZ != null and maybeZGateFromZ != likelyZGate) {
                try wrongOuputGates.put(z.name, false);
                maybeZGateFromZ = null;
            }

            if (likelyZGate.?.out.out.items.len != 0) {
                try wrongOuputGates.put(likelyZGate.?.out.name, false);
            }
        }

        var maybeNextCGateFromB: ?*Gate = null;
        if (likelyBGate != null) {
            if (likelyBGate.?.type != GateType.And) {
                @panic("Invalid program logic");
            }

            if (maybeBGateFromS != null and maybeBGateFromS != likelyBGate) {
                try wrongOuputGates.put(sGate.out.name, false);
                maybeZGateFromS = null;
                maybeBGateFromS = null;
            } else if (maybeBGateFromLastC != null and maybeBGateFromLastC != likelyBGate) {
                try wrongOuputGates.put(lastCarry.?.name, false);
                lastCarry = null;
                maybeZGateFromLastC = null;
                maybeBGateFromLastC = null;
            }

            const gatesB = likelyBGate.?.out.out.items;
            if (gatesB.len != 1) {
                try wrongOuputGates.put(likelyBGate.?.out.name, false);
            } else {
                maybeNextCGateFromB = gatesB[0];
                if (maybeNextCGateFromB.?.type != GateType.Or) {
                    try wrongOuputGates.put(likelyBGate.?.out.name, false);
                    maybeNextCGateFromB = null;
                }
            }
        }

        const gatesA = aGate.out.out.items;
        var maybeNextCGateFromA: ?*Gate = null;
        if (gatesA.len != 1) {
            try wrongOuputGates.put(aGate.out.name, false);
        } else {
            maybeNextCGateFromA = gatesA[0];
            if (maybeNextCGateFromA.?.type != GateType.Or) {
                try wrongOuputGates.put(aGate.out.name, false);
                maybeNextCGateFromA = null;
            }
        }

        var likelyNextCGate: ?*Gate = null;
        if (maybeNextCGateFromA == maybeNextCGateFromB) {
            likelyNextCGate = maybeNextCGateFromA;
        }

        if (likelyNextCGate != null) {
            if (likelyNextCGate.?.type != GateType.Or) {
                @panic("Invalid program logic");
            }
            lastCarry = likelyNextCGate.?.out;
        } else {
            lastCarry = null;
        }
    }

    // Last bit
    {
        const z = outWires[bits];

        if (lastCarry != null and lastCarry.?.out.items.len != 0) {
            try wrongOuputGates.put(lastCarry.?.name, false);
        }

        if (z.out.items.len != 0 or z.in.?.type != GateType.Or) {
            try wrongOuputGates.put(z.name, false);
        }
    }

    const result = try allocator.alloc([]const u8, wrongOuputGates.count());
    defer allocator.free(result);

    i = 0;
    var itResult = wrongOuputGates.keyIterator();
    while (itResult.next()) |name| : (i += 1) {
        result[i] = name.*;
    }

    mem.sort([]const u8, result, {}, comptime struct {
        pub fn inner(_: void, lhs: []const u8, rhs: []const u8) bool {
            return std.mem.order(u8, lhs, rhs) == .lt;
        }
    }.inner);

    const out = io.getStdOut().writer();
    var hasNames = false;
    for (result) |name| {
        if (hasNames) {
            try out.print(",{s}", .{name});
        } else {
            try out.print("{s}", .{name});
            hasNames = true;
        }
    }
    try out.writeByte('\n');
}

fn readData() !*WireConnectionsData {
    var wires = StringHashMap(*Wire).init(allocator);
    var gates = StringHashMap(*Gate).init(allocator);

    var linesSplit = mem.splitScalar(u8, input, '\n');

    // Read initial wire values
    while (linesSplit.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var valueSplit = mem.split(u8, line, ": ");
        const name = valueSplit.first();
        const value = (try fmt.parseInt(u1, valueSplit.next().?, 2)) != 0;

        const wire = try allocator.create(Wire);
        wire.* = .{
            .name = name,
            .hasValue = true,
            .value = value,
            .in = null,
            .out = ArrayList(*Gate).init(allocator),
        };

        try wires.put(name, wire);
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
        const wire = try allocator.create(Wire);
        gate.* = .{
            .type = gateType,
            .inNames = .{ in1, in2 },
            .in = .{ undefined, undefined },
            .out = wire,
        };
        wire.* = .{
            .name = out,
            .hasValue = false,
            .value = false,
            .in = gate,
            .out = ArrayList(*Gate).init(allocator),
        };
        try gates.put(out, gate);
        try wires.put(out, wire);
    }

    // Connect the gates
    var it = gates.valueIterator();
    while (it.next()) |gatePtr| {
        const gate = gatePtr.*;
        var i: u32 = 0;
        for (gate.inNames) |inName| {
            const wire = wires.get(inName).?;
            try wire.out.append(gate);
            gate.in[i] = wire;
            i += 1;
        }
    }

    const data = try allocator.create(WireConnectionsData);
    data.* = .{ .wires = wires, .gates = gates };
    return data;
}

fn freeData(data: *WireConnectionsData) void {
    var itWires = data.wires.valueIterator();
    while (itWires.next()) |wirePtr| {
        wirePtr.*.out.deinit();
        allocator.destroy(wirePtr.*);
    }
    data.wires.deinit();

    var itGates = data.gates.valueIterator();
    while (itGates.next()) |gatePtr| {
        allocator.destroy(gatePtr.*);
    }
    data.gates.deinit();

    allocator.destroy(data);
}

fn getWireValue(wire: *Wire) bool {
    if (wire.hasValue) {
        return wire.value;
    }

    const gate = wire.in.?;
    const val1 = getWireValue(gate.in[0]);
    const val2 = getWireValue(gate.in[1]);
    return switch (gate.type) {
        GateType.And => val1 and val2,
        GateType.Or => val1 or val2,
        GateType.Xor => val1 != val2,
    };
}
