const std = @import("std");
const stdin = std.io.getStdIn().reader();
const lexer = @import("frontend/lexer.zig");
const parser = @import("frontend/parser.zig");
const inter = @import("runtime/interpreter.zig");
const env = @import("runtime/environment.zig");
const val = @import("runtime/values.zig");

pub fn main() !void {
    std.debug.print("REPL: Dust v0.1\n", .{});

    var p = parser.Parser{};
    var scope = env.Environment{};

    _ = try scope.declareVar("x", .{ .numberValue = .{ .value = 10 } });
    _ = try scope.declareVar("true", .{ .boolValue = .{} });
    _ = try scope.declareVar("false", .{ .boolValue = .{ .value = false } });
    _ = try scope.declareVar("null", .{ .nullValue = .{} });

    while (true) {
        var input: [100]u8 = undefined;

        const inpsize = try stdin.read(&input);

        var source: []const u8 = input[0..inpsize];

        var program = try p.produceACT(source);

        const result = try inter.evaluate(.{ .program = program }, &scope);

        switch (result) {
            .numberValue => std.debug.print("=> {d}\n", .{result.numberValue.value}),
            .nullValue => std.debug.print("=> {}\n", .{result.nullValue.value}),
            .boolValue => std.debug.print("=> {}\n", .{result.boolValue.value}),
        }
    }
}
