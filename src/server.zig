const std = @import("std");
const util = @import("utils.zig");

// Listen in local adress and 4000
// Use 0,0,0,0 for public adress
const port: u16 = 4000;
const address = std.net.Address.initIp4(.{ 127, 0, 0, 1 }, port);

fn handle_connection(connection: std.net.StreamServer.Connection) void {
    std.debug.print("{any}\n", .{connection.address});

    //Read with chunks
    const buffer = try std.heap.page_allocator.alloc(u8, 1024);

    const bytes_read = try connection.stream.readAll(buffer);
    _ = bytes_read; // autofix
}

pub fn main() !void {

    // initialize the threadpool
    var pool: std.Thread.Pool = undefined;

    _ = try pool.init(.{ .allocator = std.heap.page_allocator }); // Init pool with page_allocator.
    defer pool.deinit();

    // Accept 16 User requests at the same time.
    // Reuse port and address after it
    const server_config = std.net.StreamServer.Options{ .reuse_address = true, .reuse_port = true, .kernel_backlog = 16 };

    var server = std.net.StreamServer.init(server_config);
    // Stop listening and deinit after main function
    defer server.deinit();
    defer server.close();

    _ = try server.listen(address);
    std.debug.print("Server is listening at {}\n", .{address});

    while (true) {
        const connection = server.accept() catch |err| {
            // You can just use try instead of catch
            std.debug.print("Some error happened while accepting the connection {any}\n", .{err});
            return;
        };
        _ = try pool.spawn(handle_connection, .{connection});
    }
}
