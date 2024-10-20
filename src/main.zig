const std = @import("std");
const raylib = @import("raylib");

const screenWidth = 1080;
const screenHeight = 720;
const Rectangle = raylib.Rectangle;
const Colour = raylib.Color;

const Direction = enum { up, down, left, right };
const Snake = struct {
    const headColour = Colour{ .r = 234, .g = 104, .b = 71, .a = 255 };
    const bodyColour = Colour{ .r = 255, .g = 162, .b = 0, .a = 255 };
    const backgroundColour = Colour{ .r = 7, .g = 15, .b = 28, .a = 255 };
    pub const sectionSize = 10;
    const maxSize = (screenWidth / Snake.sectionSize) * (screenHeight / Snake.sectionSize);
    const sectionGap = 0.01;
    body: [maxSize]Rectangle = undefined,
    length: u16 = 3,
    direction: Direction = Direction.left,
    speed: f16 = 0.8,
    pub fn init() Snake {
        var snake = Snake{};

        for (&snake.body, 0..) |*section, idx| {
            if (idx > snake.length) {
                break;
            }
            if (idx == 0) {
                section.* = Rectangle{ .x = screenWidth / 2, .y = screenHeight / 2, .width = sectionSize, .height = sectionSize };
                continue;
            }
            const prevSection = &snake.body[idx - 1];
            section.* = Rectangle{ .x = prevSection.*.x + @as(f32, @floatFromInt(sectionSize)) + @as(f32, @floatFromInt(snake.length)) + sectionGap, .y = prevSection.*.y, .width = sectionSize, .height = sectionSize };
        }

        return snake;
    }

    pub fn move(self: *Snake) void {
        for (&self.*.body, 0..) |*section, idx| {
            if (idx > self.length) {
                break;
            }
            switch (self.direction) {
                .up => {
                    section.y = section.y - self.speed;
                    if (section.y < 0) {
                        section.y = screenHeight;
                    }
                },
                .down => {
                    section.y = section.y + self.speed;
                    if (section.y > screenHeight) {
                        section.y = 0;
                    }
                },
                .left => {
                    section.x = section.x - self.speed;
                    if (section.x < 0.0) {
                        section.x = screenWidth;
                    }
                },
                .right => {
                    section.x = section.x + self.speed;
                    if (section.x > screenWidth) {
                        section.x = 0;
                    }
                },
            }
        }
    }

    pub fn draw(self: Snake) void {
        for (&self.body, 0..) |*section, idx| {
            if (idx > self.length) {
                break;
            }
            if (idx == 0) {
                raylib.drawRectangleRec(section.*, headColour);
                continue;
            }
            raylib.drawRectangleRec(section.*, bodyColour);
        }
    }
};

pub fn main() !void {
    raylib.initWindow(screenWidth, screenHeight, "Znake");
    defer raylib.closeWindow();

    var snake = Snake.init();

    raylib.setTargetFPS(144);

    while (!raylib.windowShouldClose()) {
        Snake.move(&snake);

        raylib.beginDrawing();
        defer raylib.endDrawing();

        raylib.clearBackground(backgroundColour);

        snake.draw();
    }
}
