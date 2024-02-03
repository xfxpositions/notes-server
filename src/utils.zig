const std = @import("std");

pub fn getFileSize(file_path: []const u8) !u64 {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();
    const stats = try file.stat();
    return stats.size;
}

fn len_hashmap_contents(hashmap: std.StringHashMap([]const u8)) u64 {
    var total: u64 = 0;
    var it = hashmap.iterator();

    while (it.next()) |entry| {
        total += entry.key_ptr.len + entry.value_ptr.len;
    }

    return total;
}

pub fn concatStrings(allocator: std.mem.Allocator, dest: *[]u8, src: []const u8) !void {
    const old_len = dest.len;
    const new_len = old_len + src.len;
    dest.* = try allocator.realloc(dest.*, new_len);

    // @memcpy'yi doğru adreslerle çağır
    @memcpy(dest.*[old_len..new_len], src);
}

/// Read all the file contents to buffer. Returns FileTooBig error if file size is bigger than buffer size.
pub fn read_file(file_path: []const u8, allocator: std.mem.Allocator) ![]u8 {

    // Get file size
    const file_size = try getFileSize(file_path);

    // Alloc the buffer
    var buffer = try allocator.alloc(u8, file_size);

    // Check if file exist
    if (try is_file_exist(file_path) == false) {
        std.debug.print("File not found at: {any}", .{file_path});
        return error.FileNotFound;
    }

    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    _ = try file.readAll(buffer);

    return buffer;
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

pub fn render_template(file_path: []const u8, allocator: std.mem.Allocator, data: std.StringHashMap([]const u8)) ![]const u8 {
    var html_string = try read_file(file_path, allocator);

    const script_head = "<script>\n";
    const script_end = "</script>\n";

    const data_len = len_hashmap_contents(data);
    _ = data_len;

    var buffer = try allocator.alloc(u8, 0);

    _ = try concatStrings(allocator, &buffer, script_head);

    // Append data to script
    var it = data.iterator();

    while (it.next()) |entry| {
        const js_str = try std.fmt.allocPrint(
            allocator,
            "var {s} = '{s}';\n",
            .{ entry.key_ptr.*, entry.value_ptr.* },
        );

        _ = try concatStrings(allocator, &buffer, js_str);
    }

    _ = try concatStrings(allocator, &buffer, script_end);
    _ = try concatStrings(allocator, &buffer, html_string);

    return buffer;
}
