const std = @import("std");
const utils = @import("./utils.zig");

const DbData = struct { clicks: ?u32 };

const JsonDb = struct {
    path: []const u8,
    allocator: std.mem.Allocator,
    data: std.json.Parsed(DbData),

    fn init(path: []const u8, allocator: std.mem.Allocator) !*JsonDb {
        var self = try allocator.create(JsonDb);
        self.allocator = allocator;
        self.path = path;

        // If db file doesn't exist, create the database file
        if (try utils.is_file_exist(self.path) == false) {
            _ = try std.fs.cwd().createFile(self.path, std.fs.File.CreateFlags{ .truncate = true });
            _ = try utils.write_buffer_to_file(self.path, "{}");
        }

        self.data = try read_db(self);
        return self;
    }
    pub fn deinit(self: *JsonDb) void {
        self.data.deinit();
        self.allocator.destroy(self);
    }
    fn read_db(self: *JsonDb) !std.json.Parsed(DbData) {
        const data = try utils.read_file(self.path, self.allocator);
        defer self.allocator.free(data);

        return try std.json.parseFromSlice(DbData, self.allocator, data, .{ .allocate = .alloc_always });
    }
    fn write_db(self: *JsonDb) !void {
        // Clean the file before write
        _ = try utils.delete_file_contents(self.path);

        var file = try std.fs.cwd().openFile(self.path, .{ .mode = std.fs.File.OpenMode.write_only });
        defer file.close();

        // const stringify_options: std.json.StringifyOptions = undefined;
        _ = try std.json.stringify(self.data.value, .{}, file.writer());
        std.debug.print("db written to: {s}\n", .{self.path});
    }
};
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var db = try JsonDb.init("./db.json", allocator);
    defer _ = db.deinit();

    std.debug.print("db path: {s}\n", .{db.path});
    std.debug.print("db data: {any}\n", .{db.data.value});

    db.data.value.clicks = 20;

    _ = try db.write_db();
}
