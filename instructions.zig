const Instruction = struct {
    mnemonic: [4]u8,
    argument: enum {
        none,
        integer,
        register,
    },
    description: []const u8,
};

pub const list = [_]Instruction{
    .{
        .mnemonic = "ADDI".*,
        .argument = .integer,
        .description = "ADD INTEGER",
    },
    .{
        .mnemonic = "CLRS".*,
        .argument = .integer,
        .description = "CLEAR SCREEN",
    },
    .{
        .mnemonic = "CPTO".*,
        .argument = .register,
        .description = "COPY REGISTER VALUE TO REGISTER",
    },
    .{
        .mnemonic = "DECR".*,
        .argument = .register,
        .description = "DECREMENT",
    },
    .{
        .mnemonic = "DDEC".*,
        .argument = .none,
        .description = "DISABLE DECIMAL MODE",
    },
    .{
        .mnemonic = "DRAW".*,
        .argument = .integer,
        .description = "DRAW PIXELS",
    },
    .{
        .mnemonic = "EDEC".*,
        .argument = .none,
        .description = "ENABLE DECIMAL MODE",
    },
    .{
        .mnemonic = "GOTO".*,
        .argument = .integer,
        .description = "JUMP TO ADDRESS",
    },
    .{
        .mnemonic = "HALT".*,
        .argument = .none,
        .description = "HALT EXECUTION",
    },
    .{
        .mnemonic = "IFEQ".*,
        .argument = .integer,
        .description = "IF EQUAL, EXECUTE NEXT INSTRUCTION; OTHERWISE SKIP",
    },
    .{
        .mnemonic = "IFNE".*,
        .argument = .integer,
        .description = "IF NOT EQUAL, EXECUTE NEXT INSTRUCTION; OTHERWISE SKIP",
    },
    .{
        .mnemonic = "IFPP".*,
        .argument = .none,
        .description = "IF POINTER PRESSED, EXECUTE NEXT INSTRUCTION; OTHERWISE SKIP",
    },
    .{
        .mnemonic = "INCR".*,
        .argument = .register,
        .description = "INCREMENT",
    },
    .{
        .mnemonic = "LDPP".*,
        .argument = .none,
        .description = "LOAD POINTER POSITION INTO X AND Y",
    },
    .{
        .mnemonic = "LDKK".*,
        .argument = .none,
        .description = "LOAD KEYBOARD KEY INTO W",
    },
    .{
        .mnemonic = "LOAD".*,
        .argument = .integer,
        .description = "LOAD",
    },
    .{
        .mnemonic = "PRNT".*,
        .argument = .none,
        .description = "PRINT W AS CHARACTER TO (X, Y)",
    },
    .{
        .mnemonic = "RSTR".*,
        .argument = .register,
        .description = "POP FROM STACK",
    },
    .{
        .mnemonic = "SAVE".*,
        .argument = .register,
        .description = "PUSH TO STACK",
    },
    .{
        .mnemonic = "SEXH".*,
        .argument = .integer,
        .description = "SET EXCEPTION HANDLER",
    },
    .{
        .mnemonic = "SCLR".*,
        .argument = .integer,
        .description = "SET COLOR",
    },
    .{
        .mnemonic = "SETW".*,
        .argument = .integer,
        .description = "SET W",
    },
    .{
        .mnemonic = "SETX".*,
        .argument = .integer,
        .description = "SET X",
    },
    .{
        .mnemonic = "SETY".*,
        .argument = .integer,
        .description = "SET Y",
    },
    .{
        .mnemonic = "TRGT".*,
        .argument = .register,
        .description = "SET OPERATION TARGET",
    },
    .{
        .mnemonic = "WAIT".*,
        .argument = .integer,
        .description = "DO NOTHING FOR AN AMOUNT OF MILLISECONDS",
    },
};
