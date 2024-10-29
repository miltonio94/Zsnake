const std = @import("std");
const raylib = @import("raylib");
const Snake = @import("snake.zig").Snake;
const Global = @import("global.zig");

const Colour = raylib.Color;

const backgroundColour = Colour{ .r = 7, .g = 15, .b = 28, .a = 255 };

pub fn main() !void {
    raylib.initWindow(Global.screenWidth, Global.screenHeight, "Znake");
    defer raylib.closeWindow();

    var snake = Snake.init();

    raylib.setTargetFPS(144);

    while (!raylib.windowShouldClose()) {
        raylib.drawFPS(5, 5);
        const pressedKey = raylib.getKeyPressed();

        snake.handleKeyPress(pressedKey);
        snake.handleTargetQueue();
        snake.move();

        raylib.beginDrawing();
        defer raylib.endDrawing();

        raylib.clearBackground(backgroundColour);

        snake.draw();
    }
}
