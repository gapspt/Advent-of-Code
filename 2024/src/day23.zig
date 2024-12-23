// https://adventofcode.com/2024/day/23

const std = @import("std");
const io = std.io;
const mem = std.mem;
const ArrayList = std.ArrayList;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const StringArrayHashMap = std.StringArrayHashMap;

const ConnectionData = struct {
    names: StringArrayHashMap(u32),
    connections: ArrayList([2]u32),
    connectionMap: []bool,
};

const input: []const u8 = @embedFile("input/day23.txt");

var allocator: mem.Allocator = undefined;

pub fn part1() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const initialLetter = 't';

    const data = try readConnectionData();
    defer freeConnectionData(data);

    const namesArray = data.names.iterator().keys;
    const count = data.names.count();

    var sum: i32 = 0;

    for (data.connections.items) |connection| {
        const i = connection[0];
        const j = connection[1];
        const iIndexMult = i * count;
        const jIndexMult = j * count;

        const letterFound = namesArray[i][0] == initialLetter or namesArray[j][0] == initialLetter;

        var k: u32 = @max(i, j) + 1;
        while (k < count) : (k += 1) {
            if (k != i and k != j and
                data.connectionMap[iIndexMult + k] and data.connectionMap[jIndexMult + k] and
                (letterFound or namesArray[k][0] == initialLetter))
            {
                sum += 1;
            }
        }
    }

    const out = io.getStdOut().writer();
    try out.print("{}\n", .{sum});
}

pub fn part2() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const data = try readConnectionData();
    defer freeConnectionData(data);

    const namesArray = data.names.iterator().keys;
    const count = data.names.count();

    var connectionGroups1 = ArrayList([]u32).init(allocator);
    var connectionGroups2 = ArrayList([]u32).init(allocator);
    defer {
        for (connectionGroups1.items) |connection| {
            allocator.free(connection);
        }
        for (connectionGroups2.items) |connection| {
            allocator.free(connection);
        }
        connectionGroups1.deinit();
        connectionGroups2.deinit();
    }

    var connectionGroups = &connectionGroups1;
    var prevConnectionGroups = &connectionGroups2;

    for (data.connections.items) |connection| {
        var dup = try allocator.dupe(u32, connection[0..]);
        if (connection[0] > connection[1]) {
            dup[0] = connection[1];
            dup[1] = connection[0];
        }
        try connectionGroups.append(dup);
    }

    var groupSize: u32 = 2;
    while (connectionGroups.items.len > 0) : (groupSize += 1) {
        // Clean the previous and swap it with the current so that we get a clean current
        for (prevConnectionGroups.items) |connection| {
            allocator.free(connection);
        }
        try prevConnectionGroups.resize(0);
        const aux = connectionGroups;
        connectionGroups = prevConnectionGroups;
        prevConnectionGroups = aux;

        const groupLastIndex = groupSize - 1;
        const newGroupSize = groupSize + 1;

        for (prevConnectionGroups.items) |group| {
            var i = group[groupLastIndex] + 1;
            while (i < count) : (i += 1) {
                const iIndexMult = i * count;

                var connectsToAll = true;
                for (group) |j| {
                    if (!data.connectionMap[iIndexMult + j]) {
                        connectsToAll = false;
                        break;
                    }
                }

                if (connectsToAll) {
                    var newGroup = try allocator.alloc(u32, newGroupSize);
                    @memcpy(newGroup[0..groupSize], group);
                    newGroup[groupSize] = i;
                    try connectionGroups.append(newGroup);
                }
            }
        }
    }

    const group = prevConnectionGroups.items[0];

    mem.sort(u32, group, namesArray, comptime struct {
        pub fn inner(names: [*][]const u8, lhs: u32, rhs: u32) bool {
            return std.mem.order(u8, names[lhs], names[rhs]) == .lt;
        }
    }.inner);

    const out = io.getStdOut().writer();
    var hasNames = false;
    for (group) |i| {
        if (hasNames) {
            try out.print(",{s}", .{namesArray[i]});
        } else {
            try out.print("{s}", .{namesArray[i]});
            hasNames = true;
        }
    }
    try out.writeByte('\n');
}

fn readConnectionData() !ConnectionData {
    var names = StringArrayHashMap(u32).init(allocator);
    var connections = ArrayList([2]u32).init(allocator);

    var linesSplit = mem.splitScalar(u8, input, '\n');
    while (linesSplit.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var valueSplit = mem.splitScalar(u8, line, '-');

        const aName = valueSplit.first();
        const aEntry = try names.getOrPutValue(aName, @intCast(names.count()));
        const a = aEntry.value_ptr.*;

        const bName = valueSplit.next().?;
        const bEntry = try names.getOrPutValue(bName, @intCast(names.count()));
        const b = bEntry.value_ptr.*;

        try connections.append(.{ a, b });
    }

    const count = names.count();
    var connectionMap = try allocator.alloc(bool, count * count);
    for (connections.items) |connection| {
        connectionMap[connection[0] * count + connection[1]] = true;
        connectionMap[connection[1] * count + connection[0]] = true;
    }

    return .{ .names = names, .connections = connections, .connectionMap = connectionMap };
}

fn freeConnectionData(data: ConnectionData) void {
    var aux = data; // For some reason the compiler complains about data.names.deinit() being const
    aux.names.deinit();
    data.connections.deinit();
    allocator.free(data.connectionMap);
}
