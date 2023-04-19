const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const std = @import("std");
const sdl = @import("sdl.zig");
const config = @import("config.zig");
const TileType = @import("tile.zig").TileType;
const Tile = @import("tile.zig").Tile;
const algorithms = @import("algorithms.zig");
const Position = @import("position.zig").Position;

var CONTROL_PRESSED = false;
var LEFT_MOUSE_PRESSED = false;
var RIGHT_MOUSE_PRESSED = false;
var MOUSE_X: i32 = 0;
var MOUSE_Y: i32 = 0;
var DISABLE_EDITING = false;
var ALGORITHM_ARTIFACTS_CLEARED = true;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var astar: ?algorithms.AStar = null;

fn clear(toRemove: TileType) void {
    for (&config.TILES) |*row| {
        for (&row.*) |*tile| {
            if (tile.*.type == toRemove) {
                tile.*.type = TileType.Empty;
            }
        }
    }
}

fn clearAlgorithmArtifacts() void {
    if (ALGORITHM_ARTIFACTS_CLEARED) return;

    clear(TileType.Open);
    clear(TileType.Closed);
    clear(TileType.Path);

    ALGORITHM_ARTIFACTS_CLEARED = true;
}

fn find(tileToFind: TileType) ?Position {
    for (config.TILES) |row| {
        for (row) |tile| {
            if (tile.type == tileToFind) {
                return tile.position;
            }
        }
    }

    return null;
}

fn startAStar() !void {
    DISABLE_EDITING = true;
    clearAlgorithmArtifacts();
    ALGORITHM_ARTIFACTS_CLEARED = false;

    std.debug.print("Running A*\n", .{});

    const start = find(TileType.Start) orelse {
        DISABLE_EDITING = false;
        return std.debug.print("Couldn't find start tile\n", .{});
    };
    const goal = find(TileType.Finish) orelse {
        DISABLE_EDITING = false;
        return std.debug.print("Couldn't find goal tile\n", .{});
    };

    if (astar != null) {
        astar.?.deinit();
    }

    astar = try algorithms.AStar.init(gpa.allocator(), start, goal, algorithms.hDiagonal);
}

fn updateAStar() !bool {
    if (astar == null) return true;

    const result = try astar.?.step();

    var openIter = astar.?.open.keyIterator();
    while (openIter.next()) |tile| {
        if(config.TILES[tile.x][tile.y].type == TileType.Start or config.TILES[tile.x][tile.y].type == TileType.Finish) continue;
        config.TILES[tile.x][tile.y].type = TileType.Open;
    }

    var closedIter = astar.?.closed.keyIterator();
    while (closedIter.next()) |tile| {
        if(config.TILES[tile.x][tile.y].type == TileType.Start or config.TILES[tile.x][tile.y].type == TileType.Finish) continue;
        config.TILES[tile.x][tile.y].type = TileType.Closed;
    }

    return result;
}

fn finishAStar() !void {
    DISABLE_EDITING = false;

    if (astar == null) return;
    defer astar = null;
    defer astar.?.deinit();

    if (astar.?.state == algorithms.State.Failed) {
        return std.debug.print("No path from start to goal exist\n", .{});
    }

    if (astar.?.state == algorithms.State.Done) {
        std.debug.print("Path found!\n", .{});
    }

    const path = try astar.?.getPath();

    for (path) |node| {
        var tile = config.TILES[node.x][node.y];
        if (tile.type == TileType.Start or tile.type == TileType.Finish) continue;

        config.TILES[node.x][node.y].type = TileType.Path;
    }
}

fn save() !void {
    var string = std.ArrayList(u8).init(gpa.allocator());
    defer string.deinit();
    try std.json.stringify(config.TILES, .{}, string.writer());
    // std.debug.print("{s}", .{string.items});

    var file = try std.fs.cwd().createFile("map.json", .{});
    defer file.close();
    try file.pwriteAll(string.items, 0);

    std.debug.print("Map saved!", .{});
}

fn load() !void {
    var file = try std.fs.cwd().openFile("map.json", .{});
    defer file.close();

    var string = std.ArrayList(u8).init(gpa.allocator());
    defer string.deinit();

    const data = try file.readToEndAlloc(gpa.allocator(), 1024 * 1024 * 1024); // Read 1GiB

    var stream = std.json.TokenStream.init(data);
    const parsedData = try std.json.parse(@TypeOf(config.TILES), &stream, .{});
    config.TILES = parsedData;

    std.debug.print("Map loaded!\n", .{});
}

