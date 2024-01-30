const std = @import("std");

/// Read all the file contents to buffer. Returns FileTooBig error if file size is bigger than buffer size.
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

/// Check if file exists, returns true if file exist.
pub fn is_file_exist(file_path: []const u8) !bool {
    _ = std.fs.cwd().statFile(file_path) catch |err| {
        switch (err) {
            error.FileNotFound => return false,
            else => return err,
        }
    };
    return true;
}

/// Writes whole buffer to file, creates file if it not exists
pub fn write_buffer_to_file(
    file_path: []const u8,
    buffer: []const u8,
) !void {
    const file_exists = try is_file_exist(file_path);

    // Create file if it's not exists
    if (!file_exists) {
        _ = try std.fs.cwd().createFile(file_path, .{});
    }
    var file = try std.fs.cwd().openFile(file_path, .{ .mode = std.fs.File.OpenMode.write_only });
    defer file.close();

    _ = try file.writeAll(buffer);

    std.debug.print("Contents written to file {s}\n", .{file_path});
}
