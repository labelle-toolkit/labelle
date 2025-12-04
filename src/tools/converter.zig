//! TexturePacker JSON to Zig .zon Converter
//!
//! Converts TexturePacker JSON atlas files to Zig .zon format for comptime loading.
//!
//! Usage:
//!   zig build converter -- input.json -o output.zon
//!   zig build converter -- input.json  # outputs to stdout
//!
//! The output .zon file can be embedded at comptime:
//!   const frames = @import("sprites_frames.zon");

const std = @import("std");

const Frame = struct {
    x: i32,
    y: i32,
    w: i32,
    h: i32,
    rotated: bool,
    trimmed: bool,
    // Sprite source size (for trimmed sprites)
    source_x: i32,
    source_y: i32,
    source_w: i32,
    source_h: i32,
    // Original size before trimming
    orig_w: i32,
    orig_h: i32,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        printUsage();
        std.process.exit(1);
    }

    var input_path: ?[]const u8 = null;
    var output_path: ?[]const u8 = null;

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "-o") or std.mem.eql(u8, args[i], "--output")) {
            i += 1;
            if (i >= args.len) {
                std.debug.print("Error: -o requires an output path\n", .{});
                std.process.exit(1);
            }
            output_path = args[i];
        } else if (std.mem.eql(u8, args[i], "-h") or std.mem.eql(u8, args[i], "--help")) {
            printUsage();
            std.process.exit(0);
        } else {
            input_path = args[i];
        }
    }

    if (input_path == null) {
        std.debug.print("Error: No input file specified\n", .{});
        printUsage();
        std.process.exit(1);
    }

    // Read input JSON
    const json_content = std.fs.cwd().readFileAlloc(allocator, input_path.?, 10 * 1024 * 1024) catch |err| {
        std.debug.print("Error reading input file '{s}': {}\n", .{ input_path.?, err });
        std.process.exit(1);
    };
    defer allocator.free(json_content);

    // Parse and convert
    const zon_content = try convertJsonToZon(allocator, json_content);
    defer allocator.free(zon_content);

    // Write output
    if (output_path) |path| {
        var file = std.fs.cwd().createFile(path, .{}) catch |err| {
            std.debug.print("Error creating output file '{s}': {}\n", .{ path, err });
            std.process.exit(1);
        };
        defer file.close();
        try file.writeAll(zon_content);
        std.debug.print("Converted {s} -> {s}\n", .{ input_path.?, path });
    } else {
        // Write to stdout
        _ = std.posix.write(std.posix.STDOUT_FILENO, zon_content) catch |err| {
            std.debug.print("Error writing to stdout: {}\n", .{err});
            std.process.exit(1);
        };
    }
}

fn printUsage() void {
    std.debug.print(
        \\TexturePacker JSON to Zig .zon Converter
        \\
        \\Usage:
        \\  converter <input.json> [-o <output.zon>]
        \\
        \\Options:
        \\  -o, --output <path>  Output file path (default: stdout)
        \\  -h, --help           Show this help message
        \\
        \\Examples:
        \\  converter sprites.json -o sprites_frames.zon
        \\  converter sprites.json > sprites_frames.zon
        \\
    , .{});
}

fn convertJsonToZon(allocator: std.mem.Allocator, json_content: []const u8) ![]u8 {
    const parsed = std.json.parseFromSlice(std.json.Value, allocator, json_content, .{}) catch |err| {
        std.debug.print("Error parsing JSON: {}\n", .{err});
        std.process.exit(1);
    };
    defer parsed.deinit();

    const root = parsed.value;

    // Get frames object
    const frames_obj = root.object.get("frames") orelse {
        std.debug.print("Error: JSON missing 'frames' field\n", .{});
        std.process.exit(1);
    };

    // Collect frame names and sort them for deterministic output
    var frame_names: std.ArrayList([]const u8) = .empty;
    defer frame_names.deinit(allocator);

    var frames_iter = frames_obj.object.iterator();
    while (frames_iter.next()) |entry| {
        try frame_names.append(allocator, entry.key_ptr.*);
    }

    std.mem.sort([]const u8, frame_names.items, {}, struct {
        fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.lessThan);

    // Build output
    var output: std.ArrayList(u8) = .empty;
    const writer = output.writer(allocator);

    try writer.writeAll(".{\n");

    for (frame_names.items) |name| {
        const frame_data = frames_obj.object.get(name).?;
        const frame = parseFrame(frame_data);

        // Escape the name for Zig identifier (use @"" syntax for names with special chars)
        try writer.print("    .@\"{s}\" = .{{\n", .{name});
        try writer.print("        .x = {d},\n", .{frame.x});
        try writer.print("        .y = {d},\n", .{frame.y});
        try writer.print("        .w = {d},\n", .{frame.w});
        try writer.print("        .h = {d},\n", .{frame.h});
        try writer.print("        .rotated = {},\n", .{frame.rotated});
        try writer.print("        .trimmed = {},\n", .{frame.trimmed});
        try writer.print("        .source_x = {d},\n", .{frame.source_x});
        try writer.print("        .source_y = {d},\n", .{frame.source_y});
        try writer.print("        .source_w = {d},\n", .{frame.source_w});
        try writer.print("        .source_h = {d},\n", .{frame.source_h});
        try writer.print("        .orig_w = {d},\n", .{frame.orig_w});
        try writer.print("        .orig_h = {d},\n", .{frame.orig_h});
        try writer.writeAll("    },\n");
    }

    try writer.writeAll("}\n");

    return output.toOwnedSlice(allocator);
}

fn parseFrame(value: std.json.Value) Frame {
    const frame_obj = value.object.get("frame").?.object;
    const source_size_obj = value.object.get("spriteSourceSize").?.object;
    const orig_size_obj = value.object.get("sourceSize").?.object;

    return Frame{
        .x = @intCast(frame_obj.get("x").?.integer),
        .y = @intCast(frame_obj.get("y").?.integer),
        .w = @intCast(frame_obj.get("w").?.integer),
        .h = @intCast(frame_obj.get("h").?.integer),
        .rotated = value.object.get("rotated").?.bool,
        .trimmed = value.object.get("trimmed").?.bool,
        .source_x = @intCast(source_size_obj.get("x").?.integer),
        .source_y = @intCast(source_size_obj.get("y").?.integer),
        .source_w = @intCast(source_size_obj.get("w").?.integer),
        .source_h = @intCast(source_size_obj.get("h").?.integer),
        .orig_w = @intCast(orig_size_obj.get("w").?.integer),
        .orig_h = @intCast(orig_size_obj.get("h").?.integer),
    };
}
