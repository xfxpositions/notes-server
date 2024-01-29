const std = @import("std");
const util = @import("utils.zig");

pub fn main() !void {
    _ = try util.write_buffer_to_file("./test2.txt", "kirwe kirwe kirwe\n");
}
