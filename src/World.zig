const std = @import("std");
const utils = @import("utils.zig");
const raylib = @import("raylib");
const Snake = @import("snake.old.zig").Snake;
const snake = @import("snake.zig");
const Fruit = @import("fruit.zig").Fruit;
const Global = @import("global.zig");
const builtin = @import("builtin");
const Font = raylib.Font;
const currentPath = std.fs.cwd();

const runMode = builtin.mode;
const Colour = raylib.Color;
const OptimizedMode = std.builtin.OptimizeMode;
const Keys = raylib.KeyboardKey;
const Rectangle = raylib.Rectangle;
const print = std.debug.print;
const BitPotionFont = @embedFile("./assets/BitPotion.ttf");
const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const pager = std.heap.page_allocator;

pub const World = struct {
    const backgroundColour = Colour{ .r = 7, .g = 15, .b = 28, .a = 255 };
    const pauseColour = Colour{ .r = 7, .g = 15, .b = 28, .a = 188 };
    const pausedFontColour = Colour{ .r = 93, .g = 178, .b = 248, .a = 255 };
    const rectOverlay = Rectangle{
        .x = 0,
        .y = 0,
        .width = Global.screenWidth,
        .height = Global.screenHeight,
    };
    const pausedTxt = "Paused";
    const fontSize = 24;
    const fontSpacing = 2.0;
    var font: Font = undefined;

    dt: f32 = 0,
    movementSpeed: f32 = 100,
    allocator: utils.Allocator = undefined,

    snake: snake.Snake = undefined,
    state: State,
    fontPos: raylib.Vector2 = raylib.Vector2{
        .x = Global.screenWidth / 2,
        .y = Global.screenHeight / 2,
    },

    pub fn deinit(self: *World) void {
        self.allocator.deinit();
    }

    pub fn init() !World {
        font = Font.fromMemory("ttf", BitPotionFont, 24, null);

        var self = World{
            .state = .play,
            .fontPos = raylib.Vector2{
                .x = Global.screenWidth / 2 - 70.0,
                .y = 100.0,
            },
            .dt = raylib.getFrameTime(),
            .allocator = try utils.Allocator.init(),
        };

        self.snake = try snake.Snake.init(&self.allocator);

        return self;
    }

    fn pauseOverlay(self: *World) void {
        raylib.drawRectangleRec(rectOverlay, pauseColour);
        raylib.drawTextEx(
            font,
            pausedTxt,
            self.fontPos,
            fontSize,
            fontSpacing,
            pausedFontColour,
        );
    }

    fn moveEntities(self: *World) void {
        if (self.state != State.play) return;
        self.snake.move(self.dt);
    }

    pub fn run(self: *World) void {
        raylib.initWindow(Global.screenWidth, Global.screenHeight, "Znake");
        defer raylib.closeWindow();

        raylib.setTargetFPS(200);

        while (!raylib.windowShouldClose()) {
            self.dt = raylib.getFrameTime();
            const command = utils.Command.keyToCommand(raylib.getKeyPressed());

            switch (command) {
                .pause_toggle => {
                    if (self.state == State.play) {
                        self.state = State.paused;
                    } else {
                        self.state = State.play;
                    }
                },
                .direction => |direction| {
                    if (self.state == State.play) {
                        self.snake.update(direction);
                    }
                },
                else => {},
            }

            if (self.state == State.play) {
                self.moveEntities();
            }

            raylib.beginDrawing();
            defer raylib.endDrawing();

            raylib.clearBackground(backgroundColour);

            self.render();

            if (self.state == .paused) {
                self.pauseOverlay();
            }

            if (runMode == OptimizedMode.Debug) {
                raylib.drawFPS(5, 5);
            }
        }
    }

    inline fn render(self: *World) void {
        self.snake.render();
    }
};

const State = enum {
    paused,
    play,
};
