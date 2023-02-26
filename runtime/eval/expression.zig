const env = @import("../environment.zig");
const ast = @import("../../frontend/ast.zig");
const val = @import("../values.zig");
const std = @import("std");
const inter = @import("../interpreter.zig");

pub fn evalBinExpr(bexp: ast.BinaryExpr, scope: *env.Environment) anyerror!val.RuntimeValue {
    const left_val = try inter.evaluate(.{ .expression = bexp.left.?.* }, scope);
    const right_val = try inter.evaluate(.{ .expression = bexp.right.?.* }, scope);

    if (left_val.haveType() == .Number and right_val.haveType() == .Number) {
        return try evalNumericBinExp(left_val.numberValue, right_val.numberValue, bexp.operator);
    }

    return .{ .nullValue = .{} };
}

pub fn evalNumericBinExp(nl: val.NumberValue, nr: val.NumberValue, op: []const u8) anyerror!val.RuntimeValue {
    const eql = std.mem.eql;

    if (eql(u8, op, "/") and nr.value == 0) return error.ZeroDivizion;

    var result: ?f32 = if (eql(u8, op, "+")) nl.value + nr.value //
    else if (eql(u8, op, "-")) nl.value - nr.value //
    else if (eql(u8, op, "*")) nl.value * nr.value //
    else if (eql(u8, op, "/")) nl.value / nr.value //
    else if (eql(u8, op, "%")) @rem(nl.value, nr.value) //
    else null;

    return if (result) |value| .{ .numberValue = .{ .value = value } } else error.OperatorNotSupported;
}

pub fn evalIdentifier(ident: ast.Identifier, scope: *env.Environment) anyerror!val.RuntimeValue {
    var run_val = try scope.lookUp(ident.symbol);
    return run_val;
}

pub fn evalAssignment(assExp: ast.AssignmentExpr, scope: *env.Environment) anyerror!val.RuntimeValue {
    if (assExp.assigne.?.kind() != .Identifier)
        return error.InvalidLHS;

    var var_name = assExp.assigne.?.identifier.symbol;
    var var_value = try inter.evaluate(.{ .expression = assExp.value.?.* }, scope);

    return try scope.assigneVar(var_name, var_value);
}

pub fn evalStructExpr(struct_literal: ast.StructLiteral, scope: *env.Environment) anyerror!val.RuntimeValue {
    var final_struct = val.StructValue{};

    // hendle not null keys

    for (struct_literal.properties) |prop| {
        var key = prop.key;
        var value = prop.value;

        var runtime_value = if (value) |x| try inter.evaluate(.{ .expression = x.* }, scope) else try scope.lookUp(key);

        try final_struct.properties.put(key, runtime_value);
    }

    return .{ .structValue = final_struct };
}
