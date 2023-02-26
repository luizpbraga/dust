// -----------------------------------------------------------
// --------------          AST TYPES        ------------------
// -----------------------------------------------------------
//
//
pub const NodeType = enum {
    // Statement
    Program,
    VarDeclaration,
    // Expressions
    AssignmentExpr,
    BinaryExpr,
    // Literals
    Property,
    StructLiteral,
    NumericLiteral,
    Identifier,
};

pub const Statement = union(enum) {
    // a program contains Statement
    program: Program,
    // An expression return a value
    expression: Expression,
    // Guess What?
    varDeclaration: VarDeclaration,

    pub fn kind(self: @This()) NodeType {
        return switch (self) {
            .program => .Program,
            .varDeclaration => .VarDeclaration,
            .expression => |ex| switch (ex) {
                .binaryExpr => .BinaryExpr,
                .assignmentExpr => .AssignmentExpr,
                .identifier => .Identifier,
                .numericLiteral => .NumericLiteral,
                .property => .Property,
                .structLiteral => .StructLiteral,
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
    assignmentExpr: AssignmentExpr,
    property: Property,
    structLiteral: StructLiteral,

    pub fn kind(self: @This()) NodeType {
        return switch (self) {
            .binaryExpr => .BinaryExpr,
            .assignmentExpr => .AssignmentExpr,
            .identifier => .Identifier,
            .numericLiteral => .NumericLiteral,
            .property => .Property,
            .structLiteral => .StructLiteral,
        };
    }
};

pub const AssignmentExpr = struct {
    kind: NodeType = .AssignmentExpr,
    // let x = { ... };
    // x.foo = {...}
    assigne: ?*Expression = null, // string
    value: ?*Expression = null,
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

pub const Property = struct {
    kind: NodeType = .Property,
    key: []const u8,
    value: ?*Expression = null,
};

pub const StructLiteral = struct {
    kind: NodeType = .StructLiteral,
    properties: []Property,
};

// pub const NullLiteral = struct {
//     kind: NodeType = .NullLiteral,
//     value: []const u8 = "null",
// };
