// i used the scanner from https://github.com/ifreund/zig-wayland here and took the generated code and simplified it so including this thing here just in case isaac sues me:
//
// Copyright 2020 Isaac Freund
// 
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

const xdg_shell_protocol_extension = struct {
    const xdg_wm_base_requests = [_]wl_message{
        wl_message{
            .name = "destroy",
            .signature = "",
            .types = null,
        },
        wl_message{
            .name = "create_positioner",
            .signature = "n",
            .types = null,
        },
        wl_message{
            .name = "get_xdg_surface",
            .signature = "no",
            .types = null,
        },
        wl_message{
            .name = "pong",
            .signature = "u",
            .types = null,
        },
    };
    const xdg_wm_base_events = [_]wl_message{
        wl_message{
            .name = "ping",
            .signature = "u",
            .types = null,
        },
    };
    const xdg_wm_base_interface = wl_interface{
        .name = "xdg_wm_base",
        .version = 6,
        .method_count = 4,
        .methods = &xdg_wm_base_requests,
        .event_count = 1,
        .events = &xdg_wm_base_events,
    };
    const xdg_surface_requests = [_]wl_message{
        wl_message{
            .name = "destroy",
            .signature = "",
            .types = null,
        },
        wl_message{
            .name = "get_toplevel",
            .signature = "n",
            .types = null,
        },
        wl_message{
            .name = "get_popup",
            .signature = "n?oo",
            .types = null,
        },
        wl_message{
            .name = "set_window_geometry",
            .signature = "iiii",
            .types = null,
        },
    };
    const xdg_surface_events = [_]wl_message{
        wl_message{
            .name = "configure",
            .signature = "u",
            .types = null,
        },
    };
    const xdg_surface_interface = wl_interface{
        .name = "xdg_surface",
        .version = 6,
        .method_count = 5,
        .methods = &xdg_surface_requests,
        .event_count = 1,
        .events = &xdg_surface_events,
    };
    const xdg_toplevel_requests = [_]wl_message{
        wl_message{
            .name = "destroy",
            .signature = "",
            .types = null,
        },
        wl_message{
            .name = "set_parent",
            .signature = "?o",
            .types = null,
        },
        wl_message{
            .name = "set_title",
            .signature = "s",
            .types = null,
        },
    };
    const xdg_toplevel_events = [_]wl_message{
        wl_message{
            .name = "close",
            .signature = "",
            .types = null,
        },
    };
    const xdg_toplevel_interface = wl_interface{
        .name = "xdg_toplevel",
        .version = 6,
        .method_count = 14,
        .methods = &xdg_toplevel_requests,
        .event_count = 4,
        .events = &xdg_toplevel_events,
    };
};

const wl_argument = extern union {
    /// Signed integer.
    i: i32,
    /// Unsigned integer.
    u: u32,
    /// String.
    s: ?[*:0]const u8,
    /// Object.
    o: ?*anyopaque,
    n: u32,
    h: i32,
};

const wl_interface = extern struct {
    name: [*:0]const u8,
    version: c_int,
    method_count: c_int,
    methods: ?[*]const wl_message,
    event_count: c_int,
    events: ?[*]const wl_message,
};

const wl_message = extern struct {
    name: [*:0]const u8,
    signature: [*:0]const u8,
    types: ?[*]const ?*const wl_interface,
};

pub extern const wl_compositor_interface: wl_interface;
pub extern const wl_shm_interface: wl_interface;
pub extern const wl_seat_interface: wl_interface;
extern const wl_registry_interface: wl_interface;
extern const wl_shm_pool_interface: wl_interface;
extern const wl_buffer_interface: wl_interface;
extern const wl_surface_interface: wl_interface;
extern const wl_callback_interface: wl_interface;
extern const wl_pointer_interface: wl_interface;
extern const wl_keyboard_interface: wl_interface;
pub const xdg_wm_base_interface: wl_interface = xdg_shell_protocol_extension.xdg_wm_base_interface;
pub const xdg_surface_interface: wl_interface = xdg_shell_protocol_extension.xdg_surface_interface;
pub const xdg_toplevel_interface: wl_interface = xdg_shell_protocol_extension.xdg_toplevel_interface;

