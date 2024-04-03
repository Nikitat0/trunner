const std = @import("std");
const mem = std.mem;
const t = std.testing;

pub const Token = union(enum) {
    opt: []const u8,
    shopt: []const u8,
    val: [:0]const u8,
};

pub fn ArgLexer(comptime I: type) type {
    return struct {
        const Self = @This();

        src: I,
        shopts: []const u8 = "",
        buf: ?Token = null,
        meet_args_sep: bool = false,

        pub fn init(src: I) Self {
            return .{ .src = src };
        }

        pub fn next(self: *Self) ?Token {
            if (self.buf) |tok| {
                defer self.buf = null;
                return tok;
            } else {
                return self._next();
            }
        }

        pub fn peek(self: *Self) ?Token {
            if (self.buf == null)
                self.buf = _next();
            return self.buf;
        }

        fn _next(self: *Self) ?Token {
            if (self.shopts.len != 0) {
                defer self.shopts = self.shopts[1..];
                return .{ .shopt = self.shopts[0..1] };
            }
            if (self.src.next()) |arg| {
                if (self.meet_args_sep or arg[0] != '-') {
                    return .{ .val = arg };
                }
                if (arg.len >= 2 and arg[1] == '-') {
                    if (arg.len == 2) {
                        self.meet_args_sep = true;
                        return self._next();
                    }
                    return .{ .opt = arg[2..] };
                }
                if (arg.len == 1) {
                    return .{ .val = arg };
                }
                self.shopts = arg[1..];
                return self._next();
            }
            return null;
        }
    };
}

pub fn argLexer(src: anytype) ArgLexer(@TypeOf(src)) {
    return ArgLexer(@TypeOf(src)).init(src);
}

const ArgIteratorMock = struct {
    args: [][:0]const u8,

    pub fn init(_args: [][:0]const u8) ArgIteratorMock {
        return .{ .args = _args };
    }

    pub fn next(self: *ArgIteratorMock) ?[:0]const u8 {
        if (self.args.len == 0)
            return null;
        defer self.args = self.args[1..];
        return self.args[0];
    }
};

test "lexer" {
    var args = [_][:0]const u8{
        "--opt",
        "value",
        "-o",
        "-pq",
        "path",
        "--",
        "arg",
        "--now-not-option",
        "--",
    };
    var lexer = ArgLexer(ArgIteratorMock.init(&args));
    try t.expectEqualDeep(Token{ .opt = "opt" }, lexer.next() orelse unreachable);
    try t.expectEqualDeep(Token{ .val = "value" }, lexer.next() orelse unreachable);
    try t.expectEqualDeep(Token{ .shopt = "o" }, lexer.next() orelse unreachable);
    try t.expectEqualDeep(Token{ .shopt = "p" }, lexer.next() orelse unreachable);
    try t.expectEqualDeep(Token{ .shopt = "q" }, lexer.next() orelse unreachable);
    try t.expectEqualDeep(Token{ .val = "path" }, lexer.next() orelse unreachable);
    try t.expectEqualDeep(Token{ .val = "arg" }, lexer.next() orelse unreachable);
    try t.expectEqualDeep(Token{ .val = "--now-not-option" }, lexer.next() orelse unreachable);
    try t.expectEqualDeep(Token{ .val = "--" }, lexer.next() orelse unreachable);
    try t.expect(lexer.next() == null);
}
