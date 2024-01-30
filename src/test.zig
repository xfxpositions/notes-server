const std = @import("std");
const utils = @import("./utils.zig");

test "read file to buffer" {
    // Allocate a buffer of 100 bytes using the testing allocator.
    var buffer = try std.testing.allocator.alloc(u8, 100);
    defer std.testing.allocator.free(buffer); // Ensure buffer is freed after test.
    const file_path = "test_file.txt";

    // Test setup: Create a test file with sample content.
    {
        const file = try std.fs.cwd().createFile(file_path, .{});
        try file.writeAll("Hello, Zig!"); // Write sample content to the file.
        file.close(); // Close the file after writing.
    }

    // Test: Read the file content into the buffer.
    const bytes_read = try utils.read_file_to_buffer(&buffer, file_path);
    try std.testing.expect(bytes_read == 11); // Check if bytes read matches content length.

    // Test teardown: Delete the test file.
    std.fs.cwd().deleteFile(file_path) catch {};
}

test "check if file exists" {
    const file_path = "test_file.txt";

    // Test setup: Create a test file.
    {
        const file = try std.fs.cwd().createFile(file_path, .{});
        file.close(); // Close the file after creation.
    }

    // Test: Check if the file exists.
    const exists = try utils.is_file_exist(file_path);
    try std.testing.expect(exists); // Expect the file to exist.

    // Test teardown: Delete the test file.
    std.fs.cwd().deleteFile(file_path) catch {};
}

test "write buffer to file" {
    const file_path = "test_file.txt";
    const content = "Test content";

    // Test: Write the content from the buffer to the file.
    try utils.write_buffer_to_file(file_path, content);

    // Test: Verify the file content.
    var buffer: [100]u8 = undefined; // Allocate a buffer to read the file content.
    const file = try std.fs.cwd().openFile(file_path, .{});
    const bytes_read = try file.readAll(buffer[0..]); // Read the file content.
    file.close(); // Close the file after reading.
    try std.testing.expectEqualStrings(content, buffer[0..bytes_read]); // Compare the written and read content.

    // Test teardown: Delete the test file.
    std.fs.cwd().deleteFile(file_path) catch {};
}
