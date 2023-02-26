const std = @import("std");
pub const ga = std.heap.page_allocator;

pub const TokenType = enum {
    Number,
    Identifier,
    BinaryOperator,
    LeftBrace, // {
    RightBrace, // }
    LeftParenthesis,
    RightParenthesis,
    Equals, // =
    Colon, // :
    Comma, // ,
    SemiColon, // ;
    Dot, // .
    EOF,

    // private keys
    Let,
    Const,
    Fn,
    Enum,
    Struct,
    Error,
    Return,
    Mut,
};

pub fn keyWord(string: []const u8) TokenType {
    return if (std.mem.eql(u8, string, "fn"))
        .Fn
    else if (std.mem.eql(u8, string, "mut"))
        .Mut
    else if (std.mem.eql(u8, string, "return"))
        .Return
    else if (std.mem.eql(u8, string, "enum"))
        .Enum
    else if (std.mem.eql(u8, string, "let"))
        .Let
    else if (std.mem.eql(u8, string, "const"))
        .Const
    else if (std.mem.eql(u8, string, "struct"))
        .Struct
        // else if (std.mem.eql(u8, string, "null"))
        //     .NullLiteral
    else if (std.mem.eql(u8, string, "error"))
        .Error
    else
        .Identifier;
}

pub const Token = struct {
    value: []const u8,
    type: TokenType,

    fn isNumber(char: u8) bool {
        return switch (char) {
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => true,
            else => false,
        };
    }

    fn isString(char: u8) bool {
        return switch (char) {
            '_', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z' => true,
            else => false,
        };
    }
};

pub fn tokenizer(file: []const u8) !struct {
    trash: std.ArrayList(std.ArrayList(u8)),
    token: std.ArrayList(Token),
} {
    var source: []const u8 = file;
    var trash = std.ArrayList(std.ArrayList(u8)).init(ga);
    var token_list = std.ArrayList(Token).init(ga);

    while (source.len > 0) {
        var token = source[0];

        // TODO: remove this
        var skipDefer = false;

        // remove the first character after the iteration
        // if the character is a special token
        defer {
            if (!skipDefer) source = source[1..];
        }

        // std.debug.print("token:{c}\n", .{token});

        var str = try ga.alloc(u8, 1);
        std.mem.copy(u8, str, &.{token});

        switch (token) {
            // special tokens
            '(' => try token_list.append(Token{ .value = str, .type = .LeftParenthesis }),
            ')' => try token_list.append(Token{ .value = str, .type = .RightParenthesis }),
            '{' => try token_list.append(Token{ .value = str, .type = .LeftBrace }),
            '}' => try token_list.append(Token{ .value = str, .type = .RightBrace }),
            '+', '-', '*', '/', '%' => try token_list.append(Token{ .value = str, .type = .BinaryOperator }),
            '=' => try token_list.append(Token{ .value = str, .type = .Equals }),
            ';' => try token_list.append(Token{ .value = str, .type = .SemiColon }),
            ':' => try token_list.append(Token{ .value = str, .type = .Colon }),
            ',' => try token_list.append(Token{ .value = str, .type = .Comma }),
            '.' => try token_list.append(Token{ .value = str, .type = .Dot }),
            // '"' => try token_list.append(Token{ .value = &.{token}, .type = .DoubleQuote }),
            // '\'' => try token_list.append(Token{ .value = &.{token}, .type = .SingleQuote }),
            '\n', '\r', '\t', ' ' => continue,

            else => {
                // number
                if (Token.isNumber(token)) {
                    var number = std.ArrayList(u8).init(ga);

                    while (source.len > 0 and Token.isNumber(source[0])) {
                        defer source = source[1..];
                        token = source[0];
                        // std.debug.print("n: {c} \n", .{token});
                        try number.append(token);
                        skipDefer = true;
                    }

                    try token_list.append(Token{
                        .value = number.items,
                        .type = .Number,
                    });

                    try trash.append(number);

                    // string case
                } else if (Token.isString(source[0])) {
                    var string = std.ArrayList(u8).init(ga);

                    while (source.len > 0 and Token.isString(source[0])) {
                        defer source = source[1..];
                        token = source[0];
                        // std.debug.print("str: {c} \n", .{token});
                        try string.append(token);
                        skipDefer = true;
                    }

                    try token_list.append(Token{
                        .value = string.items,
                        .type = keyWord(string.items),
                    });

                    try trash.append(string);
                } else {
                    std.log.err("Unknown Character: '{c}'\n", .{token});
                    @panic("TOKEN: Aborting doe the previously error");
                }
            },
        }
    }

    try token_list.append(Token{ .type = .EOF, .value = "End Of File" });

    return .{
        .trash = trash,
        .token = token_list,
    };
}

test "main" {
    var source: []const u8 =
        \\mut x = 10 + 22 - 30 / 100 * 14 ()
    ;

    var token_result = try tokenizer(source);
    var token_list = token_result.token;
    var trash = token_result.trash;

    defer {
        for (trash.items) |item|
            item.deinit();
        trash.deinit();
        token_list.deinit();
    }

    for (token_list.items) |item|
        std.debug.print("value: {s}, type: {}\n", .{ item.value, item.type });
}
