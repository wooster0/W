const c = @import("c.zig");
const instructions = @import("instructions.zig");
const assembler = @import("assembler.zig");
const processor = @import("processor.zig");
const window = @import("window.zig");
const memory = @import("memory.zig");

const runtime_safety = @import("builtin").mode == .Debug or @import("builtin").mode == .ReleaseSafe;
comptime {
    if (!runtime_safety and @sizeOf(anyerror) != 0) unreachable;
}
pub const Panic = if (runtime_safety) @import("std").debug.FormattedPanic else unreachable;

fn fail(strings: []const []const u8) noreturn {
    @branchHint(.cold);
    const error_file_descriptor = 2;
    for (strings) |string| {
        _ = c.write(error_file_descriptor, string.ptr, string.len);
    }
    c.exit(1);
}

pub export fn main(argument_count: c_int, arguments: [*][*:0]c_char) c_int {
    const file_name = if (argument_count >= 2) file_name: {
        break :file_name arguments[1];
    } else {
        print_manual();
        return 0;
    };
    const file_name_length = memory.count_zero_terminated(file_name);
    // TODO: binary size is bigger when this is u1 instead of u8
    var action: enum(u8) { execute, assemble } = .execute;
    var file_name_extension_index: usize = undefined;
    var index: usize = 0;
    while (index != file_name_length) : (index += 1) {
        switch (file_name[index]) {
            '.' => {
                verify_file_name: {
                    if (index == 0) break :verify_file_name;
                    file_name_extension_index = index;
                    index += 1;
                    if (index == file_name_length) break :verify_file_name;
                    if (file_name[index] != 'W') break :verify_file_name;
                    index += 1;
                    if (index != file_name_length) break :verify_file_name;
                    action = .assemble;
                    break;
                }
                fail(&.{"INVALID FILE NAME EXTENSION\n"});
            },
            'A'...'Z', '_' => {},
            else => fail(&.{"INVALID CHARACTER IN FILE NAME\n"}),
        }
    }

    const input_file = c.openat(c.AT.FDCWD, @ptrCast(file_name), .{ .ACCMODE = .RDONLY }, undefined);
    if (input_file == -1) fail(&.{"INPUT FILE COULD NOT BE READ\n"});

    //defer input_file.close();
    var content_buffer: [2 << 15]u8 = undefined;
    const content_length = c.read(input_file, &content_buffer, content_buffer.len);
    if (content_length == -1) fail(&.{"INPUT FILE COULD NOT BE READ\n"});
    const content = content_buffer[0..@intCast(content_length)];

    switch (action) {
        .assemble => {
            file_name[file_name_extension_index] = 0;
            const output_file = c.openat(c.AT.FDCWD, @ptrCast(file_name), .{ .ACCMODE = .WRONLY, .CREAT = true, .TRUNC = true }, 0o666);
            if (output_file == -1) fail(&.{"OUTPUT FILE COULD NOT BE CREATED\n"});
            //defer output_file.close();
            assembler.assemble(content, output_file);
        },
        .execute => {
            processor.memory = content_buffer;
            @memset(processor.memory[@intCast(content_length)..], 0);
            window.open();
        },
    }

    // TODO: either add a SYNC op to 1. redraw and check for mouse/key events
    //       or add POLL or smth to check for key/mouse events manually
    // TODO: to exit the program, (see processor.zig TODO also), use the BOOT code registers ESC to exit.
    //       this is checked every SYNC call. if BOOT is overriden, the program can't be closed normally.
    return 0;
}

fn print_manual() void {
    comptime var manual: []const u8 = "";

    manual = manual ++
        \\MANUAL
        \\======
        \\
        \\
    ;

    inline for (instructions.list) |instruction| {
        const argument = switch (instruction.argument) {
            .none => "NONE",
            .integer => "INTEGER",
            .register => "REGISTER",
        };
        manual = manual ++ instruction.mnemonic;
        manual = manual ++ " (" ++ argument ++ "): ";
        manual = manual ++ switch (instruction.argument) {
            .none => "    ",
            .integer => " ",
            .register => "",
        };
        manual = manual ++ instruction.description;
        manual = manual ++ "\n";
    }

    manual = manual ++
        \\
        \\NONE:     NO ARGUMENT
        \\INTEGER:  32-BIT INTEGER ARGUMENT
        \\REGISTER: W, X, Y, OR XY
        \\
    ;

    const output_file_descriptor = 1;
    _ = c.write(output_file_descriptor, manual.ptr, manual.len);
}
