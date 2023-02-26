pub const ValueType = enum {
    Null,
    Number,
    Bool,
};

pub const RuntimeValue = union(enum) {
    numberValue: NumberValue,
    nullValue: NullValue,
    boolValue: BoolValue,

    pub fn haveType(self: @This()) ValueType {
        return switch (self) {
            .numberValue => |p| p.type,
            .nullValue => |p| p.type,
            .boolValue => |p| p.type,
        };
    }
};

pub const BoolValue = struct {
    type: ValueType = .Bool,
    value: bool = true,
};

pub const NumberValue = struct {
    type: ValueType = .Number,
    value: f32 = 0,
};

pub const NullValue = struct {
    type: ValueType = .Null,
    value: @TypeOf(null) = null,
};

pub fn mkNumber(n: f32) RuntimeValue {
    return .{ .numberValue = .{ .value = n } };
}

pub fn mkBool(b: bool) RuntimeValue {
    return .{ .bollValue = .{ .value = b } };
}

pub fn mkNull() RuntimeValue {
    return .{ .nullValue = .{} };
}
