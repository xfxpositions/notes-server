const std = @import("std");
const util = @import("utils.zig");

// Listen in local adress and 4000
// Use 0,0,0,0 for public adress
const port: u16 = 4000;
const address = std.net.Address.initIp4(.{ 127, 0, 0, 1 }, port);

fn handle_connection_wrapper(connection: std.net.StreamServer.Connection, allocator: std.mem.Allocator) void {
    handle_connection(connection, allocator) catch |err| {
        std.debug.print("some error happened while handling connection: {any}\n", .{err});
    };
}

fn handle_connection(connection: std.net.StreamServer.Connection, allocator: std.mem.Allocator) !void {
    std.debug.print("{any}\n", .{connection.address});

    const chunk_size: usize = 1024;
    var chunks_n: u16 = 1; // How many chunks are allocated

    // Declare buffer for read
    const buffer = try allocator.alloc(u8, chunk_size);
    defer allocator.free(buffer);

    //Read with chunks
    while (true) {
        const bytes_read = try connection.stream.read(buffer);
        if (bytes_read == 0) {
            break; // End of the stream
        }

        // Extend buffer size
        chunks_n += 1;
        _ = try allocator.realloc(buffer, chunk_size * chunks_n);

        if (bytes_read < buffer.len) {
            break; // All bytes read
        }
    }
    std.debug.print("got out\n", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // initialize the threadpool
    var pool: std.Thread.Pool = undefined;

    _ = try pool.init(.{ .allocator = allocator }); // Init pool with page_allocator.
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
        _ = try pool.spawn(handle_connection_wrapper, .{ connection, allocator });
    }
}
