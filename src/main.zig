const std = @import("std");
const root = @import("root.zig");

pub fn main() !void {
    var gen_p_alloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gen_p_alloc.detectLeaks();
    const gpa = gen_p_alloc.allocator();

    std.debug.print("Letters: ", .{});
    const stdin = std.io.getStdIn().reader();
    var buf: [13]u8 = undefined;
    _ = try stdin.readAll(&buf);

    const box = root.Box{
        .left = buf[0..3],
        .top = buf[3..6],
        .right = buf[6..9],
        .bottom = buf[9..12],
    };

    try root.word_list.solve(gpa, box);
}
