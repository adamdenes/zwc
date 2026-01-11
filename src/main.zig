const std = @import("std");

const CountType = enum {
    lines,
    words,
    bytes,
    chars,
    all, // for -l -w -c combined
};

const InputSource = enum {
    file,
    stdin,
};

const ParsedArgs = struct {
    count_type: CountType,
    input_source: InputSource,
    file_path: ?[]const u8,
};

fn parseArgs(args: [][:0]u8) !ParsedArgs {
    if (args.len == 2) {
        if (std.mem.startsWith(u8, args[1], "-")) {
            const count_type = switch (args[1][1]) {
                'l' => CountType.lines,
                'w' => CountType.words,
                'c' => CountType.bytes,
                'm' => CountType.chars,
                else => return error.InvalidFlag,
            };
            return ParsedArgs{ .count_type = count_type, .input_source = InputSource.stdin, .file_path = null };
        } else {
            return ParsedArgs{ .count_type = CountType.all, .input_source = InputSource.file, .file_path = args[1] };
        }
    }

    if (args.len == 3) {
        const count_type = switch (args[1][1]) {
            'l' => CountType.lines,
            'w' => CountType.words,
            'c' => CountType.bytes,
            'm' => CountType.chars,
            else => return error.InvalidFlag,
        };
        return ParsedArgs{ .count_type = count_type, .input_source = InputSource.file, .file_path = args[2] };
    }

    return error.ExpectedArgument;
}

pub fn readStdin(allocator: std.mem.Allocator) ![]u8 {
    var stdin_buffer: [4096]u8 = undefined;
    var stdin_reader_wrapper = std.fs.File.stdin().reader(&stdin_buffer);
    const reader: *std.Io.Reader = &stdin_reader_wrapper.interface;

    var result = std.ArrayList(u8).empty;
    defer result.deinit(allocator);

    while (reader.takeDelimiterExclusive('\n')) |line| {
        reader.toss(1);
        try result.appendSlice(allocator, line);
        try result.append(allocator, '\n');
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    return result.toOwnedSlice(allocator);
}

pub fn readFile(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const size = (try file.stat()).size;
    const buffer = try allocator.alloc(u8, size);
    errdefer allocator.free(buffer);

    const bytes_read = try file.readAll(buffer);
    return buffer[0..bytes_read];
}

fn byteCount(file_path: []const u8) !u64 {
    const file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
    defer file.close();

    return (try file.stat()).size;
}

fn lineCount(file_path: ?[]const u8, data: ?[]const u8) !u64 {
    if (data) |d| {
        var count: u64 = 0;
        for (d) |byte| {
            if (byte == '\n') count += 1;
        }
        return count;
    }

    const file = try std.fs.cwd().openFile(file_path.?, .{ .mode = .read_only });
    defer file.close();

    var buffer: [4096]u8 = undefined;
    var file_reader = file.readerStreaming(&buffer);
    var reader = &file_reader.interface;

    var counter: u64 = 0;
    while (reader.takeDelimiterExclusive('\n')) |_| {
        reader.toss(1);
        counter += 1;
    } else |err| switch (err) {
        error.EndOfStream => return counter,
        else => return err,
    }
}

fn wordCount(allocator: std.mem.Allocator, file_path: ?[]const u8, data: ?[]const u8) !u64 {
    const buff = if (file_path) |fp| blk: {
        const allocated = try readFile(allocator, fp);
        errdefer allocator.free(allocated);
        break :blk allocated;
    } else data.?;

    defer if (file_path != null) allocator.free(buff);

    var lines = std.mem.tokenizeScalar(u8, buff, '\n');
    var counter: u64 = 0;
    while (lines.next()) |line| {
        var words = std.mem.tokenizeScalar(u8, line, ' ');
        while (words.next()) |_| {
            counter += 1;
        }
    }
    return counter;
}

fn charCount(allocator: std.mem.Allocator, file_path: []const u8) !u64 {
    const buff = try readFile(allocator, file_path);
    errdefer allocator.free(buff);

    return std.unicode.utf8CountCodepoints(buff);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var stdout_buf: [1024]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&stdout_buf);
    const writer = &stdout.interface;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const parsed = try parseArgs(args);

    switch (parsed.input_source) {
        .stdin => {
            const stdin_data = try readStdin(allocator);
            defer allocator.free(stdin_data);

            const result = switch (parsed.count_type) {
                .lines => try lineCount(null, stdin_data),
                .words => try wordCount(allocator, null, stdin_data),
                .bytes => stdin_data.len,
                .chars => try std.unicode.utf8CountCodepoints(stdin_data),
                .all => unreachable, // stdin doesn't support .all mode
            };
            try writer.print("     {d}\n", .{result});
        },
        .file => {
            const file_path = parsed.file_path.?;

            switch (parsed.count_type) {
                .lines => {
                    const result = try lineCount(file_path, null);
                    try writer.print("     {d} {s}\n", .{ result, file_path });
                },
                .words => {
                    const result = try wordCount(allocator, file_path, null);
                    try writer.print("     {d} {s}\n", .{ result, file_path });
                },
                .bytes => {
                    const result = try byteCount(file_path);
                    try writer.print("     {d} {s}\n", .{ result, file_path });
                },
                .chars => {
                    const result = try charCount(allocator, file_path);
                    try writer.print("     {d} {s}\n", .{ result, file_path });
                },
                .all => {
                    const lines = try lineCount(file_path, null);
                    const words = try wordCount(allocator, file_path, null);
                    const bytes = try byteCount(file_path);
                    try writer.print("     {d} {d} {d} {s}\n", .{ lines, words, bytes, file_path });
                },
            }
        },
    }

    try writer.flush();
}
