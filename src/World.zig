const std = @import("std");
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
    const sectionMaxSize = 10000;

    dt: f32 = 0,
    fba: FixedBufferAllocator = undefined,
    allocator: std.mem.Allocator = undefined,
    memBuffer: []u8,
    rectBuffer: []Rectangle = undefined,
    sectionBuffer: []snake.Section = undefined,
    targetBuffer: []snake.Target = undefined,
    directionBuffer: []snake.Target = undefined,
    head: snake.Head = undefined,

    state: State,
    fontPos: raylib.Vector2 = raylib.Vector2{
        .x = Global.screenWidth / 2,
        .y = Global.screenHeight / 2,
    },

    pub fn deinit(self: *World) void {
        pager.free(self.memBuffer);
    }

    pub fn init() !World {
        font = Font.fromMemory("ttf", BitPotionFont, 24, null);

        var world = World{
            .state = .play,
            .fontPos = raylib.Vector2{
                .x = Global.screenWidth / 2 - 70.0,
                .y = 100.0,
            },
            .dt = raylib.getFrameTime(),
            .memBuffer = try pager.alloc(u8, 100 * 1024 * 1024),
        };

        world.fba = FixedBufferAllocator.init(world.memBuffer);
        world.allocator = world.fba.allocator();
        world.rectBuffer = try world.allocator.alloc(Rectangle, sectionMaxSize);
        world.sectionBuffer = try world.allocator.alloc(snake.Section, sectionMaxSize);
        world.targetBuffer = try world.allocator.alloc(snake.Target, sectionMaxSize * 50);

        var i: usize = 0;
        while (i < sectionMaxSize) : (i += 1) {
            world.rectBuffer[i] = Rectangle{
                .x = 0,
                .y = 0,
                .width = snake.startingSize,
                .height = snake.startingSize,
            };
        }

        // while (world.snake.fruitOverlaping(&world.fruit)) {
        //     world.fruit.respawn();
        // }

        return world;
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

    pub fn run(self: *World) void {
        raylib.initWindow(Global.screenWidth, Global.screenHeight, "Znake");
        defer raylib.closeWindow();

        raylib.setTargetFPS(144);

        while (!raylib.windowShouldClose()) {
            self.dt = raylib.getFrameTime();
            // if (runMode == OptimizedMode.Debug) {
            raylib.drawFPS(5, 5);
            // }
            const pressedKey = raylib.getKeyPressed();

            switch (pressedKey) {
                Keys.key_p => {
                    if (self.state == State.play) {
                        self.state = State.paused;
                    } else {
                        self.state = State.play;
                    }
                },
                else => {},
            }

            if (self.state == State.play) {
                // self.snake.handleKeyPress(pressedKey);
                // self.snake.handleTargetQueue();
                // self.snake.move(self.dt);
            }
            // switch (self.state) {
            //     State.play => {
            //         self.snake.handleKeyPress(pressedKey);
            //         self.snake.handleTargetQueue();
            //         self.snake.move();
            //     },
            //     State.paused => {
            //         //
            //     },
            // }

            raylib.beginDrawing();
            defer raylib.endDrawing();

            raylib.clearBackground(backgroundColour);

            // self.fruit.draw();
            // self.snake.draw();

            if (self.state == .paused) {
                self.pauseOverlay();
            }
        }
    }
};

const State = enum {
    paused,
    play,
};
