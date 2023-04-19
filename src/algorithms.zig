const std = @import("std");
const sdl = @import("sdl.zig");
const config = @import("config.zig");
const TileType = @import("tile.zig").TileType;
const Tile = @import("tile.zig").Tile;
const Position = @import("position.zig").Position;

pub fn hManhattan(current: Position, goal: Position) f64 {
    const cx = @intCast(i32, current.x);
    const cy = @intCast(i32, current.y);
    const gx = @intCast(i32, goal.x);
    const gy = @intCast(i32, goal.y);
    return @fabs(@intToFloat(f64, cx - gx)) + @fabs(@intToFloat(f64, cy - gy));
}

pub fn hDiagonal(current: Position, goal: Position) f64 {
    const cx = @intCast(i32, current.x);
    const cy = @intCast(i32, current.y);
    const gx = @intCast(i32, goal.x);
    const gy = @intCast(i32, goal.y);

    const dx = @fabs(@intToFloat(f64, cx - gx));
    const dy = @fabs(@intToFloat(f64, cy - gy));

    return (dx + dy) + (@sqrt(2.0) - 2) * @min(dx, dy);
}

pub fn hEuclidean(current: Position, goal: Position) f64 {
    const cx = @intCast(i32, current.x);
    const cy = @intCast(i32, current.y);
    const gx = @intCast(i32, goal.x);
    const gy = @intCast(i32, goal.y);

    const dx = @fabs(@intToFloat(f64, cx - gx));
    const dy = @fabs(@intToFloat(f64, cy - gy));

    return @sqrt(dx * dx + dy * dy);
}

fn generateScore() [config.ROW_COUNT][config.COLUMN_COUNT]f64 {
    return [_][config.COLUMN_COUNT]f64{[_]f64{std.math.inf(f64)} ** config.COLUMN_COUNT} ** config.ROW_COUNT;
}

pub const State = enum {
    Waiting,
    Running,
    Done,
    Failed
};

pub const AStar = struct {
    cameFrom: std.AutoHashMap(Position, Position),
    open: std.AutoHashMap(Position, void),
    closed: std.AutoHashMap(Position, void),
    gScore: [config.ROW_COUNT][config.COLUMN_COUNT]f64,
    fScore: [config.ROW_COUNT][config.COLUMN_COUNT]f64,
    start: Position,
    goal: Position,
    h: *const fn(Position, Position) f64,
    state: State,
    allocator: std.mem.Allocator,

    pub fn init(comptime allocator: std.mem.Allocator, start: Position, goal: Position, comptime h: fn(Position, Position) f64) !AStar {
        var open = std.AutoHashMap(Position, void).init(allocator);
        try open.put(start, undefined);

        var gScore = comptime generateScore();
        gScore[start.x][start.y] = 0;

        var fScore = comptime generateScore();
        fScore[start.x][start.y] = h(start, goal);

        return .{
            .cameFrom = std.AutoHashMap(Position, Position).init(allocator),
            .open = open,
            .closed = std.AutoHashMap(Position, void).init(allocator),
            .gScore = gScore,
            .fScore = fScore,
            .start = start,
            .goal = goal,
            .h = h,
            .state = State.Waiting,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *AStar) void {
        self.*.cameFrom.deinit();
        self.*.open.deinit();
        self.*.closed.deinit();
    }

    pub fn lowestFScore(self: AStar) Position {
        var lowestScore = std.math.inf(f64);
        var position: Position = undefined;

        var iter = self.open.keyIterator();
        while (iter.next()) |tile| {
            const tileScore = self.fScore[tile.x][tile.y];
            if (tileScore < lowestScore) {
                lowestScore = tileScore;
                position = tile.*;
            }
        }

        return position;
    }

    pub fn getNeighbors(self: AStar, tile: Position) !std.ArrayList(Position).Slice {
        var neighbors = std.ArrayList(Position).init(self.allocator);
        const indexes = [_]i32{-1,0,1};
        for (indexes) |dx| {
            for (indexes) |dy| {
                const row = @intCast(i32, tile.x) + dx;
                const column = @intCast(i32, tile.y) + dy;

                if (dx == 0 and dy == 0) continue;
                if (row >= config.ROW_COUNT or column >= config.COLUMN_COUNT) continue;
                if (row < 0 or column < 0) continue;

                const x = @intCast(u32, row);
                const y = @intCast(u32, column);

                if (config.TILES[x][y].type == TileType.Wall) continue;

                try neighbors.append(.{
                    .x = x,
                    .y = y
                });
            }
        }

        return neighbors.toOwnedSlice();
    }

    pub fn step(self: *AStar) !bool {
        if(self.*.state == State.Waiting) {
            self.*.state = State.Running;
        }

        if (self.*.open.count() == 0) {
            self.*.state = State.Failed;
            return false;
        }

        var current = self.*.lowestFScore();
        if (current.x == self.*.goal.x and current.y == self.*.goal.y) {
            self.*.state = State.Done;
            return false;
        }

        _ = self.*.open.remove(current);
        try self.*.closed.put(current, undefined);

        const neighbors = try self.*.getNeighbors(current);

        for (neighbors) |neighbor| {
            const tentativeGScore = self.*.gScore[current.x][current.y]; // wikipedia state that d(current, neighbor) should be added to this but i have no clue what `d` is
            if (tentativeGScore < self.*.gScore[neighbor.x][neighbor.y]) {
                try self.*.cameFrom.put(neighbor, current);
                self.*.gScore[neighbor.x][neighbor.y] = tentativeGScore;
                self.*.fScore[neighbor.x][neighbor.y] = tentativeGScore + self.*.h(neighbor, self.*.goal);
                if (self.*.open.get(neighbor) == null) {
                    try self.*.open.put(neighbor, undefined);
                }
            }
        }

        return true;
    }

    pub fn getPath(self: AStar) !std.ArrayList(Position).Slice {
        var current = self.goal;
        var totalPath = std.ArrayList(Position).init(self.allocator);
        while (self.cameFrom.get(current) != null) {
            current = self.cameFrom.get(current) orelse continue;
            try totalPath.insert(0, current);
        }
        return totalPath.toOwnedSlice();
    }
};
