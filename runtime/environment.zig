const std = @import("std");
const val = @import("values.zig");
// pub const ga = std.heap.page_allocator;
const ga = @import("../frontend/lexer.zig").ga;

/// map (name: string, value: val.RuntimeValue)
pub const MapNameVal = std.StringHashMap(val.RuntimeValue);
pub const SetNameConst = std.StringHashMap(void);

pub const Environment = struct {
    /// scope
    parent: ?*Environment = null,

    /// map (name, value)
    variables: MapNameVal = MapNameVal.init(ga),
    /// map (name, void)
    constants: SetNameConst = SetNameConst.init(ga),

    pub fn declareVar(
        this: *@This(),
        var_name: []const u8,
        value: val.RuntimeValue,
        isConst: bool,
    ) anyerror!val.RuntimeValue {
        if (this.variables.contains(var_name)) {
            std.log.err("Cannot declare variable {s}. It's already declared", .{var_name});
            @panic("Duplicate variable daclaration");
        }

        try this.variables.put(var_name, value);

        if (isConst) {
            try this.constants.put(var_name, {});
        }

        return value;
    }

    pub fn assigneVar(this: *@This(), var_name: []const u8, value: val.RuntimeValue) anyerror!val.RuntimeValue {
        var env = try this.resolve(var_name);

        // CANNOT ASSINE TO CONST
        if (env.constants.contains(var_name)) {
            std.log.err("The variable {s} is a constant\n", .{var_name});
            return error.CANNOTASSIGNETOCONST;
        }

        env.variables.put(var_name, var_name);

        return value;
    }

    /// global scope search
    pub fn resolve(this: @This(), var_name: []const u8) anyerror!Environment {
        if (this.variables.contains(var_name))
            return this;

        if (this.parent == null) {
            std.log.err("Variable {s} does not exist", .{var_name});
            return error.VarDoesNotExist;
        }

        return this.parent.?.resolve(var_name);
    }

    pub fn lookUp(this: @This(), var_name: []const u8) anyerror!val.RuntimeValue {
        var env = try this.resolve(var_name);

        return env.variables.get(var_name).?;
    }
};
