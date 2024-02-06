const std = @import("std");
const utils = @import("./utils.zig");

const JsonDb = utils.JsonDb;
pub fn render_template(file_path: []const u8, allocator: std.mem.Allocator, comptime data: anytype) ![]const u8 {
    _ = data;

    const html_string = try utils.read_file(file_path, allocator);
    defer allocator.free(html_string);

    var buffer = try allocator.alloc(u8, 0);
    var read: usize = 0;
    const len = html_string.len;
    var variable_count: u32 = 0;
    var variable_names = std.ArrayList([]const u8).init(allocator);

    // Find variables
    while (true) {
        std.debug.print("count: {d}\n", .{variable_count});
        std.debug.print("read: {d}\n", .{read});
        std.debug.print("len: {d}\n", .{len});

        var start = std.mem.indexOf(u8, html_string[read..], "_(") orelse 0;

        if (start + read >= len) {
            break;
        }

        start = start + read;

        std.debug.print("read before end: {d}\n", .{read});

        var end = std.mem.indexOf(u8, html_string[(read)..], ")_") orelse break;

        end = read + end + 2; // Turn end to total, indexOf works as relational search

        read = end + 2; // Set offset, needle included

        std.debug.print("start: {d}, end:{d}\n", .{ start, end });
        std.debug.print("string between start and end {s}\n", .{html_string[start..end]});

        const variable_name = html_string[start + 2 .. end - 2];

        // Change variable name as value
        // Split html to 2 first
        var first_part = html_string[0..start];
        var second_part = html_string[start];

        _ = try utils.concat_strings(allocator, &first_part, "variable_value");

        @memcpy(html_string[start + 2 .. end - 2], "variable_value");

        variable_count += 1;

        _ = try variable_names.append(variable_name);

        std.debug.print("---------------------\n", .{});
    }
    defer variable_names.deinit();
    for (variable_names.items) |variable_name| {
        std.debug.print("variable name: {s}\n", .{variable_name});
    }

    // Append the remaining part of the HTML string
    _ = try utils.concat_strings(allocator, &buffer, html_string);

    return buffer;
}
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);

    const start_time = std.time.milliTimestamp();

    const html_string = try render_template("./templates/test.html", allocator, null);
    defer allocator.free(html_string);

    // std.time.sleep(10 * std.time.ns_per_ms);

    const end_time = std.time.milliTimestamp();

    const duration_ms = end_time - start_time;
    _ = duration_ms;

    // Print the results
    // std.debug.print("rendered string: {s}\n", .{html_string});
    // std.debug.print("start: {d}, end: {d}\n", .{ start_time, end_time });

    // std.debug.print("Render duration: {d} ms\n", .{duration_ms});
}
