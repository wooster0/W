const c = @import("c.zig");
const processor = @import("processor.zig");
const memory = @import("memory.zig");
const wayland = @import("wayland.zig");
pub const text = @import("text.zig");

const client = wayland.unconverted;
const wl = client.wl;
const xdg = client.xdg;

fn fail() noreturn {
    @branchHint(.cold);
    const message = "EXECUTION FAILURE\n";
    const error_file_descriptor = 2;
    _ = c.write(error_file_descriptor, message.ptr, message.len);
    c.exit(1);
}

var wl_surface: *anyopaque = undefined;
var wl_buffer: *anyopaque = undefined;
// TODO: don't make these null? can they ever not be initialized? yes, by an invalid server so check.
var wl_shm: ?*anyopaque = null;
var wl_compositor: ?*anyopaque = null;
var wl_seat: ?*anyopaque = null;
var xdg_wm_base: ?*anyopaque = null;

pub var pointer_x: u4 = 0;
pub var pointer_y: u4 = 0;
pub var pointer_pressed: bool = false;
pub var last_pressed_key: u8 = 0;

const screen_size = 16;
pub const cell_size = 16;
pub const square_size = 2;

pub const size = screen_size * cell_size * square_size;

pub var pixels: [*]Color = undefined;

fn set_pixel(x: u16, y: u16, color: Color) void {
    const index = @as(usize, x) + (size * @as(usize, y));
    pixels[index] = color;
}

pub fn draw_bits(comptime length: comptime_int, bits: @Type(.{ .int = .{ .signedness = .unsigned, .bits = length } }), x: u16, y: u16, color: Color) void {
    var relative_x: u16 = 0;
    while (relative_x != length) : (relative_x += 1) {
        const bit = (bits >> @intCast(relative_x)) & 1;
        if (bit == 1) {
            const absolute_x = (x + relative_x) * square_size;
            const absolute_y = y * square_size;
            draw_square(absolute_x, absolute_y, color);
        }
    }
}

fn draw_square(x: u16, y: u16, color: Color) void {
    var relative_x: u16 = 0;
    while (relative_x < square_size) : (relative_x += 1) {
        var relative_y: u16 = 0;
        while (relative_y < square_size) : (relative_y += 1) {
            set_pixel(x + relative_x, y + relative_y, color);
        }
    }
}

pub var stop = false;
pub var redraw = true;

pub const Color = packed struct {
    blue: u8,
    green: u8,
    red: u8,
    alpha: u8 = 0xff,
};

pub fn open() void {
    // Connect to a display.
    const wl_display = wayland.wl_display_connect(null) orelse fail();
    const wl_registry = wayland.wl_get_registry(wl_display) orelse fail();

    @as(*wl.Registry, @ptrCast(wl_registry)).setListener(wl_registry_listener);

    // Populate wl_compositor, wl_shm, xdg_wm_base, and wl_seat.
    if (wayland.wl_display_roundtrip(wl_display) == -1) fail();

    @as(*xdg.WmBase, @ptrCast(xdg_wm_base)).setListener(xdg_wm_base_listener);
    @as(*wl.Seat, @ptrCast(wl_seat)).setListener(wl_seat_listener);

    const buffer_file_descriptor = c.memfd_create("", 0);
    if (buffer_file_descriptor == -1) fail();

    const buffer_stride = size * @sizeOf(Color);
    const buffer_size = buffer_stride * size;

    if (c.ftruncate(buffer_file_descriptor, buffer_size) == -1) fail();

    pixels = @alignCast(@ptrCast(c.mmap(
        null,
        buffer_size,
        // TODO: no READ permission needed right? does this even make sense?
        //c.PROT.READ |
        c.PROT.WRITE,
        .{ .TYPE = .SHARED },
        buffer_file_descriptor,
        0,
    )));
    if (@intFromPtr(pixels) == -1) fail();
    @memset(pixels[0 .. size * size], .{ .red = 0, .green = 0, .blue = 0 });

    const shm_pool = wayland.wl_shm_create_pool(wl_shm.?, buffer_file_descriptor, buffer_size) orelse fail();

    wl_buffer = wayland.wl_shm_pool_create_buffer(shm_pool, 0, size, size, buffer_stride, .argb8888) orelse fail();

    wl_surface = wayland.wl_compositor_create_surface(wl_compositor.?) orelse fail();
    const xdg_surface = wayland.xdg_wm_base_get_xdg_surface(xdg_wm_base.?, wl_surface) orelse fail();
    const xdg_toplevel = wayland.xdg_surface_get_xdg_toplevel(xdg_surface) orelse fail();

    // We are not going to register a listener for the close event because during a WAIT
    // the event would not fire so the only way to halt the program other than the HALT
    // instruction should be where the program was started.
    @as(*xdg.Surface, @ptrCast(xdg_surface)).setListener(xdg_surface_listener);
    wl.Callback.setListener(@ptrCast(wayland.wl_surface_frame(wl_surface) orelse fail()), wl_surface_frame_listener);

    wayland.xdg_toplevel_set_title(xdg_toplevel, "W");
    wayland.wl_surface_commit(wl_surface);

    while (!stop) {
        if (wayland.wl_display_dispatch(wl_display) == -1) fail();
    }
}

