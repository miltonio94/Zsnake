const std = @import("std");
const raylib = @import("raylib");
const Snake = @import("snake.zig").Snake;
const Fruit = @import("fruit.zig").Fruit;
const Global = @import("global.zig");
const Colour = raylib.Color;

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
            raylib.drawFPS(5, 5);
            const pressedKey = raylib.getKeyPressed();

            self.snake.handleKeyPress(pressedKey);
            self.snake.handleTargetQueue();
            self.snake.move();

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
