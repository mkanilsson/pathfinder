const sdl = @import("sdl.zig");
const TileType = @import("tile.zig").TileType;
const Tile = @import("tile.zig").Tile;

pub const ROW_COUNT = 50;
pub const COLUMN_COUNT = 50;
pub const TILE_SIZE = 20;
pub const TILE_PADDING = 1;
pub var TILES = generateTiles();

pub const EmptyTileColor = sdl.Color {
    .r = 0xEB,
    .g = 0xDB,
    .b = 0xB2,
    .a = 0xFF,
};

pub const WallTileColor = sdl.Color {
    .r = 0,
    .g = 0,
    .b = 0,
    .a = 255,
};

pub const StartTileColor = sdl.Color {
    .r = 0x56,
    .g = 0x85,
    .b = 0x88,
    .a = 0xFF,
};

pub const FinishTileColor = sdl.Color {
    .r = 0xCC,
    .g = 0x24,
    .b = 0x1D,
    .a = 0xFF,
};

pub const PathTileColor = sdl.Color {
    .r = 0x98,
    .g = 0x97,
    .b = 0x1A,
    .a = 0xFF,
};

pub const OpenTileColor = sdl.Color {
    .r = 0xB1,
    .g = 0x62,
    .b = 0x86,
    .a = 0xFF,
};

pub const ClosedTileColor = sdl.Color {
    .r = 0xD7,
    .g = 0x99,
    .b = 0x21,
    .a = 0xFF,
};

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
