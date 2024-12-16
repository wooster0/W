const c = @import("c.zig");
const instructions = @import("instructions.zig");
const memory = @import("memory.zig");
const format = @import("format.zig");

fn fail(strings: []const []const u8) noreturn {
    @branchHint(.cold);
    const error_file_descriptor = 2;
    var line_number_buffer: [format.maximum_length(@TypeOf(line_number))]u8 = undefined;
    inline for (.{ "ERROR ON LINE ", format.decimal(line_number, &line_number_buffer), ": " }) |string| {
        _ = c.write(error_file_descriptor, string.ptr, string.len);
    }
    for (strings) |string| {
        _ = c.write(error_file_descriptor, string.ptr, string.len);
    }
    c.exit(1);
}

const LabelDefinition = struct {
    identifier: []const u8,
    address: u32,
    used: bool = false,
    line_number: usize,
};

const LabelUsage = struct {
    identifier: []const u8,
    address: u32,
    line_number: usize,
};

var line_number: usize = 1;

var label_usages: [32]LabelUsage = undefined;
var label_usages_index: u8 = 0;

var label_definitions: [32]LabelDefinition = undefined;
var label_definitions_index: u8 = 0;

var address: u16 = 0;

pub fn assemble(source: []const u8, file_descriptor: c.FileDescriptor) void {
    var lines = memory.Splitter{ .buffer = source, .delimiter = '\n' };
    while (lines.next()) |line| : (line_number += 1) {
        // Handle comments and empty lines.
        var saw_non_space = false;
        var saw_semicolon = false;
        const trimmed_line = for (line, 0..) |character, index| {
            if (character == '#') {
                break line[0..index];
            }
            if (character != ' ') saw_non_space = true;
            if (character == ';') saw_semicolon = true;
        } else line;
        if (!saw_non_space) continue;
        var statements = memory.Splitter{ .buffer = trimmed_line, .delimiter = ';' };
        assemble_statements: while (statements.next()) |statement| {
            const trimmed_statement = memory.trim(statement, " ");
            if (trimmed_statement.len == 0) {
                fail(&.{"UNEXPECTED SEMICOLON WITHOUT INSTRUCTION\n"});
            }

            var tokens = memory.Splitter{ .buffer = trimmed_statement, .delimiter = ' ' };
            const identifier = tokens.next().?;
            const rest = tokens.rest();

            var saw_colon = false;
            for (identifier) |character| {
                if (saw_colon) fail(&.{ "UNEXPECTED CHARACTER '", &.{character}, "' AFTER COLON\n" });
                switch (character) {
                    'A'...'Z', '_' => {},
                    ':' => saw_colon = true,
                    else => fail(&.{ "UNEXPECTED CHARACTER '", &.{character}, "'\n" }),
                }
            }

            if (saw_colon) {
                if (saw_semicolon) fail(&.{"LABEL IN LINE WITH SEMICOLON\n"});
                // Record label definition.
                if (identifier.len == 1) fail(&.{"UNNAMED LABEL\n"});
                const label_definition_identifier = identifier[0 .. identifier.len - 1];
                for (label_definitions[0..label_definitions_index]) |label_definition| {
                    if (memory.compare(label_definition.identifier, label_definition_identifier)) {
                        fail(&.{ "REDEFINITION OF LABEL \"", label_definition_identifier, "\"\n" });
                    }
                }
                label_definitions[label_definitions_index] = .{
                    .identifier = label_definition_identifier,
                    .address = address,
                    .line_number = line_number,
                };
                label_definitions_index += 1;
                if (rest.len != 0) fail(&.{"UNEXPECTED TOKEN AFTER LABEL DEFINITION\n"});
                continue :assemble_statements;
            } else if (identifier.len == 4) {
                const identifier_integer: u32 = @bitCast(identifier[0..4].*);
                // Assemble a real instruction.
                inline for (instructions.list) |instruction| {
                    const instruction_mnemonic_integer: u32 = @bitCast(instruction.mnemonic);
                    if (identifier_integer == instruction_mnemonic_integer) {
                        write_string(file_descriptor, identifier);
                        // Assemble instruction argument.
                        switch (instruction.argument) {
                            .none => if (rest.len != 0) fail(&.{"UNEXPECTED ARGUMENT\n"}),
                            .integer => if (rest.len != 0) {
                                const argument = rest;
                                assemble_integer(file_descriptor, argument);
                            } else {
                                fail(&.{"EXPECTED INTEGER ARGUMENT\n"});
                            },
                            .register => if (rest.len != 0) {
                                const argument = rest;
                                assemble_register(file_descriptor, argument);
                            } else {
                                fail(&.{"EXPECTED REGISTER ARGUMENT\n"});
                            },
                        }
                        continue :assemble_statements;
                    }
                }
                // Assemble pseudo instruction DATA.
                if (identifier_integer == @as(u32, @bitCast(@as([4]u8, "DATA".*)))) {
                    var arguments = memory.Splitter{ .buffer = rest, .delimiter = ',' };
                    while (arguments.next()) |argument| {
                        const trimmed_argument = memory.trim(argument, " ");
                        if (trimmed_argument.len == 0) {
                            fail(&.{"UNEXPECTED COMMA WITHOUT DATA\n"});
                        }
                        assemble_data(file_descriptor, trimmed_argument);
                    }
                    continue :assemble_statements;
                }
            }
            fail(&.{"UNKNOWN INSTRUCTION MNEMONIC\n"});
        }
    }

    write_label_addresses: for (label_usages[0..label_usages_index]) |label_usage| {
        for (label_definitions[0..label_definitions_index]) |*label_definition| {
            if (memory.compare(label_usage.identifier, label_definition.identifier)) {
                const address_bytes: [4]u8 = @bitCast(if (@import("builtin").cpu.arch.endian() == .little)
                    label_definition.address
                else
                    @byteSwap(label_definition.address));
                const byte_count = c.pwrite(file_descriptor, &address_bytes, 4, label_usage.address);
                if (byte_count != 4) {
                    line_number = label_usage.line_number;
                    fail(&.{"OUTPUT FILE COULD NOT BE WRITTEN\n"});
                }
                label_definition.used = true;
                continue :write_label_addresses;
            }
        }
        line_number = label_usage.line_number;
        fail(&.{ "UNKNOWN LABEL \"", label_usage.identifier, "\"\n" });
    }

    for (label_definitions[0..label_definitions_index]) |label_definition| {
        if (!label_definition.used) {
            line_number = label_definition.line_number;
            fail(&.{ "UNUSED LABEL \"", label_definition.identifier, "\"\n" });
        }
    }
}

