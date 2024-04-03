const std = @import("std");
const io = std.io;
const meta = std.meta;
const process = std.process;
const ArgIteratorPosix = process.ArgIteratorPosix;
const exit = process.exit;

const clap_lexer = @import("./cli/lexer.zig");
const argLexer = clap_lexer.argLexer;
const Token = clap_lexer.Token;

const Config = @import("./config.zig");

comptime {
    _ = clap_lexer;
}

pub const usage =
    \\Usage: trunner [OPTION]... [--] COMMAND [ARG]...
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

pub const error_epilogue = "\n" ++ usage ++
    \\Try 'trunner --help' for more information
    \\
;

const ShOpt = enum {
    h,
    v,

    pub fn unshorted(self: ShOpt) Opt {
        return switch (self) {
            .h => Opt.help,
            .v => Opt.version,
        };
    }
};

const Opt = enum {
    help,
    version,
};

pub fn parse(alloc: std.mem.Allocator) !Config {
    var arg_iter = ArgIteratorPosix.init();
    _ = arg_iter.skip();
    var lexer = argLexer(arg_iter);

    var config = Config{ .command = undefined };
    var command = std.ArrayList(?[*:0]const u8).init(alloc);
    var print_help = false;
    var print_version = false;
    while (lexer.next()) |tok| {
        var option: Opt = undefined;
        switch (tok) {
            Token.arg => |arg| {
                try command.append(arg);
                continue;
            },
            Token.opt => |opt| if (meta.stringToEnum(Opt, opt)) |known_opt| {
                option = known_opt;
            } else {
                try error_exit("unknown option --{s}", .{opt});
            },
            Token.shopt => |shopt| if (meta.stringToEnum(ShOpt, shopt)) |known_shopt| {
                option = known_shopt.unshorted();
            } else {
                try error_exit("unknown shorthand -{s}", .{shopt});
            },
        }
        switch (option) {
            .help => print_help = true,
            .version => print_version = true,
        }
    }

    if (print_help or print_version) {
        var stdout = io.bufferedWriter(io.getStdOut().writer());
        var w = stdout.writer();
        if (print_help)
            try w.print(help, .{});
        if (print_help and print_version)
            try w.print("\n", .{});
        if (print_version)
            try w.print(version, .{});
        try stdout.flush();
        exit(0);
    }

    if (command.items.len == 0)
        try error_exit("there is nothing to run", .{});
    config.command = try command.toOwnedSliceSentinel(null);

    return config;
}

pub fn error_exit(comptime fmt: []const u8, args: anytype) !noreturn {
    var stderr = io.bufferedWriter(io.getStdErr().writer());
    var w = stderr.writer();
    try w.print("error: ", .{});
    try w.print(fmt, args);
    try w.print("\n", .{});
    try w.print(error_epilogue, .{});
    try stderr.flush();
    exit(1);
}
