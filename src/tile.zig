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
            TileType.Empty => color = config.colors.empty,
            TileType.Wall => color = config.colors.wall,
            TileType.Start => color = config.colors.start,
            TileType.Finish => color = config.colors.finish,
            TileType.Path => color = config.colors.path,
            TileType.Open => color = config.colors.open,
            TileType.Closed => color = config.colors.closed,
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
