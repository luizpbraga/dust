const std = @import("std");
const stdin = std.io.getStdIn().reader();
const lexer = @import("frontend/lexer.zig");
const parser = @import("frontend/parser.zig");
const inter = @import("runtime/interpreter.zig");
const env = @import("runtime/environment.zig");
const val = @import("runtime/values.zig");

pub fn main() !void {
    std.debug.print("REPL: Dust v0.1\n", .{});
    std.debug.print("---------------\n", .{});

    var p = parser.Parser{};
    var scope = env.Environment{};

    // // GLOBAL VARIABLES
    // _ = try scope.declareVar("x", val.mkNumber(10), false);

    // GLOBAL CONST
    _ = try scope.declareVar("true", val.mkBool(true), true);
    _ = try scope.declareVar("false", val.mkBool(false), true);
    _ = try scope.declareVar("null", val.mkNull(), true);

    while (true) {
        var input: [100]u8 = undefined;

        const inpsize = try stdin.read(&input);

        var source: []const u8 = input[0..inpsize];

        if (std.mem.eql(u8, source, "exit\n")) {
            std.debug.print("> Salamaleico MF!\n", .{});
            break;
        }

        var program = try p.produceACT(source);

        const result = try inter.evaluate(.{ .program = program }, &scope);

        // print value and type
        result.printTorepl();
    }
}