pub extern fn wl_display_connect(name: ?[*:0]const u8) ?*anyopaque;
pub extern fn wl_display_roundtrip(display: *anyopaque) c_int;
pub extern fn wl_display_dispatch(display: *anyopaque) c_int;
pub extern fn wl_proxy_destroy(proxy: *anyopaque) void;

extern fn wl_proxy_marshal_array_constructor(proxy: *anyopaque, operation: u32, arguments: [*]wl_argument, interface: *const anyopaque) ?*anyopaque;
extern fn wl_proxy_marshal_array(proxy: *anyopaque, operation: u32, args: ?[*]wl_argument) void;

pub fn wl_get_registry(display: *anyopaque) ?*anyopaque {
    var arguments = [_]wl_argument{.{ .o = null }};
    return wl_proxy_marshal_array_constructor(display, 1, @ptrCast(&arguments), &wl_registry_interface);
}

pub fn wl_shm_create_pool(shm: *anyopaque, file_descriptor: i32, size: i32) ?*anyopaque {
    var arguments = [_]wl_argument{
        .{ .o = null },
        .{ .h = file_descriptor },
        .{ .i = size },
    };
    return wl_proxy_marshal_array_constructor(shm, 0, @ptrCast(&arguments), &wl_shm_pool_interface);
}

const Format = enum(c_int) { argb8888 = 0 };
pub fn wl_shm_pool_create_buffer(shm_pool: *anyopaque, offset: i32, width: i32, height: i32, stride: i32, format: Format) ?*anyopaque {
    var arguments = [_]wl_argument{
        .{ .o = null },
        .{ .i = offset },
        .{ .i = width },
        .{ .i = height },
        .{ .i = stride },
        .{ .u = @as(u32, @intCast(@intFromEnum(format))) },
    };
    return wl_proxy_marshal_array_constructor(shm_pool, 0, &arguments, &wl_buffer_interface);
}

pub fn wl_compositor_create_surface(compositor: *anyopaque) ?*anyopaque {
    var arguments = [_]wl_argument{.{ .o = null }};
    return wl_proxy_marshal_array_constructor(compositor, 0, &arguments, &wl_surface_interface);
}

pub fn xdg_wm_base_get_xdg_surface(wm_base: *anyopaque, _surface: *anyopaque) ?*anyopaque {
    var arguments = [_]wl_argument{
        .{ .o = null },
        .{ .o = @ptrCast(_surface) },
    };
    return wl_proxy_marshal_array_constructor(wm_base, 2, &arguments, &xdg_surface_interface);
}

pub fn xdg_surface_get_xdg_toplevel(surface: *anyopaque) ?*anyopaque {
    var arguments = [_]wl_argument{.{ .o = null }};
    return wl_proxy_marshal_array_constructor(surface, 1, &arguments, &xdg_toplevel_interface);
}

pub fn xdg_surface_ack_configure(surface: *anyopaque, serial: u32) void {
    var arguments = [_]wl_argument{
        .{ .u = serial },
    };
    wl_proxy_marshal_array(surface, 4, &arguments);
}

pub fn wl_surface_attach(surface: *anyopaque, buffer: ?*anyopaque, x: i32, y: i32) void {
    var arguments = [_]wl_argument{
        .{ .o = @ptrCast(buffer) },
        .{ .i = x },
        .{ .i = y },
    };
    wl_proxy_marshal_array(surface, 1, &arguments);
}

pub fn wl_surface_damage(surface: *anyopaque, x: i32, y: i32, width: i32, height: i32) void {
    var arguments = [_]wl_argument{
        .{ .i = x },
        .{ .i = y },
        .{ .i = width },
        .{ .i = height },
    };
    wl_proxy_marshal_array(surface, 2, &arguments);
}

pub fn wl_surface_frame(surface: *anyopaque) ?*anyopaque {
    var arguments = [_]wl_argument{.{ .o = null }};
    return wl_proxy_marshal_array_constructor(surface, 3, &arguments, &wl_callback_interface);
}

