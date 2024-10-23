const std = @import("std");
const raylib = @import("raylib");
const Snake = @import("snake.zig").Snake;

const screenWidth = 1080;
const screenHeight = 720;
const Colour = raylib.Color;

const backgroundColour = Colour{ .r = 7, .g = 15, .b = 28, .a = 255 };

pub fn main() !void {
    raylib.initWindow(screenWidth, screenHeight, "Znake");
    defer raylib.closeWindow();

    var snake = Snake.init();

    raylib.setTargetFPS(144);

    while (!raylib.windowShouldClose()) {
        raylib.drawFPS(5, 5);
        const pressedKey = raylib.getKeyPressed();
        snake.handleTargetQueue();

        snake.handleKeyPress(pressedKey);

        snake.move();

        raylib.beginDrawing();
        defer raylib.endDrawing();

        raylib.clearBackground(backgroundColour);

        snake.draw();
    }
}
