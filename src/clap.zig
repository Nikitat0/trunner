const std = @import("std");
const process = std.process;
const ArgIteratorPosix = process.ArgIteratorPosix;
const exit = process.exit;

const clap_lexer = @import("./clap/lexer.zig");
const ArgLexer = clap_lexer.ArgLexer;
const Token = clap_lexer.Token;

comptime {
    _ = clap_lexer;
}

pub const usage =
    \\usage: trunner [OPTION]... [--] COMMAND [ARG]...
    \\
;

pub const help = usage ++
    \\Run process in a jail
    \\Example: trunner --time-limit 1000 -- python3 main.py
    \\
    \\General Options:
    \\  -h, --help           Print this help and exit
    \\  -v, --version        Print version information and exit
    \\
;

pub const version =
    \\trunner 0.1.0
    \\
;

pub fn parse() Config {
    var arg_iter = ArgIteratorPosix();
    arg_iter.skip();
    var lexer = ArgLexer(ArgIteratorPosix).init(arg_iter);
    _ = lexer;
}
