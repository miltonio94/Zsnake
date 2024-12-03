const std = @import("std");
const utils = @import("utils.zig");
const raylib = @import("raylib");
const snake = @import("snake.zig");
const Fruit = @import("fruit.zig").Fruit;
const global = @import("global.zig");
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

pub const World = struct {
    const MenuSelection = enum {
        start,
        restart,
        quit,

        inline fn nextValue(self: MenuSelection) MenuSelection {
            return switch (self) {
                .start => .restart,
                .restart => .quit,
                .quit => .start,
            };
        }

        inline fn prevValue(self: MenuSelection) MenuSelection {
            return switch (self) {
                .start => .quit,
                .restart => .start,
                .quit => .restart,
            };
        }

        pub inline fn update(self: *MenuSelection, direction: utils.Direction) void {
            switch (direction) {
                .up => {
                    self.* = self.prevValue();
                },
                .down => {
                    self.* = self.nextValue();
                },
                else => {},
            }
        }

        pub inline fn draw(self: MenuSelection) void {
            const startingPoint = -(global.screenHeight / 4);
            utils.drawTextCentered(
                "Start",
                fontSize,
                font,
                fontSpacing,
                if (self == .start) global.red else global.yellow,
                startingPoint,
            );
            utils.drawTextCentered(
                "Restart",
                fontSize,
                font,
                fontSpacing,
                if (self == .restart) global.red else global.yellow,
                startingPoint + 45,
            );
            utils.drawTextCentered(
                "Quit",
                fontSize,
                font,
                fontSpacing,
                if (self == .quit) global.red else global.yellow,
                startingPoint + 90,
            );
        }
    };

    const State = enum {
        paused,
        menu,
        play,
        gameOver,
        restart,
    };
    const rectOverlay = Rectangle{
        .x = 0,
        .y = 0,
        .width = global.screenWidth,
        .height = global.screenHeight,
    };
    const pausedTxt = "Paused";
    const menuTitleTxt = "Menu";
    const gameOverTxt = "Game Over";
    const fontSize = 24;
    const fontSpacing = 2.0;
    var font: Font = undefined;
    var gameRunning = true;
    var menuSeletion: MenuSelection = .start;
    var scoreStr: [12]u8 = undefined;
    var score: i32 = 0;

    dt: f32 = 0,
    allocator: utils.Allocator = undefined,

    snake: snake.Snake = undefined,
    fruit: Fruit,
    state: State,
    fontPos: raylib.Vector2 = raylib.Vector2{
        .x = global.screenWidth / 2,
        .y = global.screenHeight / 2,
    },

    pub fn deinit(self: *World) void {
        self.allocator.deinit();
    }

    pub fn init() !World {
        font = Font.fromMemory("ttf", BitPotionFont, 24, null);
        _ = try std.fmt.bufPrint(&scoreStr, "{}", .{score});

        var self = World{
            .state = .menu,
            .fontPos = raylib.Vector2{
                .x = global.screenWidth / 2 - 70.0,
                .y = 100.0,
            },
            .fruit = Fruit.Init(),
            .dt = raylib.getFrameTime(),
            .allocator = try utils.Allocator.init(),
        };

        while (self.snake.fruitOverlap(self.fruit)) {
            self.fruit.respawn();
        }

        self.snake = try snake.Snake.init(&self.allocator);

        return self;
    }

    fn menuRender(self: World) void {
        _ = self;
        raylib.drawRectangleRec(rectOverlay, global.darkBlueWithTransparency);
        utils.drawTextCentered(menuTitleTxt, fontSize, font, fontSpacing, global.orange, -(global.screenHeight / 3));
        menuSeletion.draw();
    }

    fn gameOverOverlay(self: *World) void {
        _ = self;
        raylib.drawRectangleRec(rectOverlay, global.darkBlueWithTransparency);
        utils.drawTextCentered(gameOverTxt, fontSize, font, fontSpacing, global.red, -(global.screenHeight / 3));
    }

    fn pauseOverlay(self: *World) void {
        _ = self;
        raylib.drawRectangleRec(rectOverlay, global.darkBlueWithTransparency);
        utils.drawTextCentered(pausedTxt, fontSize, font, fontSpacing, global.lightBlue, -(global.screenHeight / 3));
    }

    fn moveEntities(self: *World) void {
        if (self.state != State.play) return;
        self.snake.move(self.dt);
    }

    pub fn run(self: *World) void {
        raylib.initWindow(global.screenWidth, global.screenHeight, "Znake");
        defer raylib.closeWindow();

        raylib.setTargetFPS(200);

        while (gameRunning) {
            self.dt = raylib.getFrameTime();
            var direction: ?utils.Direction = null;

            // Input handling
            switch (utils.Command.keyToCommand(raylib.getKeyPressed())) {
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
                .select => {
                    switch (menuSeletion) {
                        .quit => {
                            gameRunning = false;
                        },

                        .restart => {
                            self.state = .restart;
                        },
                        .start => {
                            self.state = .play;
                        },
                    }
                },
                .direction => |direction_| {
                    direction = direction_;
                },
                else => {},
            }

            // Update
            switch (self.state) {
                .play => {
                    if (direction) |direction_| {
                        self.snake.directionChange(direction_);
                    }

                    if (self.snake.selfCollision()) {
                        self.state = .gameOver;
                    }

                    if (self.snake.hasEatenFruit(self.fruit)) {
                        score += 10;
                        self.snake.movementSpeed += 10;
                        self.fruit.respawn();
                        while (self.snake.fruitOverlap(self.fruit)) {
                            self.fruit.respawn();
                        }
                        scoreStr = .{0} ** 12;
                        _ = std.fmt.bufPrint(&scoreStr, "{}", .{score}) catch |err| {
                            print("Err: {any}", .{err});
                        };

                        self.snake.grow();
                    }

                    self.moveEntities();
                },
                .menu => {
                    if (direction) |direction_| {
                        menuSeletion.update(direction_);
                    }
                },
                .gameOver => {},
                .restart => {
                    score = 0;
                    scoreStr = .{0} ** 12;
                    _ = std.fmt.bufPrint(&scoreStr, "{}", .{score}) catch |err| {
                        print("Err: {any}", .{err});
                    };

                    self.snake.reinit();
                    self.fruit.respawn();
                    while (self.snake.fruitOverlap(self.fruit)) {
                        self.fruit.respawn();
                    }
                    self.state = .play;
                },
                .paused => {},
            }

            // Draw
            raylib.beginDrawing();
            defer raylib.endDrawing();

            raylib.clearBackground(global.darkBlue);

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
                    self.render();
                    renderScore();
                },
                else => {},
            }

            if (runMode == .Debug) {
                raylib.drawFPS(5, 5);
            }
        }
        if (runMode == .Debug) {
            print("FPS: {d:.10}\n", .{self.dt});
        }
    }

    inline fn renderScore() void {
        raylib.drawTextEx(font, "Score " ++ scoreStr, .{ .x = global.screenWidth - 200, .y = 32 }, fontSize, fontSpacing, global.beige);
    }

    inline fn render(self: World) void {
        self.fruit.render();
        self.snake.render();
    }
};
