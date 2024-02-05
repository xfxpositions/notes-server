const std = @import("std");
const utils = @import("./utils.zig");

const JsonDb = utils.JsonDb;

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
