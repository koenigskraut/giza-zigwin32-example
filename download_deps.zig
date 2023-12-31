const std = @import("std");

const cairo_link = "https://github.com/koenigskraut/giza-zigwin32-example/releases/download/v1.0.0/cairo.tar.gz";

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var exists: bool = true;
    std.fs.cwd().access("deps", .{}) catch {
        exists = false;
    };
    if (exists) return;

    try std.fs.cwd().makeDir("deps");
    var cairo_dir = try std.fs.cwd().openDir("deps", .{});
    defer cairo_dir.close();

    var client = std.http.Client{ .allocator = arena.allocator() };
    defer client.deinit();

    const uri = std.Uri.parse(cairo_link) catch unreachable;
    var req = try client.request(.GET, uri, .{ .allocator = arena.allocator() }, .{});
    defer req.deinit();
    try req.start();
    try req.wait();

    var file = try std.fs.cwd().createFile("cairo.tar.gz", .{ .read = true });

    var fifo = std.fifo.LinearFifo(u8, .{ .Static = 4096 }).init();
    defer fifo.deinit();
    try fifo.pump(req.reader(), file.writer());

    try file.seekTo(0);

    var decomp = try std.compress.gzip.decompress(arena.allocator(), file.reader());

    try std.tar.pipeToFileSystem(cairo_dir, decomp.reader(), .{ .mode_mode = .ignore });

    file.close();
    try std.fs.cwd().deleteFile("cairo.tar.gz");
}