pub fn wl_surface_commit(surface: *anyopaque) void {
    wl_proxy_marshal_array(surface, 6, null);
}

pub fn wl_registry_bind(registry: *anyopaque, name: u32, comptime T: type, interface: *const wl_interface) ?*anyopaque {
    // TODO: when removing this comptime parameter, binary size increases.....
    _ = T;
    const version_to_construct = 1;
    var arguments = [_]wl_argument{
        .{ .u = name },                 .{ .s = interface.name },
        .{ .u = version_to_construct }, .{ .o = null },
    };
    return wl_proxy_marshal_array_constructor(registry, 0, &arguments, @ptrCast(interface));
}

pub fn xdg_toplevel_set_title(toplevel: *anyopaque, title: [*:0]const u8) void {
    var arguments = [_]wl_argument{.{ .s = title }};
    wl_proxy_marshal_array(toplevel, 2, &arguments);
}

pub fn xdg_wm_base_pong(wm_base: *anyopaque, serial: u32) void {
    var arguments = [_]wl_argument{.{ .u = serial }};
    wl_proxy_marshal_array(wm_base, 3, &arguments);
}

pub fn wl_seat_get_pointer(seat: *anyopaque) ?*anyopaque {
    var arguments = [_]wl_argument{.{ .o = null }};
    return wl_proxy_marshal_array_constructor(seat, 0, &arguments, &wl_pointer_interface);
}

pub fn wl_seat_get_keyboard(seat: *anyopaque) ?*anyopaque {
    var arguments = [_]wl_argument{.{ .o = null }};
    return wl_proxy_marshal_array_constructor(seat, 1, &arguments, &wl_keyboard_interface);
}

