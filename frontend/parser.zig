const std = @import("std");
const ast = @import("ast.zig");
const lexer = @import("lexer.zig");
const inter = @import("../runtime/interpreter.zig");

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
            else => blk: {
                var exp = try this.parseExpr();
                break :blk .{ .expression = exp };
            },
        };
    }

    fn parseExpr(this: *This) !ast.Expression {
        return try this.parseAssignmentExpr();
    }

    fn parseAssignmentExpr(this: *This) !ast.Expression {
        var left = try lexer.ga.create(ast.Expression);
        left.* = try this.parseStructExpr();
        //
        if (this.at().type == .Equals) {
            _ = this.eat();
            var value = try lexer.ga.create(ast.Expression);
            value.* = try this.parseAssignmentExpr();

            // copys
            var lcp = try lexer.ga.create(ast.Expression);
            lcp.* = left.*;

            var vcp = try lexer.ga.create(ast.Expression);
            vcp.* = value.*;

            return .{
                .assignmentExpr = .{
                    .value = vcp,
                    .assigne = lcp,
                },
            };
        }

        return left.*;
    }

    fn parseStructExpr(this: *This) anyerror!ast.Expression {
        // struct{ []Propeties }
        if (this.at().type != .Struct)
            return try this.parseAdditiveExpr();

        _ = this.eat();

        _ = try this.expect(.LeftBrace);

        // array of Propeties
        var prop_list = std.ArrayList(ast.Property).init(lexer.ga);

        while (this.notEOF() and this.at().type != .RightBrace) {

            // { .key1 = val1 [, .key2 = val2] }
            _ = try this.expect(.Dot);

            const key_token = try this.expect(.Identifier);
            const key_value = key_token.value;

            if (this.at().type == .Comma) {
                _ = this.eat();
                try prop_list.append(.{ .key = key_value });
                continue;
            } else if (this.at().type == .RightBrace) {
                try prop_list.append(.{ .key = key_value });
                continue;
            }

            _ = try this.expect(.Equals);

            var value = try lexer.ga.create(ast.Expression);
            value.* = try this.parseExpr();

            try prop_list.append(.{ .key = key_value, .value = value });

            if (this.at().type != .RightBrace) {
                _ = try this.expect(.Comma);
            }
        }

        _ = try this.expect(.RightBrace);

        // for (prop_list.items) |prop| {
        //     std.debug.print("{s} {any}\n", .{ prop.key, prop.value });
        // }

        return .{
            .structLiteral = .{
                .properties = prop_list.items,
            },
        };
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

        const exp = try this.parseExpr();
        const declaration = ast.VarDeclaration{
            // .value = stmt.expression,
            .value = exp,
            .constant = is_const,
            .identifier = identifier,
        };

        _ = try this.expect(.SemiColon);

        return .{ .varDeclaration = declaration };
    }

    fn parseAdditiveExpr(this: *This) !ast.Expression {
        var right = try lexer.ga.create(ast.Expression);
        var left = try lexer.ga.create(ast.Expression);

        // ble: var result = try lexer.ga.create(ast.Statement);

        left.* = try this.parseMultiplicativeExpr(); //

        // parsing the operator
        // 10 + 5 - 2
        while (std.mem.eql(u8, this.at().value, "+") or std.mem.eql(u8, this.at().value, "-")) {
            const op = this.eat().value;

            right.* = try this.parseMultiplicativeExpr();

            var lcp = try lexer.ga.create(ast.Expression);
            var rcp = try lexer.ga.create(ast.Expression);
            rcp.* = right.*;
            lcp.* = left.*;

            left.* = .{
                .binaryExpr = .{
                    .operator = op,
                    .left = lcp,
                    .right = rcp,
                },
            };
        }

        return left.*;
    }

    fn parseMultiplicativeExpr(this: *This) !ast.Expression {
        var right = try lexer.ga.create(ast.Expression);
        var left = try lexer.ga.create(ast.Expression);

        // ble: var result = try lexer.ga.create(ast.Statement);

        // left.* = try this.parsePrimaryExpr(); //
        left.* = try this.parseCallMemberExpr(); //

        while (std.mem.eql(u8, this.at().value, "*") or
            std.mem.eql(u8, this.at().value, "/") or
            std.mem.eql(u8, this.at().value, "%"))
        {
            const op = this.eat().value;

            right.* = try this.parseCallMemberExpr();

            var lcp = try lexer.ga.create(ast.Expression);
            var rcp = try lexer.ga.create(ast.Expression);
            lcp.* = left.*;
            rcp.* = right.*;

            left.* = .{
                .binaryExpr = .{
                    .operator = op,
                    .left = lcp,
                    .right = rcp,
                },
            };
        }

        return left.*;
    }

    // foo.x ()
    fn parseCallMemberExpr(self: *This) anyerror!ast.Expression {
        var member = try self.parseMemberExpr(); // foo.x

        if (self.at().type == .LeftParenthesis)
            return self.parseCallExpr(member); // ()

        return member;
    }

    fn parseCallExpr(self: *This, caller: ast.Expression) anyerror!ast.Expression {
        var call_expr = ast.Expression{
            .callExpr = .{
                .caller = caller,
                .args = try self.parseArgsList(),
            },
        };

        // foo.x()()()
        if (self.at().type == .LeftParenthesis)
            call_expr = try self.parseCallExpr(call_expr);

        return call_expr;
    }

    /// print(x, y, x) => x and y are parameters
    fn parseArgsExpr(self: *This) anyerror![]ast.Expression {
        _ = try self.expect(.LeftParenthesis);

        var args = if (self.at().type == .RightParenthesis)
            try lexer.ga.alloc(ast.Expression)
        else
            try self.parseArgsList();

        _ = try self.expect(.RightParenthesis);

        return args;
    }

    fn parseArgsList(self: *This) anyerror![]ast.Expression {
        var args = std.ArrayList(ast.Expression).init(lexer.ga);

        try args.append(try self.parseAssignmentExpr());

        while (self.at().type == .Comma) {
            _ = self.eat();

            try args.append(try self.parseAssignmentExpr());
        }

        return self;
    }

    fn parseMemberExpr(self: *This) anyerror!ast.Expression {
        return self;
    }

    fn parsePrimaryExpr(self: *This) anyerror!ast.Expression {
        var tk = self.at().type;

        return switch (tk) {
            .Identifier => .{
                .identifier = .{
                    .symbol = self.eat().value,
                },
            },
            .Number => .{
                .numericLiteral = .{
                    .value = try std.fmt.parseFloat(f32, self.eat().value),
                },
            },

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
                @panic("Unexpected TOKEN; [See parser.parsePrimaryExpr]");
            },
        };
    }

    /// return the next token
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

test "main" {
    var source = "10 - 10 + 10";

    var parser = Parser{};
    var program = try parser.produceACT(source);

    std.debug.print("{}\n", .{program.kind});

    for (program.body.?) |*body| {
        std.debug.print("{}\n", .{body.kind()});

        repel(&body.expression);

        std.debug.print("{}", .{body.expression});
        // }
    }

    const result = try inter.evaluate(.{ .program = program });
    std.debug.print("\n=> {}", .{result});
}
