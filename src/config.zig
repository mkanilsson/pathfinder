const std = @import("std");
const sdl = @import("sdl.zig");
const TileType = @import("tile.zig").TileType;
const Tile = @import("tile.zig").Tile;

pub const ROW_COUNT = 50;
pub const COLUMN_COUNT = 50;
pub const TILE_SIZE = 20;
pub const TILE_PADDING = 1;
pub var TILES = generateTiles();

pub const ColorConfig = struct {
    empty: sdl.Color,
    wall: sdl.Color,
    start: sdl.Color,
    finish: sdl.Color,
    path: sdl.Color,
    open: sdl.Color,
    closed: sdl.Color,
    background: sdl.Color,

    pub fn save(self: ColorConfig, allocator: std.mem.Allocator) !void {
        var string = std.ArrayList(u8).init(allocator);
        defer string.deinit();
        try std.json.stringify(self, .{}, string.writer());

        var file = try std.fs.cwd().createFile("colors.json", .{});
        defer file.close();
        try file.pwriteAll(string.items, 0);

        std.debug.print("Colors saved!\n", .{});
    }

    pub fn load(allocator: std.mem.Allocator) !ColorConfig {
        var file = try std.fs.cwd().openFile("colors.json", .{});
        defer file.close();

        var string = std.ArrayList(u8).init(allocator);
        defer string.deinit();

        const data = try file.readToEndAlloc(allocator, 1024 * 1024 * 1024); // Read 1GiB

        var stream = std.json.TokenStream.init(data);
        const parsedData = try std.json.parse(ColorConfig, &stream, .{});
        std.debug.print("Colors loaded!\n", .{});
        return parsedData;
    }
};

pub var colors: ColorConfig = undefined;

fn generateTiles() [ROW_COUNT][COLUMN_COUNT]Tile {
    var tiles: [ROW_COUNT][COLUMN_COUNT]Tile = undefined;
    @setEvalBranchQuota(@max(1000, ROW_COUNT * COLUMN_COUNT + 51)); // I have no clue why this works, but it does
    for (&tiles) |*row, row_index| {
        for (&row.*) |*tile, column_index| {
            tile.* = .{
                .@"type" = TileType.Empty,
                .position = .{
                    .x = @intCast(u32, row_index),
                    .y = @intCast(u32, column_index),
                }
            };
        }
    }

    return tiles;
}
