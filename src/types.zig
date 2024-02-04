pub const http_method = enum{
    GET,
    POST,
    PUT,
    DELETE
};

pub const http_codes = enum(u16){
    OK = 200,
    NOT_FOUND = 404
};

pub const http_head =
    "HTTP/1.1 200 OK\r\n" ++
    "Connection: close\r\n" ++
    "Content-Type: {s}\r\n" ++
    "Content-Length: {}\r\n" ++
    "\r\n";
    
pub const mimes = .{ .{ ".html", "text/html" }, .{ ".css", "text/css" }, .{ ".map", "application/json" }, .{ ".svg", "image/svg+xml" }, .{ ".jpg", "image/jpg" }, .{ ".png", "image/png" } };
