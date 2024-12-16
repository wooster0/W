const c = @import("c.zig");
const window = @import("window.zig");
const format = @import("format.zig");

const ExceptionCode = enum {
    unknown_register,
    not_followed_by_goto,
    stack_overflow,
    unknown_instruction,
};

fn handle_exception(code: ExceptionCode) void {
    if (exception_handler == .none) {
        @memset(window.pixels[0 .. window.size * (window.cell_size * window.square_size) * 2], .{ .red = 0, .green = 0, .blue = 0 });
        const explanation = switch (code) {
            // zig fmt: off
            .unknown_register =>     " WITH UNKNOWN REGISTER",
            .not_followed_by_goto => " NOT FOLLOWED BY GOTO ",
            .stack_overflow =>       " CAUSED STACK OVERFLOW",
            .unknown_instruction =>  " IS UNKNOWN           ",
            // zig fmt: on
        };
        var x: u16 = 0;
        inline for (.{ memory[exception_address..][0..4], explanation }) |string| {
            for (string) |character| {
                window.text.draw_character(
                    character,
                    x * window.cell_size,
                    (x / 16) * window.cell_size,
                    .{ .red = 0xff, .green = 0, .blue = 0 },
                );
                x += 1;
            }
        }
        window.redraw = true;
        state = .halt;
    } else {
        xy.x = @intFromEnum(code);
        w = exception_address;
        address = @intFromEnum(exception_handler);
    }
}

// TODO: include this code at the end if there's not already such a label
//       and instead of running this through the assembler include it in byte form directly (which is not even that unreadable)
//GOTO BOOT_END
//BOOT:
//    SETW 0
//    SETX 0
//    SETY 0
//    TRGT W
//    PTR
//    POINTER
//    KEYBOARD   KBD
//    POINTER -> PTR
//    SETW 'W'
//
//    SKBH:
//    SPTH
//
//    REGE
//A
//    SCLR WHITE
//    GOTO 0
//WHITE:
//    DATA $FFFFFF
//BOOT_END:

var w: u32 = 0;
var xy: packed struct(u8) {
    x: u4 = 0,
    y: u4 = 0,
} = .{};
pub var memory: [2 << 15]u8 = undefined;
var target: u8 = 'W';
var decimal = false;
var stack: [256]u32 = undefined;
var stack_pointer: u8 = 0;
var color: [3]u8 = .{ 0xff, 0xff, 0xff };
var exception_handler: enum(u16) { none, _ } = .none;
var exception_address: u16 = undefined;

var address: u16 = 0;

//pub fn initialize() void {
// TODO: special BOOT: and exception: labels that can be replaced by user code
//       the default BOOT: code is going to set the values currently set above.
//       and by default they'll be random.
//const seed = seed: {
//    var timespec: posix.timespec = undefined;
//    posix.clock_gettime(.REALTIME, &timespec) catch break :seed 0;
//    break :seed @as(u64, @truncate(@as(usize, @bitCast(timespec.nsec))));
//};
//var random_number_generator = Random.DefaultPrng.init(seed);
//w = @truncate(random_number_generator.next());
//xy = @bitCast(@as(u8,@truncate(random_number_generator.next())));
//}

fn get_integer() u32 {
    const integer: u32 = @bitCast(memory[address..][0..4].*);
    address +%= 4;
    return integer;
}

fn get_register() u8 {
    const register = memory[address];
    address +%= 1;
    return register;
}

fn mnemonic(string: *const [4:0]u8) u32 {
    return @bitCast(@as([4]u8, string.*));
}

// TODO:
//CALL -> SAVE (ADDRESS) + GOTO
//RETN -> RSTR (ADDRESS) + GOTO

const State = union(enum) { execute_next_instruction, wait_milliseconds: u32, key_handler, halt };
var state: State = .execute_next_instruction;

pub fn process() void {
    switch (state) {
        .execute_next_instruction => execute_next_instruction(),
        .wait_milliseconds => |milliseconds_remaining| {
            // Split up the waiting to keep the program responsive.
            const division = 100;

            const nanoseconds_per_microseconds = 1000;
            const nanoseconds_per_milliseconds = 1000 * nanoseconds_per_microseconds;
            var remaining: c.timespec = undefined;
            if (milliseconds_remaining < division) {
                state = .execute_next_instruction;
                const duration = c.timespec{ .sec = 0, .nsec = milliseconds_remaining * nanoseconds_per_milliseconds };
                _ = c.nanosleep(&duration, &remaining);
            } else {
                // TODO: workaround for (duplicate issue) https://github.com/ziglang/zig/issues/21462:
                //       change State{ to .{ once that issue is fixed.
                state = State{ .wait_milliseconds = milliseconds_remaining -| division };
                const duration = c.timespec{ .sec = 0, .nsec = 100 * nanoseconds_per_milliseconds };
                _ = c.nanosleep(&duration, &remaining);
            }
        },
        .key_handler => {},
        .halt => {},
    }
}

