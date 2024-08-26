const std = @import("std");
const testing = std.testing;

const word_file = @embedFile("words_alpha.txt");

const WordList = struct {
    const Self = @This();
    words: []const u8,

    pub fn filtered(self: Self, allocator: std.mem.Allocator, box: Box) ![][]const u8 {
        var list = std.ArrayList([]const u8).init(allocator);
        var words = std.mem.tokenizeScalar(u8, self.words, '\n');
        var word_count: usize = 0;
        while (words.next()) |word| {
            word_count += 1;
            if (box.fits(word)) {
                try list.append(word);
            }
        }
        // std.debug.print("Word count: {d}\n", .{word_count});
        // std.debug.print("Words: {d}\n", .{list.items.len});
        return list.toOwnedSlice();
    }

    pub fn solve(self: Self, allocator: std.mem.Allocator, box: Box) !void {
        const words = try self.filtered(allocator, box);
        defer allocator.free(words);

        const sorted = try allocator.dupe([]const u8, words);
        defer allocator.free(sorted);
        std.mem.sort([]const u8, sorted, .{}, moreLetters);

        var solution = std.ArrayList([]const u8).init(allocator);
        defer solution.deinit();
        try solution.append(sorted[0]);

        var banned = std.ArrayList([]const u8).init(allocator);
        defer banned.deinit();

        var count = multiLetterCount(solution.items);
        while (count < 12) {
            const prev = prv: {
                if (solution.items.len > 0) {
                    break :prv solution.getLast();
                } else wrd: for (sorted) |word| {
                    for (banned.items) |ban| if (std.mem.eql(u8, ban, word)) continue :wrd;
                    break :prv word;
                } else unreachable;
            };

            var best_count: usize = count;
            var best_index: ?usize = null;
            var new_solution = try allocator.alloc([]const u8, solution.items.len + 1);
            defer allocator.free(new_solution);
            std.mem.copyForwards([]const u8, new_solution, solution.items);

            out: for (sorted[1..], 1..) |word, i| {
                // std.debug.print("Word: {s}\tLast:  {c}\n", .{ prev, prev[prev.len - 1] });
                // std.debug.print("New:  {s}\tFirst: {c}\n", .{ word, word[0] });
                for (banned.items) |ban| if (ban.len == word.len) {
                    var equal: bool = true;
                    for (ban, word) |a, b| {
                        if (a != b) equal = false;
                    }
                    if (equal) continue :out;
                };
                if (word[0] != prev[prev.len - 1]) continue :out;

                for (solution.items) |used| {
                    if (std.mem.eql(u8, used, word)) continue :out;
                } else {
                    new_solution[solution.items.len] = word;
                    const new_count = multiLetterCount(new_solution);
                    if (new_count > best_count) {
                        // std.debug.print("Word: {s}\nBanned:\n", .{word});
                        // for (banned.items) |bw| {
                        //     std.debug.print("{s}\n", .{bw});
                        // }
                        best_count = new_count;
                        best_index = i;
                    }
                }
            } else {
                if (best_index) |bi| {
                    try solution.append(sorted[bi]);
                } else {
                    // std.debug.print("Old length: {d}\n", .{solution.items.len});
                    const to_ban = solution.pop();
                    // std.debug.print("New length: {d}\n", .{solution.items.len});
                    // std.debug.print("New ban: {s}\n", .{to_ban});
                    try banned.append(to_ban);
                    // for (banned.items) |bw| std.debug.print("{s}\n", .{bw});
                }
            }
            count = multiLetterCount(solution.items);
        } else {
            for (solution.items) |word| {
                std.debug.print("{s}\n", .{word});
            }
        }
    }
};

fn moreLetters(_: @TypeOf(.{}), lhs: []const u8, rhs: []const u8) bool {
    return (letterCount(lhs) > letterCount(rhs));
}

fn letterCount(word: []const u8) usize {
    var words = [_][]const u8{word};
    return multiLetterCount(words[0..]);
}

fn multiLetterCount(words: [][]const u8) usize {
    var bits = std.bit_set.IntegerBitSet(26).initEmpty();
    for (words) |word| for (word) |c| bits.set(c - 97);
    return bits.count();
}

pub const word_list = WordList{ .words = word_file };

pub const Box = struct {
    const Self = @This();
    left: []u8,
    top: []u8,
    right: []u8,
    bottom: []u8,

    fn sidesArr(self: Self) [4][]u8 {
        return .{ self.left, self.top, self.right, self.bottom };
    }

    fn letters(self: Self) [12]u8 {
        var ret_val: [12]u8 = undefined;
        for (self.sidesArr(), 0..) |side, i| for (side, 0..) |c, j| {
            ret_val[i * 3 + j] = c;
        };
        return ret_val;
    }

    pub fn fits(self: Self, word: []const u8) bool {
        if (word.len < 2) return false;

        const sides = self.sidesArr();

        var pos: u2 = blk: {
            for (sides, 0..) |side, i| {
                for (side) |c| {
                    if (c == word[0]) {
                        break :blk @as(u2, @intCast(i));
                    }
                }
            } else return false;
        };

        var match_length: usize = 0;
        for (word[1..]) |letter| sds: {
            for (sides, 0..) |side, i| {
                for (side) |c| if (c == letter) {
                    if (i == pos) break;
                    match_length += 1;
                    pos = @as(u2, @intCast(i));
                    break :sds;
                };
            } else return false;
        } else return true;
    }
};
