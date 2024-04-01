const std = @import("std");
const clap = @import("./clap.zig");
comptime {
    _ = clap;
}

pub fn main() !void {
    var config = clap.parse();
    _ = config;
}