fn execute_next_instruction() void {
    exception_address = address;
    const instruction_operation_code = get_integer();
    switch (instruction_operation_code) {
        mnemonic("ADDI") => {
            const integer = get_integer();
            switch (target) {
                'W' => w += integer,
                'X' => xy.x += @truncate(integer),
                'Y' => xy.y += @truncate(integer),
                'Z' => xy = @bitCast(@as(u8, @bitCast(xy)) + @as(u8, @truncate(integer))),
                else => unreachable,
            }
        },
        mnemonic("CLRS") => {
            const integer = get_integer();
            var clear_color = memory[integer..][0..3].*;
            clear_color = @bitCast(if (@import("builtin").cpu.arch.endian() == .big)
                clear_color
            else
                @as([3]u8, @bitCast(@byteSwap(@as(u24, @bitCast(clear_color))))));
            @memset(window.pixels[0 .. window.size * window.size], window.Color{ .red = clear_color[0], .green = clear_color[1], .blue = clear_color[2] });
            window.redraw = true;
        },
        mnemonic("CPTO") => {
            const destination = get_register();
            const source = target;
            switch (destination) {
                'W' => switch (source) {
                    'W' => {},
                    'X' => w = xy.x,
                    'Y' => w = xy.y,
                    'Z' => w = @as(u8, @bitCast(xy)),
                    else => unreachable,
                },
                'X' => switch (source) {
                    'W' => xy.x = @truncate(w),
                    'X' => {},
                    'Y' => xy.x = xy.y,
                    'Z' => xy.x = @truncate(@as(u8, @bitCast(xy))),
                    else => unreachable,
                },
                'Y' => switch (source) {
                    'W' => xy.y = @truncate(w),
                    'X' => xy.y = xy.x,
                    'Y' => {},
                    'Z' => xy.y = @truncate(@as(u8, @bitCast(xy))),
                    else => unreachable,
                },
                'Z' => switch (source) {
                    'W' => xy = @bitCast(@as(u8, @truncate(w))),
                    'X' => xy = @bitCast(@as(u8, xy.x)),
                    'Y' => xy = @bitCast(@as(u8, xy.y)),
                    'Z' => {},
                    else => unreachable,
                },
                else => return handle_exception(.unknown_register),
            }
        },
        mnemonic("DDEC") => {
            decimal = false;
        },
        mnemonic("DECR") => {
            const register = get_register();
            switch (register) {
                'W' => w -%= 1,
                'X' => xy.x -%= 1,
                'Y' => xy.y -%= 1,
                'Z' => xy = @bitCast(@as(u8, @bitCast(xy)) -% 1),
                else => return handle_exception(.unknown_register),
            }
        },
        mnemonic("DRAW") => {
            const integer = get_integer();
            for (0..16) |y| {
                window.draw_bits(
                    16,
                    @bitCast(memory[integer + y * 4 ..][0..2].*),
                    @as(u16, xy.x) * window.cell_size,
                    ((@as(u16, xy.y) * window.cell_size) + @as(u16, @intCast(y))),
                    .{ .red = color[0], .green = color[1], .blue = color[2] },
                );
            }
            window.redraw = true;
        },
        mnemonic("EDEC") => {
            decimal = true;
        },
        mnemonic("GOTO") => {
            const integer = get_integer();
            address = @truncate(integer);
        },
        mnemonic("HALT") => {
            window.stop = true;
        },
        mnemonic("IFEQ") => {
            const integer = get_integer();

            const next_instruction = get_integer();
            address -%= 4;
            if (next_instruction != mnemonic("GOTO")) {
                return handle_exception(.not_followed_by_goto);
            }

            if (switch (target) {
                'W' => w != integer,
                'X' => xy.x != integer,
                'Y' => xy.y != integer,
                'Z' => @as(u8, @bitCast(xy)) != integer,
                else => unreachable,
            }) {
                // Take the else branch.
                address +%= 8;
            }
        },
        mnemonic("IFNE") => {
            const integer = get_integer();

            const next_instruction = get_integer();
            address -%= 4;
            if (next_instruction != mnemonic("GOTO")) {
                return handle_exception(.not_followed_by_goto);
            }

            if (switch (target) {
                'W' => w == integer,
                'X' => xy.x == integer,
                'Y' => xy.y == integer,
                'Z' => @as(u8, @bitCast(xy)) == integer,
                else => unreachable,
            }) {
                // Take the else branch.
                address +%= 8;
            }
        },
        mnemonic("IFPP") => {
            const next_instruction = get_integer();
            address -%= 4;
            if (next_instruction != mnemonic("GOTO")) {
                return handle_exception(.not_followed_by_goto);
            }

            if (!window.pointer_pressed) {
                // Take the else branch.
                address +%= 8;
            }
        },
        mnemonic("INCR") => {
            const register = get_register();
            switch (register) {
                'W' => w +%= 1,
                'X' => xy.x +%= 1,
                'Y' => xy.y +%= 1,
                'Z' => xy = @bitCast(@as(u8, @bitCast(xy)) +% 1),
                else => return handle_exception(.unknown_register),
            }
            if (decimal) {
                if (xy.x == 10) {
                    xy.x = 0;
                    xy.y += 1;
                }
                if (xy.y == 10) {
                    xy.y = 0;
                }
            }
        },
        mnemonic("LDPP") => {
            xy.x = window.pointer_x;
            xy.y = window.pointer_y;
        },
        mnemonic("LDKK") => {
            w = window.last_pressed_key;
        },
        // TODO: if it turns out using W for this is just too much, the only solution would perhaps be an offset/index register.
        //       INCI
        //       DECI
        //       SETI <- this actually takes a register to copy from
        //       SITW <- or this: "set I to W". W is the only one that makes sense anyway.
        //       CWTI <- "copy W to I"?
        mnemonic("LOAD") => {
            const integer = get_integer() +% w;
            switch (target) {
                'W' => w = @as(u32, @bitCast(memory[integer..][0..4].*)),
                'X' => xy.x = @truncate(memory[integer]),
                'Y' => xy.y = @truncate(memory[integer]),
                'Z' => xy = @bitCast(memory[integer]),
                else => unreachable,
            }
        },
        mnemonic("PRNT") => {
            window.text.draw_character(
                @truncate(w),
                @as(u8, xy.x) * window.cell_size,
                @as(u8, xy.y) * window.cell_size,
                .{ .red = color[0], .green = color[1], .blue = color[2] },
            );
            window.redraw = true;
        },
        mnemonic("RSTR") => {
            stack_pointer, const overflow = @subWithOverflow(stack_pointer, 1);
            if (overflow == 1) return handle_exception(.stack_overflow);
            const register = get_register();
            switch (register) {
                'W' => w = stack[stack_pointer],
                'X' => xy.x = @truncate(stack[stack_pointer]),
                'Y' => xy.y = @truncate(stack[stack_pointer]),
                'Z' => xy = @bitCast(@as(u8, @truncate(stack[stack_pointer]))),
                else => return handle_exception(.unknown_register),
            }
        },
        mnemonic("SAVE") => {
            const register = get_register();
            stack[stack_pointer] = switch (register) {
                'W' => w,
                'X' => xy.x,
                'Y' => xy.y,
                'Z' => @as(u8, @bitCast(xy)),
                else => return handle_exception(.unknown_register),
            };
            stack_pointer +%= 1;
        },
        mnemonic("SCLR") => {
            const integer = get_integer();
            color = memory[integer..][0..3].*;
            color = @bitCast(if (@import("builtin").cpu.arch.endian() == .big)
                color
            else
                @as([3]u8, @bitCast(@byteSwap(@as(u24, @bitCast(color))))));
        },
        mnemonic("SEXH") => {
            const integer = get_integer();
            exception_handler = @enumFromInt(@as(u16, @truncate(integer)));
        },
        mnemonic("SETW") => {
            const integer = get_integer();
            w = integer;
        },
        mnemonic("SETX") => {
            const integer = get_integer();
            xy.x = @truncate(integer);
        },
        mnemonic("SETY") => {
            const integer = get_integer();
            xy.y = @truncate(integer);
        },
        mnemonic("TRGT") => {
            const register = get_register();
            switch (register) {
                'W', 'X', 'Y', 'Z' => {},
                else => return handle_exception(.unknown_register),
            }
            target = register;
        },
        mnemonic("WAIT") => {
            const integer = get_integer();
            // TODO: workaround for (duplicate issue) https://github.com/ziglang/zig/issues/21462:
            //       change State{ to .{ once that issue is fixed.
            state = State{ .wait_milliseconds = integer };
        },
        else => return handle_exception(.unknown_instruction),
    }
}
