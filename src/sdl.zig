const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const std = @import("std");

fn logError(comptime message: [*c]const u8) void {
    const format = comptime std.fmt.comptimePrint("{s}: %s", .{message});
    c.SDL_Log(format, c.SDL_GetError());
}

pub fn delay(ms: u32) void {
    c.SDL_Delay(ms);
}

pub fn init() !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
}

pub fn deinit() void {
    c.SDL_Quit();
}

pub const Window = struct {
    window: *c.SDL_Window,

    pub fn init(title: [*c]const u8) !Window {
        const window = c.SDL_CreateWindow(title, c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, 800, 600, c.SDL_WINDOW_OPENGL) orelse {
            logError("Unable to create window");
            return error.SDLInitializationFailed;
        };

        return Window {
            .window = window
        };
    }

    pub fn deinit(self: Window) void {
        c.SDL_DestroyWindow(self.window);
    }
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

pub const Renderer = struct {
    renderer: *c.SDL_Renderer,

    pub fn init(window: Window) !Renderer {
        const renderer = c.SDL_CreateRenderer(window.window, -1, c.SDL_RENDERER_ACCELERATED) orelse {
            logError("Unable to create renderer");
            return error.SDLInitializationFailed;
        };

        return Renderer {
            .renderer = renderer
        };
    }

    pub fn deinit(self: Renderer) void {
        c.SDL_DestroyRenderer(self.renderer);
    }

    pub fn clear(self: Renderer) void {
        _ = c.SDL_RenderClear(self.renderer);
    }

    pub fn present(self: Renderer) void {
        c.SDL_RenderPresent(self.renderer);
    }

    pub fn setDrawColor(self: Renderer, color: Color) !void {
        if (c.SDL_SetRenderDrawColor(self.renderer, color.r, color.g, color.b, color.a) < 0) {
            logError("Unable to change draw color");
            return error.SDLInitializationFailed;
        }
    }

    pub fn fillRect(self: Renderer, rect: Rect, color: Color) !void {
        try self.setDrawColor(color);
        if (c.SDL_RenderFillRect(self.renderer, &rect.toSDLRect()) < 0) {
            logError("Unable to draw rect");
            return error.SDLInitializationFailed;
        }
    }
};

pub const Rect = struct {
    x: u32,
    y: u32,
    w: u32,
    h: u32,

    pub fn toSDLRect(self: Rect) c.SDL_Rect {
        return c.SDL_Rect {
            .x = @intCast(c_int, self.x),
            .y = @intCast(c_int, self.y),
            .w = @intCast(c_int, self.w),
            .h = @intCast(c_int, self.h),
        };
    }
};

pub const EventType = enum {
    Up,
    Down
};

pub const MouseButton = enum {
    Left,
    Middle,
    Right,
    X1,
    X2
};

pub const EventState = enum {
    Pressed,
    Relesed
};

pub const MouseButtonEvent = struct {
    @"type": EventType,
    button: MouseButton,
    state: EventState,
    clicks: u8,
    x: i32,
    y: i32,

    pub fn fromSDLEvent(event: *const c.SDL_Event) !MouseButtonEvent {
        const mouseEvent = @ptrCast(*const c.SDL_MouseButtonEvent, event);

        const eventType = switch (mouseEvent.*.@"type") {
            c.SDL_MOUSEBUTTONDOWN => EventType.Down,
            c.SDL_MOUSEBUTTONUP => EventType.Up,
            else => unreachable
        };

        const eventButton = switch (mouseEvent.*.button) {
            c.SDL_BUTTON_LEFT => MouseButton.Left,
            c.SDL_BUTTON_MIDDLE => MouseButton.Middle,
            c.SDL_BUTTON_RIGHT => MouseButton.Right,
            c.SDL_BUTTON_X1 => MouseButton.X1,
            c.SDL_BUTTON_X2 => MouseButton.X2,
            else => unreachable
        };

        const eventState = switch (mouseEvent.*.state) {
            c.SDL_PRESSED => EventState.Pressed,
            c.SDL_RELEASED => EventState.Relesed,
            else => unreachable
        };

        return .{
            .@"type" = eventType,
            .button = eventButton,
            .state = eventState,
            .clicks = mouseEvent.*.clicks,
            .x = mouseEvent.*.x,
            .y = mouseEvent.*.y,
        };
    }
};

pub const KeyboardKey = enum {
    Control,
    Shift,
    Escape,
    W,
    A,
    S,
    D,
    Q,
    L,
    C,
    Unknown
};

pub const KeyboardEvent = struct {
    @"type": EventType,
    key: KeyboardKey,
    state: EventState,
    repeat: bool,

    pub fn fromSDLEvent(event: *const c.SDL_Event) !KeyboardEvent {
        const keyboardEvent = @ptrCast(*const c.SDL_KeyboardEvent, event);

        const eventType = switch (keyboardEvent.*.@"type") {
            c.SDL_KEYDOWN => EventType.Down,
            c.SDL_KEYUP => EventType.Up,
            else => unreachable
        };

        const key = switch (keyboardEvent.*.keysym.scancode) {
            c.SDL_SCANCODE_LCTRL, c.SDL_SCANCODE_RCTRL => KeyboardKey.Control,
            c.SDL_SCANCODE_LSHIFT, c.SDL_SCANCODE_RSHIFT => KeyboardKey.Shift,
            c.SDL_SCANCODE_ESCAPE => KeyboardKey.Escape,
            c.SDL_SCANCODE_W => KeyboardKey.W,
            c.SDL_SCANCODE_A => KeyboardKey.A,
            c.SDL_SCANCODE_S => KeyboardKey.S,
            c.SDL_SCANCODE_D => KeyboardKey.D,
            c.SDL_SCANCODE_Q => KeyboardKey.Q,
            c.SDL_SCANCODE_L => KeyboardKey.L,
            c.SDL_SCANCODE_C => KeyboardKey.C,
            else => KeyboardKey.Unknown
        };

        const eventState = switch (keyboardEvent.*.state) {
            c.SDL_PRESSED => EventState.Pressed,
            c.SDL_RELEASED => EventState.Relesed,
            else => unreachable
        };

        return .{
            .@"type" = eventType,
            .key = key,
            .state = eventState,
            .repeat = keyboardEvent.*.repeat == 1,
        };
    }
};

pub const MouseMotionEvent = struct {
    x: i32,
    y: i32,

    pub fn fromSDLEvent(event: *const c.SDL_Event) !MouseMotionEvent {
        const mouseMotionEvent = @ptrCast(*const c.SDL_MouseMotionEvent, event);

        return .{
            .x = mouseMotionEvent.*.x,
            .y = mouseMotionEvent.*.y,
        };
    }
};
