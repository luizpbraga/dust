const std = @import("std");
const ast = @import("ast.zig");
const lexer = @import("lexer.zig");
const inter = @import("../runtime/interpreter.zig");

// *** TODO: Every Function Must Return an Expression

const TokenError = error{
    MISSING_TOKEN,
};

pub const Parser = struct {
    const This = @This();

    tokens: ?[]lexer.Token = null,

    fn at(self: *This) lexer.Token {
        return self.tokens.?[0];
    }

    fn eat(self: *This) lexer.Token {
        var tk = self.at();
        self.tokens = self.tokens.?[1..];
        return tk;
    }

    fn notEOF(this: *@This()) bool {
        return this.tokens.?[0].type != .EOF;
    }

    fn parseStmt(this: *This) !ast.Statement {
        // skiped: no return code
        return switch (this.at().type) {
            .Let, .Const => try this.parseVarDeclaration(),
            else => try this.parseExpr(),
        };
    }

    // TODO: retorn ast.Expression
    fn parseExpr(this: *This) !ast.Statement {
        return try this.parseAssignmentExpr();
    }

    fn parseAssignmentExpr(this: *This) !ast.Statement {
        var left = try lexer.ga.create(ast.Statement);
        left.* = try this.parseAdditiveExpr(); // will be parseObjExpr();
        //
        if (this.at().type == .Equals) {
            _ = this.eat();
            var value = try lexer.ga.create(ast.Statement);
            value.* = try this.parseAssignmentExpr();

            // copys
            var lcp = try lexer.ga.create(ast.Statement);
            lcp.* = left.*;

            var vcp = try lexer.ga.create(ast.Statement);
            vcp.* = value.*;

            return .{
                .expression = .{
                    .assignmentExpr = .{
                        .value = &vcp.expression,
                        .assigne = &lcp.expression,
                    },
                },
            };
        }

        return left.*;
    }

    // LET NAME;
    // (LET | CONST) NAME = EXP;
    fn parseVarDeclaration(this: *This) anyerror!ast.Statement {
        const is_const = this.eat().type == .Const;
        const _identifier = try this.expect(.Identifier);

        // expression
        const identifier = _identifier.value;

        if (this.at().type == .SemiColon) {
            _ = this.eat();
            if (is_const)
                return error.ConstValueNotAssigned;

            return .{ .varDeclaration = .{
                .identifier = identifier,
            } };
        }

        _ = try this.expect(.Equals);

        const stmt = try this.parseExpr();
        const declaration = ast.VarDeclaration{
            .value = stmt.expression,
            .constant = is_const,
            .identifier = identifier,
        };

        _ = try this.expect(.SemiColon);

        return .{ .varDeclaration = declaration };
    }

    fn parseAdditiveExpr(this: *This) !ast.Statement {
        var right = try lexer.ga.create(ast.Statement);
        var left = try lexer.ga.create(ast.Statement);
        // var result = try lexer.ga.create(ast.Statement);

        left.* = try this.parseMultiplicativeExpr(); //

        // parsing the operator
        // 10 + 5 - 2
        while (std.mem.eql(u8, this.at().value, "+") or std.mem.eql(u8, this.at().value, "-")) {
            const op = this.eat().value;

            right.* = try this.parseMultiplicativeExpr();

            var lcp = try lexer.ga.create(ast.Statement);
            lcp.* = left.*;
            var rcp = try lexer.ga.create(ast.Statement);
            rcp.* = right.*;

            left.* = .{
                .expression = .{
                    .binaryExpr = .{
                        .operator = op,
                        .left = &lcp.expression,
                        .right = &rcp.expression,
                    },
                },
            };
        }

        // return result.*;
        return left.*;
    }

    fn parseMultiplicativeExpr(this: *This) !ast.Statement {
        var right = try lexer.ga.create(ast.Statement);
        var left = try lexer.ga.create(ast.Statement);
        // var result = try lexer.ga.create(ast.Statement);

        left.* = try this.parsePrimaryExpr(); //

        // parsing the operator
        while (std.mem.eql(u8, this.at().value, "*") or
            std.mem.eql(u8, this.at().value, "/") or
            std.mem.eql(u8, this.at().value, "%"))
        {
            const op = this.eat().value;

            right.* = try this.parsePrimaryExpr();

            var lcp = try lexer.ga.create(ast.Statement);
            lcp.* = left.*;
            var rcp = try lexer.ga.create(ast.Statement);
            rcp.* = right.*;

            left.* = .{
                .expression = .{
                    .binaryExpr = .{
                        .operator = op,
                        .left = &lcp.expression,
                        .right = &rcp.expression,
                    },
                },
            };
        }

        // return result.*;
        return left.*;
    }

    fn parsePrimaryExpr(self: *This) anyerror!ast.Statement {
        var tk = self.at().type;

        // lest find the statements
        return switch (tk) {
            .Identifier => .{ .expression = .{ .identifier = .{
                .symbol = self.eat().value,
            } } },
            .Number => .{ .expression = .{ .numericLiteral = .{
                .value = try std.fmt.parseFloat(f32, self.eat().value),
            } } },

            .LeftParenthesis => blk: {
                _ = self.eat(); // (
                const value = try self.parseExpr();

                _ = try self.expect(.RightParenthesis);
                // _ = self.eat(); // )
                break :blk value;
            },

            // .NullLiteral => blk: {
            //     _ = self.eat();
            //     break :blk .{ .expression = .{ .nullLiteral = .{} } };
            // },
            else => {
                std.debug.print("ERROR: {s}\n", .{@tagName(tk)});
                @panic("Unexpected TOKEN");
            },
        };
    }

    fn expect(self: *This, t: lexer.TokenType) TokenError!lexer.Token {
        var prev = self.eat();

        if (prev.type != t) {
            std.log.err("PARSER - Expect {}\n", .{t});
            return error.MISSING_TOKEN;
        }

        return prev;
    }

    pub fn produceACT(self: *This, source: []const u8) !ast.Program {
        var token_result = try lexer.tokenizer(source);

        // wee have tokens now!! YEE
        self.tokens = token_result.token.items;

        // std.debug.print("TOKENS::\n", .{});
        // for (self.tokens.?) |tk|
        //     std.debug.print("*\t{s} {}\n", .{ tk.value, tk.type });

        // std.debug.print("{any}", .{self.tokens.?});

        var program = ast.Program{};

        // parser until end of file
        var body_statement = std.ArrayList(ast.Statement).init(lexer.ga);

        while (self.notEOF()) {
            try body_statement.append(try self.parseStmt());
        }

        program.body = body_statement.items;

        return program;
    }
};

// beautiful recursive print
pub fn repel(exp: ?*ast.Expression) void {
    if (exp) |e| switch (e.*) {
        .identifier => |p| std.debug.print("> {} {s}\n", .{ p.kind, p.symbol }),
        .numericLiteral => |p| std.debug.print("> {} {d}\n", .{ p.kind, p.value }),
        // .nullLiteral => |p| std.debug.print("> {} {s}\n", .{ p.kind, p.value }),
        .binaryExpr => |p| {
            std.debug.print("{s}\n", .{p.operator});
            repel(p.left);
            repel(p.right);
        },
    };
}

// pub fn main() !void {
//     var source = "10 - 10 + 10";

//     var parser = Parser{};
//     var program = try parser.produceACT(source);

//     std.debug.print("{}\n", .{program.kind});

//     for (program.body.?) |*body| {
//         std.debug.print("{}\n", .{body.kind()});

//         repel(&body.expression);

//         std.debug.print("{}", .{body.expression});
//         // }
//     }

//     const result = try inter.evaluate(.{ .program = program });
//     std.debug.print("\n=> {}", .{result});
// }
