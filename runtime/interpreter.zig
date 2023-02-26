const ast = @import("../frontend/ast.zig");
const env = @import("environment.zig");
const val = @import("values.zig");
const exp = @import("eval/expression.zig");
const stmt = @import("eval/statemant.zig");
const std = @import("std");
const parser = @import("../frontend/parser.zig");

pub fn evaluate(astStmt: ast.Statement, scope: *env.Environment) anyerror!val.RuntimeValue {
    return switch (astStmt.kind()) {
        .Identifier => try exp.evalIdentifier(astStmt.expression.identifier, scope),
        .StructLiteral => try exp.evalStructExpr(astStmt.expression.structLiteral, scope),
        .NumericLiteral => .{ .numberValue = .{ .value = astStmt.expression.numericLiteral.value } },
        // .NullLiteral => .{ .nullValue = .{} },
        .BinaryExpr => try exp.evalBinExpr(astStmt.expression.binaryExpr, scope),
        .AssignmentExpr => try exp.evalAssignment(astStmt.expression.assignmentExpr, scope),
        // Statement
        .Program => try stmt.evalProgram(astStmt.program, scope),
        .VarDeclaration => try stmt.evalVarDeclaration(astStmt.varDeclaration, scope),
        else => {
            std.debug.print("EVALUATION ERROR: This AST node has not yet been setup.\n", .{});
            std.debug.print("{}\n", .{astStmt});
            return error.TokenNotDefined;
        },
    };
}
