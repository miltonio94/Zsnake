const std = @import("std");
const raylib = @import("raylib");
const Snake = @import("snake.zig").Snake;
const Fruit = @import("fruit.zig").Fruit;
const Global = @import("global.zig");
const builtin = @import("builtin");

const runMode = builtin.mode;
const Colour = raylib.Color;
const OptimizedMode = std.builtin.OptimizeMode;
const Keys = raylib.KeyboardKey;
const print = std.debug.print;

pub const World = struct {
    const backgroundColour = Colour{ .r = 7, .g = 15, .b = 28, .a = 255 };
    state: State,
    snake: Snake,
    fruit: Fruit,

    pub fn Init() World {
        var world = World{
            .state = .play,
            .snake = Snake.Init(),
            .fruit = Fruit.Init(),
        };

        while (world.snake.fruitOverlaping(&world.fruit)) {
            world.fruit.respawn();
        }

        return world;
    }

    pub fn run(self: *World) void {
        raylib.initWindow(Global.screenWidth, Global.screenHeight, "Znake");
        defer raylib.closeWindow();

        raylib.setTargetFPS(144);

        while (!raylib.windowShouldClose()) {
            if (runMode == OptimizedMode.Debug) {
                raylib.drawFPS(5, 5);
            }
            const pressedKey = raylib.getKeyPressed();

            switch (pressedKey) {
                Keys.key_p => {
                    if (self.state == State.play) {
                        print("p pressed\n", .{});
                        self.state = State.paused;
                        print("state: {any}\n", .{self.state});
                    } else {
                        print("p pressed - play\n", .{});
                        self.state = State.play;
                        print("state: {any}\n", .{self.state});
                    }
                },
                else => {},
            }

            switch (self.state) {
                State.play => {
                    self.snake.handleKeyPress(pressedKey);
                    self.snake.handleTargetQueue();
                    self.snake.move();
                },
                State.paused => {
                    //
                },
            }

            raylib.beginDrawing();
            defer raylib.endDrawing();

            raylib.clearBackground(backgroundColour);

            self.fruit.draw();
            self.snake.draw();
        }
    }
};

const State = enum {
    paused,
    play,
};
