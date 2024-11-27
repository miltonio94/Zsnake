const std = @import("std");
const utils = @import("utils.zig");
const raylib = @import("raylib");
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
    const orange = Colour{ .r = 234, .g = 104, .b = 71, .a = 255 };
    const yellow = Colour{ .r = 255, .g = 162, .b = 0, .a = 255 };
    const backgroundColour = Colour{ .r = 7, .g = 15, .b = 28, .a = 255 };
    const overLayColour = Colour{ .r = 7, .g = 15, .b = 28, .a = 188 };
    const lightBlue = Colour{ .r = 93, .g = 178, .b = 248, .a = 255 };
    const red = Colour{ .r = 234, .g = 61, .b = 84, .a = 255 };
    const rectOverlay = Rectangle{
        .x = 0,
        .y = 0,
        .width = Global.screenWidth,
        .height = Global.screenHeight,
    };
    const pausedTxt = "Paused";
    const menuTitleTxt = "Menu";
    const gameOverTxt = "Game Over";
    const fontSize = 24;
    const fontSpacing = 2.0;
    var font: Font = undefined;
    var gameRunning = true;
    var menuSeletion: MenuSelection = .start;

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

    fn menuRender(self: World) void {
        _ = self;
        raylib.drawRectangleRec(rectOverlay, overLayColour);
        utils.drawTextCentered(menuTitleTxt, fontSize, font, fontSpacing, orange, -(Global.screenHeight / 3));
    }

    fn gameOverOverlay(self: *World) void {
        _ = self;
        raylib.drawRectangleRec(rectOverlay, overLayColour);
        utils.drawTextCentered(gameOverTxt, fontSize, font, fontSpacing, red, -(Global.screenHeight / 3));
    }

    fn pauseOverlay(self: *World) void {
        _ = self;
        raylib.drawRectangleRec(rectOverlay, overLayColour);
        utils.drawTextCentered(pausedTxt, fontSize, font, fontSpacing, lightBlue, -(Global.screenHeight / 3));
    }

    fn moveEntities(self: *World) void {
        if (self.state != State.play) return;
        self.snake.move(self.dt);
    }

    pub fn run(self: *World) void {
        raylib.initWindow(Global.screenWidth, Global.screenHeight, "Znake");
        defer raylib.closeWindow();

        raylib.setTargetFPS(200);

        while (gameRunning) {
            // TODO: Figure out if we can make the fps print only happen if a comp time var is passed through
            if (runMode == .Debug) {
                print("FPS: {d:.10}\n", .{self.dt});
            }
            self.dt = raylib.getFrameTime();
            const command = utils.Command.keyToCommand(raylib.getKeyPressed());

            switch (command) {
                .pause_toggle => {
                    if (self.state == .play) {
                        self.state = .paused;
                    } else {
                        self.state = .play;
                    }
                },
                .menu_toggle => {
                    if (self.state == .menu) {
                        self.state = .play;
                    } else {
                        self.state = .menu;
                    }
                },
                .direction => |direction| {
                    if (self.state == .play) {
                        self.snake.update(direction);
                    }
                },
                else => {},
            }

            raylib.beginDrawing();
            defer raylib.endDrawing();

            raylib.clearBackground(backgroundColour);

            self.render();

            switch (self.state) {
                .paused => {
                    self.pauseOverlay();
                },
                .gameOver => {
                    self.gameOverOverlay();
                },
                .menu => {
                    self.menuRender();
                },
                .play => {
                    if (self.snake.selfCollision()) {
                        self.state = .gameOver;
                    }
                    self.moveEntities();
                },
            }

            if (runMode == .Debug) {
                raylib.drawFPS(5, 5);
            }
        }
    }

    inline fn render(self: *World) void {
        self.snake.render();
    }
};

const MenuSelection = enum {
    start,
    quit,
};

const State = enum {
    paused,
    menu,
    play,
    gameOver,
};