fn write_integer(file_descriptor: c.FileDescriptor, integer: u32) void {
    const integer_bytes: [4]u8 = @bitCast(integer);
    const byte_count = c.write(file_descriptor, &integer_bytes, integer_bytes.len);
    if (byte_count != integer_bytes.len) fail(&.{"OUTPUT FILE COULD NOT BE WRITTEN\n"});
    address += 4;
}

fn write_string(file_descriptor: c.FileDescriptor, string: []const u8) void {
    const byte_count = c.write(file_descriptor, string.ptr, string.len);
    if (byte_count != string.len) fail(&.{"OUTPUT FILE COULD NOT BE WRITTEN\n"});
    address += @intCast(string.len);
}

fn assemble_integer(file_descriptor: c.FileDescriptor, argument: []const u8) void {
    const integer = switch (argument[0]) {
        'A'...'Z', '_' => integer: {
            // Assemble label.
            for (argument[1..]) |character| {
                switch (character) {
                    'A'...'Z', '_' => {},
                    else => fail(&.{ "UNEXPECTED CHARACTER '", &.{character}, "' IN LABEL NAME\n" }),
                }
            }
            label_usages[label_usages_index] = .{
                .identifier = argument,
                .address = address,
                .line_number = line_number,
            };
            label_usages_index += 1;
            break :integer undefined;
        },
        '0'...'9' => integer: {
            // Assemble decimal.
            var integer: u32 = 0;
            var index: u8 = 0;
            while (index != argument.len) : (index += 1) {
                integer *= 10;
                const character = argument[index];
                switch (character) {
                    '0'...'9' => integer += character - '0',
                    else => fail(&.{ "UNEXPECTED CHARACTER '", &.{character}, "' IN DECIMAL\n" }),
                }
            }
            break :integer integer;
        },
        '$' => integer: {
            // Assemble hexadecimal.
            var integer: u32 = 0;
            var index: u8 = 1;
            while (index != argument.len) : (index += 1) {
                integer *= 16;
                const character = argument[index];
                switch (character) {
                    '0'...'9' => integer += character - '0',
                    'A'...'F' => integer += (character - 'A') + 0xA,
                    else => fail(&.{ "UNEXPECTED CHARACTER '", &.{character}, "' IN HEXADECIMAL\n" }),
                }
            }
            break :integer integer;
        },
        '%' => integer: {
            // Assemble binary.
            var integer: u32 = 0;
            var index: u8 = 1;
            while (index != argument.len) : (index += 1) {
                integer *= 2;
                const character = argument[index];
                switch (character) {
                    '0' => {},
                    '1' => integer += 1,
                    else => fail(&.{ "UNEXPECTED CHARACTER '", &.{character}, "' IN BINARY\n" }),
                }
            }
            break :integer integer;
        },
        '\'' => integer: {
            // Assemble character.
            if (argument.len != 3 or argument[2] != '\'') {
                fail(&.{"INVALID CHARACTER ARGUMENT\n"});
            }
            break :integer argument[1];
        },
        else => fail(&.{ "UNEXPECTED CHARACTER '", &.{argument[0]}, "'\n" }),
    };
    write_integer(file_descriptor, integer);
}

fn assemble_register(file_descriptor: c.FileDescriptor, argument: []const u8) void {
    if (argument.len == 1) {
        switch (argument[0]) {
            'W', 'X', 'Y' => write_string(file_descriptor, &.{argument[0]}),
            else => fail(&.{"UNKNOWN REGISTER NAME\n"}),
        }
    } else if (argument.len == 2) {
        if (argument[0] == 'X' and argument[1] == 'Y') {
            write_string(file_descriptor, "Z");
        } else {
            fail(&.{"UNKNOWN REGISTER NAME\n"});
        }
    } else {
        fail(&.{"UNKNOWN REGISTER NAME\n"});
    }
}

fn assemble_data(file_descriptor: c.FileDescriptor, argument: []const u8) void {
    if (argument[0] == '"') {
        var saw_double_quote = false;
        for (argument[1..], 0..) |character, index| {
            switch (character) {
                '"' => {
                    saw_double_quote = true;
                    if (argument.len - "\"\"".len != index) {
                        fail(&.{"UNEXPECTED CHARACTER AFTER CHARACTER STRING\n"});
                    }
                },
                else => {},
            }
        }
        if (!saw_double_quote) {
            fail(&.{"UNTERMINATED CHARACTER STRING\n"});
        }
        if (argument.len >= 3) {
            write_string(file_descriptor, argument[1 .. argument.len - 1]);
        }
    } else {
        assemble_integer(file_descriptor, argument);
    }
}