pub const unconverted = struct {
    const Array = extern struct {
        size: usize,
        alloc: usize,
        data: ?*anyopaque,
    };

    const Fixed = enum(i32) {
        _,
        pub fn toInt(f: Fixed) i24 { return @truncate(@intFromEnum(f) >> 8); }
    };

    pub fn Dispatcher(comptime Object: type) type {
        const Payload = Object.Event;
        return struct {
            pub fn dispatcher(
                implementation: ?*const anyopaque,
                object: *wl.Proxy,
                operation: u32,
                _: *const wl_message,
                arguments: [*]wl_argument,
            ) callconv(.C) c_int {
                inline for (@typeInfo(Payload).@"union".fields, 0..) |payload_field, payload_num| {
                    if (payload_num == operation) {
                        var payload_data: payload_field.type = undefined;
                        if (payload_field.type != void) {
                            inline for (@typeInfo(payload_field.type).@"struct".fields, 0..) |f, i| {
                                switch (@typeInfo(f.type)) {
                                    .int, .@"struct" => @field(payload_data, f.name) = @as(f.type, @bitCast(arguments[i].u)),
                                    .pointer, .optional => @field(payload_data, f.name) = @as(f.type, @ptrFromInt(@intFromPtr(arguments[i].o))),
                                    .@"enum" => @field(payload_data, f.name) = @as(f.type, @enumFromInt(arguments[i].i)),
                                    else => unreachable,
                                }
                            }
                        }

                        const HandlerFn = fn (*Object, Payload) void;
                        @as(*const HandlerFn, @ptrCast(@alignCast(implementation)))(
                            @as(*Object, @ptrCast(object)),
                            @unionInit(Payload, payload_field.name, payload_data),
                        );

                        return 0;
                    }
                }
                unreachable;
            }
        };
    }

    pub const wl = struct {
        pub const Keyboard = opaque {
            pub const generated_version = 2;
            pub const getInterface = wl.keyboard.getInterface;
            pub const KeymapFormat = wl.keyboard.KeymapFormat;
            pub const KeyState = wl.keyboard.KeyState;
            pub fn setQueue(_keyboard: *Keyboard, _queue: *wl.EventQueue) void {
                const _proxy: *wl.Proxy = @ptrCast(_keyboard);
                _proxy.setQueue(_queue);
            }
            pub const Event = union(enum) {
                keymap: struct {
                    format: KeymapFormat,
                    fd: i32,
                    size: u32,
                },
                enter: struct {
                    serial: u32,
                    surface: ?*anyopaque,
                    keys: *Array,
                },
                leave: struct {
                    serial: u32,
                    surface: ?*anyopaque,
                },
                key: struct {
                    serial: u32,
                    time: u32,
                    key: u32,
                    state: KeyState,
                },
                modifiers: struct {
                    serial: u32,
                    mods_depressed: u32,
                    mods_latched: u32,
                    mods_locked: u32,
                    group: u32,
                },
            };
            pub inline fn setListener(
                _keyboard: *Keyboard,
                _listener: *const fn (keyboard: *anyopaque, event: Event) void,
            ) void {
                const _proxy: *wl.Proxy = @ptrCast(_keyboard);
                if (_proxy.wl_proxy_add_dispatcher(Dispatcher(Keyboard).dispatcher, _listener, null) != 0) unreachable;
            }
            pub fn destroy(_keyboard: *Keyboard) void {
                const _proxy: *wl.Proxy = @ptrCast(_keyboard);
                _proxy.destroy();
            }
        };
        pub const Pointer = opaque {
            pub const getInterface = wl.pointer.getInterface;
            pub const Error = wl.pointer.Error;
            pub const ButtonState = wl.pointer.ButtonState;
            pub const Axis = wl.pointer.Axis;
            pub const AxisSource = wl.pointer.AxisSource;
            pub const AxisRelativeDirection = wl.pointer.AxisRelativeDirection;
            pub fn setQueue(_pointer: *Pointer, _queue: *wl.EventQueue) void {
                const _proxy: *wl.Proxy = @ptrCast(_pointer);
                _proxy.setQueue(_queue);
            }
            pub const Event = union(enum) {
                leave: struct {
                    serial: u32,
                    surface: ?*anyopaque,
                },
                motion: struct {
                    time: u32,
                    surface_x: Fixed,
                    surface_y: Fixed,
                },
                button: struct {
                    serial: u32,
                    time: u32,
                    button: u32,
                    state: ButtonState,
                },
            };
            pub inline fn setListener(
                _pointer: *Pointer,
                _listener: *const fn (pointer: *anyopaque, event: Event) void,
            ) void {
                const _proxy: *wl.Proxy = @ptrCast(_pointer);
                if (_proxy.wl_proxy_add_dispatcher(Dispatcher(Pointer).dispatcher, _listener, null) != 0) unreachable;
            }
        };

        pub const seat = struct {
            pub const Capability = packed struct(u32) {
                pointer: bool = false,
                keyboard: bool = false,
                touch: bool = false,
                _padding: u29 = 0,
                pub const Enum = enum(c_int) {
                    pointer = 1,
                    keyboard = 2,
                    touch = 4,
                    _,
                };
            };
            pub const Error = enum(c_int) {
                missing_capability = 0,
                _,
            };
        };

        pub const pointer = struct {
            pub const Error = enum(c_int) {
                role = 0,
                _,
            };
            pub const ButtonState = enum(c_int) {
                released = 0,
                pressed = 1,
                _,
            };
            pub const Axis = enum(c_int) {
                vertical_scroll = 0,
                horizontal_scroll = 1,
                _,
            };
            pub const AxisSource = enum(c_int) {
                wheel = 0,
                finger = 1,
                continuous = 2,
                _,
            };
            pub const AxisRelativeDirection = enum(c_int) {
                identical = 0,
                inverted = 1,
                _,
            };
        };
        pub const keyboard = struct {
            extern const wl_keyboard_interface: wl_interface;
            pub const KeymapFormat = enum(c_int) {
                no_keymap = 0,
                xkb_v1 = 1,
                _,
            };
            pub const KeyState = enum(c_int) {
                released = 0,
                pressed = 1,
                _,
            };
        };

        pub const Proxy = opaque {
            extern fn wl_proxy_marshal_array(proxy: *Proxy, operation: u32, arguments: ?[*]wl_argument) void;

            extern fn wl_proxy_marshal_array_constructor(
                proxy: *Proxy,
                operation: u32,
                arguments: [*]wl_argument,
                interface: *const wl_interface,
            ) ?*Proxy;

            const DispatcherFn = fn (
                implementation: ?*const anyopaque,
                proxy: *Proxy,
                operation: u32,
                message: *const wl_message,
                arguments: [*]wl_argument,
            ) callconv(.C) c_int;
            /// Returns non-zero if a dispatcher was already added.
            extern fn wl_proxy_add_dispatcher(
                proxy: *Proxy,
                dispatcher: *const DispatcherFn,
                implementation: ?*const anyopaque,
                data: ?*anyopaque,
            ) c_int;
        };

        pub const Registry = opaque {
            pub const Event = union(enum) {
                global: struct {
                    name: u32,
                    interface: [*:0]const u8,
                    version: u32,
                },
                global_remove: struct {
                    name: u32,
                },
            };
            pub inline fn setListener(
                _registry: *Registry,
                _listener: *const fn (registry: *anyopaque, event: Event) void,
            ) void {
                const _proxy: *wl.Proxy = @ptrCast(_registry);
                if (_proxy.wl_proxy_add_dispatcher(Dispatcher(Registry).dispatcher, _listener, null) != 0) unreachable;
            }
        };
        pub const Callback = opaque {
            pub const Event = union(enum) {
                done: struct {
                    callback_data: u32,
                },
            };
            pub inline fn setListener(
                _callback: *Callback,
                _listener: *const fn (callback: *anyopaque, event: Event) void,
            ) void {
                const _proxy: *wl.Proxy = @ptrCast(_callback);
                if (_proxy.wl_proxy_add_dispatcher(Dispatcher(Callback).dispatcher, _listener, null) != 0) unreachable;
            }
        };
        pub const Compositor = opaque {};
        pub const Shm = opaque {};
        pub const Seat = opaque {
            pub const Capability = wl.seat.Capability;
            pub const Event = union(enum) {
                capabilities: struct {
                    capabilities: Capability,
                },
                name: struct {
                    name: [*:0]const u8,
                },
            };
            pub inline fn setListener(
                _seat: *Seat,
                _listener: *const fn (seat: *anyopaque, event: Event) void,
            ) void {
                const _proxy: *wl.Proxy = @ptrCast(_seat);
                if (_proxy.wl_proxy_add_dispatcher(Dispatcher(Seat).dispatcher, _listener, null) != 0) unreachable;
            }
        };
    };

    pub const xdg = struct {
        pub const WmBase = opaque {
            pub const Event = union(enum) {
                ping: struct {
                    serial: u32,
                },
            };
            pub inline fn setListener(
                _wm_base: *WmBase,
                _listener: *const fn (wm_base: *anyopaque, event: Event) void,
            ) void {
                const _proxy: *wl.Proxy = @ptrCast(_wm_base);
                if (_proxy.wl_proxy_add_dispatcher(Dispatcher(WmBase).dispatcher, _listener, null) != 0) unreachable;
            }
        };
        pub const Surface = opaque {
            pub const Event = union(enum) {
                configure: struct {
                    serial: u32,
                },
            };
            pub inline fn setListener(
                _surface: *Surface,
                _listener: *const fn (surface: *anyopaque, event: Event) void,
            ) void {
                const _proxy: *wl.Proxy = @ptrCast(_surface);
                if (_proxy.wl_proxy_add_dispatcher(Dispatcher(Surface).dispatcher, _listener, null) != 0) unreachable;
            }
        };
        pub const Toplevel = opaque {
            pub const Event = union(enum) {
                configure: struct {
                    width: i32,
                    height: i32,
                    states: *Array,
                },
                close: void,
            };
            pub inline fn setListener(
                _toplevel: *Toplevel,
                _listener: *const fn (toplevel: *anyopaque, event: Event) void,
            ) void {
                const _proxy: *wl.Proxy = @ptrCast(_toplevel);
                _proxy.addDispatcher(Dispatcher(Toplevel).dispatcher, _listener);
            }
        };
    };
};
