const std = @import("std");
const sdl = @import("sdl.zig");
const config = @import("config.zig");
const Position = @import("position.zig").Position;

pub const TileType = enum {
    Empty,
    Wall,
    Start,
    Finish,
    Path,
    Open,
    Closed,

    pub fn jsonStringify(self: TileType, _: std.json.StringifyOptions, out_stream: anytype) !void {
        const value = switch (self) {
            TileType.Empty => "\"Empty\"",
            TileType.Wall => "\"Wall\"",
            TileType.Start => "\"Start\"",
            TileType.Finish => "\"Finish\"",
            TileType.Path => "\"Path\"",
            TileType.Open => "\"Open\"",
            TileType.Closed => "\"Closed\"",
        };

        return out_stream.writeAll(value);
    }
};

pub const Tile = struct {
    @"type": TileType,
    position: Position,

    pub fn draw(self: Tile, renderer: *const sdl.Renderer, x: u32, y: u32) !void {
        var color: sdl.Color = undefined;
        switch (self.@"type") {
            TileType.Empty => color = config.EmptyTileColor,
            TileType.Wall => color = config.WallTileColor,
            TileType.Start => color = config.StartTileColor,
            TileType.Finish => color = config.FinishTileColor,
            TileType.Path => color = config.PathTileColor,
            TileType.Open => color = config.OpenTileColor,
            TileType.Closed => color = config.ClosedTileColor,
        }

        const rect = sdl.Rect {
            .x = (config.TILE_SIZE + config.TILE_PADDING) * x + config.TILE_PADDING,
            .y = (config.TILE_SIZE + config.TILE_PADDING) * y + config.TILE_PADDING,
            .w = config.TILE_SIZE,
            .h = config.TILE_SIZE,
        };

        try renderer.fillRect(rect, color);
    }
};
