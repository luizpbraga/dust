const std = @import("std");
const ga = @import("../frontend/lexer.zig").ga;

pub const ValueType = enum {
    Null,
    Number,
    Bool,
    Struct,
};

pub const RuntimeValue = union(enum) {
    numberValue: NumberValue,
    nullValue: NullValue,
    structValue: StructValue,
    boolValue: BoolValue,

    pub fn haveType(self: @This()) ValueType {
        return switch (self) {
            inline else => |p| p.type,
        };
    }

    // TODO: recursive print
    pub fn printTorepl(self: @This()) void {
        switch (self) {
            inline else => |r| std.debug.print("=> {} : {}\n", .{ r.value, r.type }),
            .numberValue => |r| std.debug.print("=> {d} : {}\n", .{ r.value, r.type }),
            .structValue => |r| {
                for (r.properties.keys()) |name| {
                    std.debug.print("{{ name: {s}, ", .{name});
                    var _value = r.properties.get(name);
                    if (_value) |value|
                        switch (value) {
                            .numberValue => |p| {
                                std.debug.print("value : {d} }}\n", .{p.value});
                            },

                            .structValue => |p| {
                                std.debug.print("field : \n", .{});
                                printTorepl(.{ .structValue = p });
                                std.debug.print("}}\n", .{});
                            },

                            inline else => |p| {
                                std.debug.print("value : {} }}\n", .{p.value});
                            },
                        };
                }

                // std.debug.print("   : {}\n", .{r.type});
            },
        }
    }
};

/// map (name, runtimevalue)
pub const MapNameProp = std.StringArrayHashMap(RuntimeValue);

pub const StructValue = struct {
    type: ValueType = .Struct,
    properties: MapNameProp = MapNameProp.init(ga),
};

pub const BoolValue = struct {
    type: ValueType = .Bool,
    value: bool = true,
};

pub fn mkBool(b: bool) RuntimeValue {
    return .{ .boolValue = .{ .value = b } };
}

pub const NumberValue = struct {
    type: ValueType = .Number,
    value: f32 = 0,
};

pub fn mkNumber(n: f32) RuntimeValue {
    return .{ .numberValue = .{ .value = n } };
}

pub const NullValue = struct {
    type: ValueType = .Null,
    value: @TypeOf(null) = null,
};

pub fn mkNull() RuntimeValue {
    return .{ .nullValue = .{} };
}
