const std = @import("std");
const os = std.os;
const linux = os.linux;

const CStr = [*:0]const u8;
const CStrArray = [*:null]const ?CStr;

pub fn execve(path: CStr, argv: CStrArray, envp: CStrArray) !noreturn {
    _ = linux.execve(path, argv, envp);
    return error.ExecveError;
}
