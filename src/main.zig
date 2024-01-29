const std = @import("std");
const types = @import("types.zig");
const string = @import("./zig-string.zig");
// Listen in local adress and 4000
// Use 0,0,0,0 for public adress
const port: u16 = 4000;
const address = std.net.Address.initIp4(.{ 127, 0, 0, 1 }, port);

fn read_file(fpath: *const u8) std.fs.File.ReadError!*u8 {
    _ = fpath; // autofix

}

pub fn main() !void {
    var mystring = try string.String.init_with_contents(std.heap.page_allocator, "Hello");
    
    std.debug.print("mystring: {s}\n", .{mystring.str()});
    std.debug.print("Hello to my notes server\n", .{});
}
