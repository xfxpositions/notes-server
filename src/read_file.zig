const std = @import("std");
const File = std.fs.File;

const filepath = "./file.txt";

pub fn read_file_to_buffer(buffer: *[]u8, file_path: []const u8) !usize {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const metadata = try file.metadata();
    const file_size = metadata.size();

    // Check file size
    if (file_size > buffer.len) {
        std.debug.print("Buffer size is smaller than file size {any}", .{error.FileTooBig});
        return error.FileTooBig;
    }

    const bytes_read = try file.readAll(buffer.*);

    return bytes_read;
}

pub fn main() !void {
    _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    var buffer = try allocator.alloc(u8, 1024);
    defer allocator.free(buffer);

    const bytes_read = try read_file_to_buffer(&buffer, filepath);

    std.debug.print("{} bytes read\n", .{bytes_read});

    std.debug.print("file contents:\n-------\n{s}\n--------\n", .{buffer[0..bytes_read]});
}
