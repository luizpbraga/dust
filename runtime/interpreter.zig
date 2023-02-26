const ast = @import("../frontend/ast.zig");
const env = @import("environment.zig");
const val = @import("values.zig");
const exp = @import("eval/expression.zig");
const stmt = @import("eval/statemant.zig");
const std = @import("std");

pub fn evaluate(astStmt: ast.Statement, scope: *env.Environment) anyerror!val.RuntimeValue {
    return switch (astStmt.kind()) {
        .Identifier => try exp.evalIdentifier(astStmt.expression.identifier, scope),
        .NumericLiteral => .{ .numberValue = .{ .value = astStmt.expression.numericLiteral.value } },
        // .NullLiteral => .{ .nullValue = .{} },
        .BinaryExpr => try exp.evalBinExpr(astStmt.expression.binaryExpr, scope),
        .AssignmentExpr => try exp.evalAssignment(astStmt.expression.assignmentExpr, scope),
        // Statement
        .Program => try stmt.evalProgram(astStmt.program, scope),
        .VarDeclaration => try stmt.evalVarDeclaration(astStmt.varDeclaration, scope),
        // else => {
        //     std.debug.print("EVALUATION ERROR: astStmt {}\n", .{astStmt});
        //     return error.TokeNotDefined;
        // },
    };
}
// fn evalBinExpr(bexp: ast.BinaryExpr, scope: env.Environment) anyerror!val.RuntimeValue {
//     const left_val = try evaluate(.{ .expression = bexp.left.?.* }, scope);
//     const right_val = try evaluate(.{ .expression = bexp.right.?.* }, scope);

//     if (left_val.haveType() == .Number and right_val.haveType() == .Number) {
//         return try evalNumericBinExp(left_val.numberValue, right_val.numberValue, bexp.operator);
//     }

//     return .{ .nullValue = .{} };
// }

// fn evalNumericBinExp(nl: val.NumberValue, nr: val.NumberValue, op: []const u8) anyerror!val.RuntimeValue {
//     const eql = std.mem.eql;

//     if (eql(u8, op, "/") and nr.value == 0) return error.ZeroDivizion;

//     var result: ?f32 = if (eql(u8, op, "+")) nl.value + nr.value //
//     else if (eql(u8, op, "-")) nl.value - nr.value //
//     else if (eql(u8, op, "*")) nl.value * nr.value //
//     else if (eql(u8, op, "/")) nl.value / nr.value //
//     else if (eql(u8, op, "%")) @rem(nl.value, nr.value) //
//     else null;

//     return if (result) |value| .{ .numberValue = .{ .value = value } } else error.OperatorNotSupported;
// }

// fn evalProgram(prog: ast.Program, scope: env.Environment) anyerror!val.RuntimeValue {
//     var lest_eval = val.RuntimeValue{ .nullValue = .{} };

//     for (prog.body.?) |stmt| {
//         lest_eval = try evaluate(stmt, scope);
//     }

//     return lest_eval;
// }

// fn evalIdentifier(ident: ast.Identifier, scope: env.Environment) anyerror!val.RuntimeValue {
//     var run_val = try scope.lookUp(ident.symbol);
//     return run_val;
// }

// fn evalVarDeclaration(var_decl: ast.VarDeclaration, scope: env.Environment) anyerror!val.RuntimeValue {
//     _ = scope;
//     _ = var_decl;
//     return;
// }

// TODO: astSatement => ast.Program => expression.value
//
