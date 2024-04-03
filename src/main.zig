const std = @import("std");

const cli = @import("./cli.zig");
const sys = @import("./sys.zig");

comptime {
    const builtin = @import("builtin");
    if (!builtin.is_test and builtin.os.tag != .linux)
        @compileError("trunner cannot be built for OS other than Linux");
    _ = cli;
    _ = sys;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var config = try cli.parse(alloc);
    const empty = [_:null]?[*:0]const u8{};
    try sys.execve(config.command[0] orelse unreachable, config.command, &empty);
}
