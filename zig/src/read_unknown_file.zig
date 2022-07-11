const std = @import("std");
const os = std.os;

pub fn main() !void {
    _ = std.fs.openFileAbsolute(
        "unknown.txt",
        std.fs.File.OpenFlags{},
    ) catch |e| {
        _ = try std.io.getStdOut().write(@typeName(@TypeOf(e)));
    };
    // error.SharingViolation => {},
    // error.PathAlreadyExists => {},
    // error.FileNotFound => {},
    // error.AccessDenied => {},
    // error.PipeBusy => {},
    // error.NameTooLong => {},
    // error.InvalidUtf8 => {},
    // error.BadPathName => {},
    // error.Unexpected => {},
    // error.SymLinkLoop => {},
    // error.ProcessFdQuotaExceeded => {},
    // error.SystemFdQuotaExceeded => {},
    // error.NoDevice => {},
    // error.SystemResources => {},
    // error.FileTooBig => {},
    // error.IsDir => {},
    // error.NoSpaceLeft => {},
    // error.NotDir => {},
    // error.DeviceBusy => {},
    // error.FileLocksNotSupported => {},
    // error.FileBusy => {},
    // error.WouldBlock => {},
}
