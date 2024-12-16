fn maximum_integer(comptime Type: type) comptime_int {
    const int = @typeInfo(Type).int;
    if (int.bits == 0) return 0;
    return (1 << (int.bits - @intFromBool(int.signedness == .signed))) - 1;
}

pub fn maximum_length(comptime Type: type) comptime_int {
    // TODO: @log10 should support integers
    return @intFromFloat(@log10(@as(comptime_float, maximum_integer(Type))) + 1);
}

pub fn decimal(integer: anytype, buffer: *[maximum_length(@TypeOf(integer))]u8) []const u8 {
    comptime if (buffer.len > 256) unreachable;
    var index: u8 = 0;
    var digits = integer;
    while (digits != 0) : (digits /= 10) {
        const digit: u8 = @intCast(digits % 10);
        buffer[buffer.len - index - 1] = '0' + digit;
        index += 1;
    }
    return buffer[buffer.len - index ..];
}

pub fn hexadecimal(integer: anytype, buffer: *[maximum_length(@TypeOf(integer))]u8) []const u8 {
    comptime if (buffer.len > 256) unreachable;
    var index: u8 = 0;
    var digits = integer;
    while (digits != 0) : (digits /= 16) {
        const digit: u8 = @intCast(digits % 16);
        buffer[buffer.len - index - 1] = switch (digit) {
            0...9 => '0' + digit,
            10...15 => 'A' + digit,
            else => unreachable,
        };
        index += 1;
    }
    return buffer[buffer.len - index ..];
}