fn handleInput() void {
    if (DISABLE_EDITING) return;

    const row = @intCast(usize, @max(0, @divFloor(MOUSE_X, config.TILE_SIZE + config.TILE_PADDING)));
    const column = @intCast(usize, @max(0, @divFloor(MOUSE_Y, config.TILE_SIZE + config.TILE_PADDING)));

    if (row >= config.ROW_COUNT or column >= config.COLUMN_COUNT) return;

    if (CONTROL_PRESSED) {
        if (LEFT_MOUSE_PRESSED) {
            clearAlgorithmArtifacts();
            clear(TileType.Start);
            config.TILES[row][column].type = TileType.Start;
        } else if (RIGHT_MOUSE_PRESSED) {
            clearAlgorithmArtifacts();
            clear(TileType.Finish);
            config.TILES[row][column].type = TileType.Finish;
        }
    } else {
        if (LEFT_MOUSE_PRESSED) {
            clearAlgorithmArtifacts();
            config.TILES[row][column].type = TileType.Wall;
        } else if (RIGHT_MOUSE_PRESSED) {
            clearAlgorithmArtifacts();
            config.TILES[row][column].type = TileType.Empty;
        }
    }
}


pub fn main() !void {
    config.colors = try config.ColorConfig.load(gpa.allocator());

    try sdl.init();
    defer sdl.deinit();

    const window = try sdl.Window.init("Pathfinder");
    defer window.deinit();

    const renderer = try sdl.Renderer.init(window);
    defer renderer.deinit();

    var quit = false;
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.@"type") {
                c.SDL_QUIT => {
                    quit = true;
                },
                c.SDL_MOUSEMOTION => {
                    const mouseMotionEvent = try sdl.MouseMotionEvent.fromSDLEvent(&event);
                    MOUSE_X = mouseMotionEvent.x;
                    MOUSE_Y = mouseMotionEvent.y;
                },
                c.SDL_MOUSEBUTTONDOWN, c.SDL_MOUSEBUTTONUP => {
                    // onMouseDownEvent(try sdl.MouseButtonEvent.fromSDLEvent(&event)),
                    const mouseEvent = try sdl.MouseButtonEvent.fromSDLEvent(&event);

                    switch(mouseEvent.button) {
                        sdl.MouseButton.Left => LEFT_MOUSE_PRESSED = mouseEvent.state == sdl.EventState.Pressed,
                        sdl.MouseButton.Right => RIGHT_MOUSE_PRESSED = mouseEvent.state == sdl.EventState.Pressed,
                        else => {}
                    }
                },
                c.SDL_KEYDOWN, c.SDL_KEYUP => {
                    const keyboardEvent = try sdl.KeyboardEvent.fromSDLEvent(&event);

                    if (keyboardEvent.key == sdl.KeyboardKey.Q) {
                        quit = true;
                    }

                    switch(keyboardEvent.key) {
                        sdl.KeyboardKey.Control => CONTROL_PRESSED = keyboardEvent.state == sdl.EventState.Pressed,
                        else => {}
                    }

                    if(keyboardEvent.state == sdl.EventState.Pressed) {
                        if (keyboardEvent.key == sdl.KeyboardKey.A) {
                            try startAStar();
                        } else if (keyboardEvent.key == sdl.KeyboardKey.S) {
                            try save();
                        } else if (keyboardEvent.key == sdl.KeyboardKey.L) {
                            try load();
                        } else if (keyboardEvent.key == sdl.KeyboardKey.C) {
                            clear(TileType.Wall);
                            clear(TileType.Start);
                            clear(TileType.Finish);
                            clear(TileType.Path);
                            clear(TileType.Closed);
                            clear(TileType.Open);
                        }else if (keyboardEvent.key == sdl.KeyboardKey.Escape) {
                            if (astar != null) {
                                astar.?.deinit();
                                astar = null;
                            }
                        }
                    }
                },
                else => {}
            }

            handleInput();

        }

        try renderer.setDrawColor(config.colors.background);

        renderer.clear();

        if (!try updateAStar()) {
            try finishAStar();
        }

        for (config.TILES) |row, row_index| {
            for (row) |tile, column_index| {
                try tile.draw(&renderer, @intCast(u32, row_index), @intCast(u32, column_index));
            }
        }

        renderer.present();

        sdl.delay(17);
    }
}
