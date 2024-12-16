const std = @import("std");

pub extern "c" fn write(file_descriptor: FileDescriptor, buffer: [*]const u8, byte_amount: usize) isize;
pub extern "c" fn pwrite(file_descriptor: FileDescriptor, buffer: [*]const u8, byte_amount: usize, offset: usize) isize;
pub extern "c" fn read(file_descriptor: FileDescriptor, buffer: [*]u8, byte_amount: usize) isize;
pub extern "c" fn memfd_create(name: [*:0]const u8, flags: c_uint) c_int;
pub extern "c" fn mmap(address: ?*align(std.mem.page_size) anyopaque, length: usize, protection: c_uint, flags: std.c.MAP, file_descriptor: FileDescriptor, offset: usize) *anyopaque;
pub extern "c" fn openat(file_descriptor: FileDescriptor, path: [*:0]const u8, oflag: std.c.O, mode: std.c.mode_t) c_int;
pub extern "c" fn ftruncate(file_descriptor: FileDescriptor, length: usize) c_int;
pub extern "c" fn nanosleep(duration: *const timespec, remainder: ?*timespec) c_int;
pub extern "c" fn exit(code: c_int) noreturn;
pub const timespec = std.c.timespec;
pub const AT = std.c.AT;
pub const PROT = std.c.PROT;
pub const FileDescriptor = c_int;
