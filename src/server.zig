const std = @import("std");
const util = @import("utils.zig");

const Request = struct { method: []const u8, path: []const u8, http_version: []const u8, headers: std.StringHashMap(?[]const u8), body: []const u8 };

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

    const chunk_size: usize = 256;
    var chunk_count: u16 = 1; // How many chunks are allocated
    var total_read: usize = 0;
    var bytes_read: usize = 0;

    // allocate buffer for read
    var buffer = try allocator.alloc(u8, chunk_size);
    defer allocator.free(buffer);

    //Read with chunks
    while (true) {
        bytes_read = try connection.stream.read(buffer[total_read..]);
        if (bytes_read == 0) {
            break; // End of the stream
        }

        total_read += bytes_read;

        std.debug.print("bytes read: {}\n", .{bytes_read});
        std.debug.print("total len of buffer: {}\n", .{buffer.len});

        // Check if we need more size
        if (total_read >= buffer.len) {
            // Extend buffer size
            chunk_count += 1;
            buffer = try allocator.realloc(buffer, chunk_size * chunk_count);
        } else {
            break; // All data read
        }
    }

    std.debug.print("the read buffer is \n{s}\n", .{buffer[0..]});
    std.debug.print("total chunks read: {}\n", .{chunk_count});

    // Split the request
    var parts = std.mem.splitAny(u8, buffer, "\r\n\r\n");
    var head = parts.first();

    // Split head into status line and headers
    var head_parts = std.mem.splitAny(u8, head, "\r\n");

    // Parse status line
    var status_line = head_parts.first();
    var status_line_parts = std.mem.splitScalar(u8, status_line, ' ');

    const method = status_line_parts.first();
    const path = status_line_parts.next().?;
    const http_version = status_line_parts.next().?;

    // Parse raw headers to hashmap
    var headers_lines: std.mem.SplitIterator(u8, std.mem.DelimiterType.scalar) = undefined;

    while (head_parts.next()) |headers_raw| {
        headers_lines = std.mem.splitScalar(u8, headers_raw, '\n');
    }

    var headers = std.StringHashMap(
        ?[]const u8,
    ).init(allocator);

    while (true) {
        const line = headers_lines.next();
        if (line == null) {
            break; // Exit if end of lines
        }

        var line_parts = std.mem.splitScalar(u8, line.?, ':');
        const key = line_parts.first();
        const value: []const u8 = line_parts.next() orelse "";

        _ = try headers.put(key, value);
    }

    // Parse body
    const body = parts.next().?;

    const request: Request = Request{ .method = method, .path = path, .http_version = http_version, .headers = headers, .body = body };
    std.debug.print("request: {any}\n", .{request});
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
