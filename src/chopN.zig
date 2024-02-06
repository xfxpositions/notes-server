const std = @import("std");

pub fn chop_n(buffer: *[]u8, n: u16, allocator: std.mem.Allocator) ![]u8 {
    const len = buffer.*.len;

    if (len < n) {
        const new_buffer = try allocator.alloc(u8, 0);
        return new_buffer;
    }

    const new_len = buffer.len - n;

    var new_buffer = try allocator.alloc(u8, new_len);
    @memcpy(new_buffer[0..], buffer.*[n..]);

    return new_buffer;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const str = "123kiwer";

    var buffer = try allocator.alloc(u8, str.len);

    @memcpy(buffer, str);

    std.debug.print("buffer {s}\n", .{buffer});

    buffer = try chop_n(&buffer, 3, allocator);

    defer allocator.free(buffer);
}