fn wl_registry_listener(wl_registry: *anyopaque, event: wl.Registry.Event) void {
    switch (event) {
        .global => |global| {
            // TODO: when changing wl.Shm or xdg.WmBase to void, binary size increases even though the type is unused and the parameter could be removed.
            if (memory.compare_zero_terminated(global.interface, wayland.wl_compositor_interface.name)) {
                wl_compositor = wayland.wl_registry_bind(wl_registry, global.name, wl.Compositor, &wayland.wl_compositor_interface) orelse fail();
            } else if (memory.compare_zero_terminated(global.interface, wayland.wl_shm_interface.name)) {
                wl_shm = wayland.wl_registry_bind(wl_registry, global.name, wl.Shm, &wayland.wl_shm_interface) orelse fail();
            } else if (memory.compare_zero_terminated(global.interface, wayland.xdg_wm_base_interface.name)) {
                xdg_wm_base = wayland.wl_registry_bind(wl_registry, global.name, xdg.WmBase, &wayland.xdg_wm_base_interface) orelse fail();
            } else if (memory.compare_zero_terminated(global.interface, wayland.wl_seat_interface.name)) {
                wl_seat = wayland.wl_registry_bind(wl_registry, global.name, wl.Seat, &wayland.wl_seat_interface) orelse fail();
            }
        },
        .global_remove => {},
    }
}

fn xdg_surface_listener(xdg_surface: *anyopaque, event: xdg.Surface.Event) void {
    switch (event) {
        .configure => |configure| {
            wayland.xdg_surface_ack_configure(xdg_surface, configure.serial);
            wayland.wl_surface_attach(wl_surface, wl_buffer, 0, 0);
            wayland.wl_surface_commit(wl_surface);
        },
    }
}

fn wl_surface_frame_listener(wl_callback: *anyopaque, _: wl.Callback.Event) void {
    wayland.wl_proxy_destroy(wl_callback);
    wl.Callback.setListener(@ptrCast(wayland.wl_surface_frame(wl_surface) orelse fail()), wl_surface_frame_listener);

    tick();

    if (redraw) {
        wayland.wl_surface_attach(wl_surface, wl_buffer, 0, 0);
        wayland.wl_surface_damage(wl_surface, 0, 0, size, size);
        redraw = false;
    }
    wayland.wl_surface_commit(wl_surface);
}

fn xdg_wm_base_listener(_: *anyopaque, event: xdg.WmBase.Event) void {
    switch (event) {
        .ping => |ping| {
            wayland.xdg_wm_base_pong(xdg_wm_base.?, ping.serial);
        },
    }
}

fn wl_seat_listener(_: *anyopaque, event: wl.Seat.Event) void {
    switch (event) {
        .capabilities => |data| {
            if (data.capabilities.keyboard) {
                const wl_keyboard = wayland.wl_seat_get_keyboard(wl_seat.?) orelse fail();
                @as(*wl.Keyboard, @ptrCast(wl_keyboard)).setListener(wl_keyboard_listener);
            } else {
                // TODO: fail?
            }

            // TODO: use touch too?
            if (data.capabilities.pointer) {
                const wl_pointer = wayland.wl_seat_get_pointer(wl_seat.?) orelse fail();
                @as(*wl.Pointer, @ptrCast(wl_pointer)).setListener(wl_pointer_listener);
            } else {
                // TODO: fail?
            }
        },
        .name => {},
    }
}

fn wl_pointer_listener(_: *anyopaque, event: wl.Pointer.Event) void {
    switch (event) {
        .motion => |motion| {
            pointer_x = @truncate(@as(u24, @bitCast(motion.surface_x.toInt())) / (screen_size * square_size));
            pointer_y = @truncate(@as(u24, @bitCast(motion.surface_y.toInt())) / (screen_size * square_size));
        },
        .button => |button| {
            pointer_pressed = button.state == .pressed;
        },
        else => {},
    }
}

var key_shift = false;

fn wl_keyboard_listener(_: *anyopaque, event: wl.Keyboard.Event) void {
    switch (event) {
        .key => |key| {
            const code = key.key;
            const key_map_rows_unshifted = .{
                .{0x1b} ++ "1234567890-=" ++ .{ 0x08, 0x09 } ++ "qwertyuiop[]" ++ .{0x0a},
                "asdfghjkl;'`",
                "\\zxcvbnm,./",
            };
            const key_map_rows_shifted = .{
                .{0x1b} ++ "!@#$%^&*()_+" ++ .{ 0x08, 0x09 } ++ "QWERTYUIOP{}" ++ .{0x0a},
                "ASDFGHJKL:\"~",
                "|ZXCVBNM<>?",
            };
            const key_map_rows = if (key_shift) key_map_rows_shifted else key_map_rows_unshifted;
            const character = switch (code) {
                1...28 => key_map_rows[0][code - 1],
                30...41 => key_map_rows[1][code - 30],
                43...53 => key_map_rows[2][code - 43],
                57 => ' ',
                else => return,
            };
            last_pressed_key = character;
            //@import("std").debug.print("code={d} -> character=({c}, {x})\n", .{ @as(u8, @intCast(code)), character, character });
        },
        .modifiers => |modifiers| {
            key_shift = modifiers.mods_depressed == 1;
        },
        else => {},
    }
}

fn tick() void {
    processor.process();
}
