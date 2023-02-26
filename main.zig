const std = @import("std");
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();
const lexer = @import("frontend/lexer.zig");
const parser = @import("frontend/parser.zig");
const inter = @import("runtime/interpreter.zig");
const env = @import("runtime/environment.zig");
const val = @import("runtime/values.zig");

// ** TODO: FREE THE MEMORY **

fn repl(p: *parser.Parser, scope: *env.Environment) anyerror!void {
    while (true) {
        var input: [100]u8 = undefined;

        std.debug.print("Dust> ", .{});
        const inpsize = try stdin.read(&input);

        var source: []const u8 = input[0..inpsize];

        if (std.mem.eql(u8, source, "exit\n")) {
            std.debug.print("Dust> Salamaleico MF!\n", .{});
            break;
        }

        var program = try p.produceACT(source);

        const result = try inter.evaluate(.{ .program = program }, scope);

        // print value and type
        result.printTorepl();
    }
}

pub fn main() !void {
    var p = parser.Parser{};

    var scope = try env.Environment.init(.{});
    // defer lexer.ga.free(scope);

    var args_iter = std.process.args();
    _ = args_iter.skip();

    const cmd = args_iter.next() orelse "repl";

    // REFATORAR ISSO AAAAAAAAAAAAAAAAAAAA
    if (std.mem.eql(u8, cmd, "repl")) {
        std.debug.print("** REPL: Dust v0.1 **\n", .{});
        std.debug.print("---------------\n", .{});
        try repl(&p, &scope);
    } else {
        if (std.mem.eql(u8, cmd, "run")) {
            const file = args_iter.next();
            if (file) |name| {
                std.debug.print("Dust> file_name: {s}\n", .{name});
                std.debug.print("----------\n", .{});

                var buffer: [1024]u8 = undefined;

                const source = try std.fs.cwd().readFile(name, &buffer);

                var program = try p.produceACT(source);

                const result = try inter.evaluate(.{ .program = program }, &scope);

                // print value and type
                result.printTorepl();
            } else std.debug.print("No file Found\n", .{});
        } else std.debug.print("Command {s} dont exist\n", .{cmd});
    }
}
