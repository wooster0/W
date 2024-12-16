pub fn find(slice: []const u8, start_index: usize, value: u8) ?usize {
    for (slice[start_index..], start_index..) |other_value, index| {
        if (value == other_value) return index;
    }
    return null;
}

pub fn compare(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |value_a, value_b| {
        if (value_a != value_b) return false;
    }
    return true;
}

pub fn compare_zero_terminated(a: [*:0]const u8, b: [*:0]const u8) bool {
    var index: usize = 0;
    while (a[index] == b[index] and a[index] != 0) : (index += 1) {}
    return a[index] == b[index];
}

pub fn count_zero_terminated(string: [*:0]c_char) usize {
    var index: usize = 0;
    while (true) : (index += 1) if (string[index] == 0) return index;
}

pub fn trim(slice: []const u8, values: []const u8) []const u8 {
    var begin: usize = 0;
    var end: usize = slice.len;
    while (begin < end and find(values, 0, slice[begin]) != null) : (begin += 1) {}
    while (end > begin and find(values, 0, slice[end - 1]) != null) : (end -= 1) {}
    return slice[begin..end];
}

pub const Splitter = struct {
    buffer: []const u8,
    index: ?usize = 0,
    delimiter: u8,

    pub fn next(splitter: *Splitter) ?[]const u8 {
        const start = splitter.index orelse return null;
        const end = if (find(splitter.buffer, start, splitter.delimiter)) |delimiter_start| end: {
            splitter.index = delimiter_start + 1;
            break :end delimiter_start;
        } else end: {
            splitter.index = null;
            break :end splitter.buffer.len;
        };
        return splitter.buffer[start..end];
    }

    pub fn rest(splitter: Splitter) []const u8 {
        const end = splitter.buffer.len;
        const start = splitter.index orelse end;
        return splitter.buffer[start..end];
    }
};
