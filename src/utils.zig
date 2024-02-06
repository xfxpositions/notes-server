const std = @import("std");

pub fn getFileSize(file_path: []const u8) !u64 {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();
    const stats = try file.stat();
    return stats.size;
}

pub fn len_hashmap_contents(hashmap: std.StringHashMap([]const u8)) u64 {
    var total: u64 = 0;
    var it = hashmap.iterator();

    while (it.next()) |entry| {
        total += entry.key_ptr.len + entry.value_ptr.len;
    }

    return total;
}

pub fn concat_strings(allocator: std.mem.Allocator, dest: *[]u8, src: []const u8) !void {
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
    const buffer = try allocator.alloc(u8, file_size);

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

pub fn delete_file_contents(file_path: []const u8) !void {
    const file = try std.fs.cwd().openFile(file_path, .{ .mode = std.fs.File.OpenMode.write_only });
    defer file.close();

    _ = try file.setEndPos(0);
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

pub const EntryInfo = struct {
    name: []const u8,
    is_dir: bool,
};

pub fn list_dir_contents(path: []const u8, allocator: std.mem.Allocator) !std.ArrayList(EntryInfo) {
    var dir = try std.fs.cwd().openIterableDir(path, .{});
    defer dir.close();

    var list = std.ArrayList(EntryInfo).init(allocator);

    var it = dir.iterate();
    while (try it.next()) |entry| {
        const is_dir = entry.kind == std.fs.File.Kind.directory;

        // Copy entry name
        const name = try allocator.alloc(u8, entry.name.len);
        @memcpy(name[0..entry.name.len], entry.name);

        try list.append(EntryInfo{ .name = name, .is_dir = is_dir });
    }

    return list;
}

pub fn render_template(file_path: []const u8, allocator: std.mem.Allocator, data: ?std.StringHashMap([]const u8)) ![]const u8 {
    const html_string = try read_file(file_path, allocator);

    const script_head = "<script>\n";
    const script_end = "</script>\n";

    var buffer = try allocator.alloc(u8, 0);

    _ = try concat_strings(allocator, &buffer, script_head);

    if (data) |data_unwrapped| {
        // Append data to script
        var it = data_unwrapped.iterator();

        while (it.next()) |entry| {
            const js_str = try std.fmt.allocPrint(
                allocator,
                "let {s} = `{s}`;\n",
                .{ entry.key_ptr.*, entry.value_ptr.* },
            );

            _ = try concat_strings(allocator, &buffer, js_str);
        }
    }

    _ = try concat_strings(allocator, &buffer, script_end);
    _ = try concat_strings(allocator, &buffer, html_string);

    return buffer;
}

pub const DbData = struct { clicks: ?u32 };

pub const JsonDb = struct {
    path: []const u8,
    allocator: std.mem.Allocator,
    data: std.json.Parsed(DbData),

    pub fn init(path: []const u8, allocator: std.mem.Allocator) !*JsonDb {
        var self = try allocator.create(JsonDb);
        self.allocator = allocator;
        self.path = path;

        // If db file doesn't exist, create the database file
        if (try is_file_exist(self.path) == false) {
            // _ = try std.fs.cwd().createFile(self.path, std.fs.File.CreateFlags{ .truncate = true });
            // _ = try write_buffer_to_file(self.path, "{}");
            _ = try self.write_db();
        }

        self.data = try read_db(self);
        return self;
    }
    pub fn deinit(self: *JsonDb) void {
        self.data.deinit();
        self.allocator.destroy(self);
    }
    pub fn read_db(self: *JsonDb) !std.json.Parsed(DbData) {
        const data = try read_file(self.path, self.allocator);
        defer self.allocator.free(data);

        return try std.json.parseFromSlice(DbData, self.allocator, data, .{ .allocate = .alloc_always });
    }
    pub fn write_db(self: *JsonDb) !void {
        // Clean the file before write
        _ = try delete_file_contents(self.path);

        var file = try std.fs.cwd().openFile(self.path, .{ .mode = std.fs.File.OpenMode.write_only });
        defer file.close();

        // const stringify_options: std.json.StringifyOptions = undefined;
        _ = try std.json.stringify(self.data.value, .{}, file.writer());
        std.debug.print("db written to: {s}\n", .{self.path});
    }
};
