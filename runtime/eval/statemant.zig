const env = @import("../environment.zig");
const ast = @import("../../frontend/ast.zig");
const val = @import("../values.zig");
const inter = @import("../interpreter.zig");

pub fn evalProgram(
    prog: ast.Program,
    scope: *env.Environment,
) anyerror!val.RuntimeValue {
    var lest_eval = val.RuntimeValue{ .nullValue = .{} };

    for (prog.body.?) |stmt| {
        lest_eval = try inter.evaluate(stmt, scope);
    }

    return lest_eval;
}

pub fn evalVarDeclaration(
    decl: ast.VarDeclaration,
    scope: *env.Environment,
) anyerror!val.RuntimeValue {
    //
    const run_val = if (decl.value) |value|
        try inter.evaluate(.{ .expression = value }, scope)
    else
        val.mkNull();

    var res = try scope.declareVar(decl.identifier, run_val, decl.constant);
    return res;
}
