const std = @import("std");

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
pub fn write_buffer_to_file(
    file_path: []const u8,
    buffer: []const u8,
) !void {
    _ = buffer; // autofix
    var file = try std.fs.cwd().openFile(file_path, .{ .mode = std.fs.File.OpenMode.write_only });
    const metadata = try file.metadata();
    const kind = metadata.kind();
    const stats = file.stat();
    std.debug.print("stats: {any}", .{stats});

    std.debug.print("kind of file is: {}\n", .{kind});

    defer file.close();

    // _ = try file.writeAll(buffer);

    std.debug.print("Contents written to file {s}\n", .{file_path});
}
