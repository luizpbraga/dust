// -----------------------------------------------------------
// --------------          AST TYPES        ------------------
// ---     Defines the structure of our languages AST      ---
// -----------------------------------------------------------
//
//
pub const NodeType = enum {
    // Statement
    Program,
    VarDeclaration,
    // Expressions
    NumericLiteral,
    Identifier,
    BinaryExpr,
    // NullLiteral,
};

pub const Statement = union(enum) {
    // a program contains Stmt
    program: Program,
    // An expression return a value
    expression: Expression,
    //
    varDeclaration: VarDeclaration,

    pub fn kind(self: @This()) NodeType {
        return switch (self) {
            .program => .Program,
            .varDeclaration => .VarDeclaration,
            .expression => |ex| switch (ex) {
                .binaryExpr => .BinaryExpr,
                .identifier => .Identifier,
                .numericLiteral => .NumericLiteral,
                // .nullLiteral => .NullLiteral,
            },
        };
    }
};
pub const VarDeclaration = struct {
    kind: NodeType = .VarDeclaration,
    constant: bool = false,
    identifier: []const u8,
    value: ?Expression = null,
};

pub const Program = struct {
    kind: NodeType = .Program,
    body: ?[]Statement = null,
};

pub const Expression = union(enum) {
    binaryExpr: BinaryExpr,
    identifier: Identifier,
    numericLiteral: NumericLiteral,
    // nullLiteral: NullLiteral,
};

pub const BinaryExpr = struct {
    kind: NodeType = .BinaryExpr,
    left: ?*Expression = null,
    right: ?*Expression = null,
    operator: []const u8,
};

pub const Identifier = struct {
    kind: NodeType = .Identifier,
    symbol: []const u8,
};

pub const NumericLiteral = struct {
    kind: NodeType = .NumericLiteral,
    value: f32,
};

// pub const NullLiteral = struct {
//     kind: NodeType = .NullLiteral,
//     value: []const u8 = "null",
// };
