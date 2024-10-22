const std = @import("std");
const raylib = @import("raylib");

const screenWidth = 1080;
const screenHeight = 720;
const Rectangle = raylib.Rectangle;
const Colour = raylib.Color;
const Keys = raylib.KeyboardKey;

const backgroundColour = Colour{ .r = 7, .g = 15, .b = 28, .a = 255 };

pub fn main() !void {
    raylib.initWindow(screenWidth, screenHeight, "Znake");
    defer raylib.closeWindow();

    var snake = Snake.init();

    raylib.setTargetFPS(144);

    while (!raylib.windowShouldClose()) {
        const pressedKey = raylib.getKeyPressed();

        Snake.handleKeyPress(&snake, pressedKey);

        Snake.move(&snake);

        raylib.beginDrawing();
        defer raylib.endDrawing();

        raylib.clearBackground(backgroundColour);

        snake.draw();
    }
}

const Direction = enum { up, down, left, right };
const SectionTarget = union(Direction) { up: f32, down: f32, left: f32, right: f32 };

const Section = struct {
    section: Rectangle,
    // NOTE: If this gets too big it will cause a segment fault
    // needs to be investigated, for now, we will keep 50
    targets: [50]SectionTarget = undefined,
    queuSize: i16 = 0,
    // pub fn shiftTargetsToLeft(self: *Section) void {

    // }
    pub fn init(rec: Rectangle) Section {
        return Section{
            .section = rec,
            // .targets = undefined,
            .queuSize = 0,
        };
    }
};

const Snake = struct {
    const headColour = Colour{ .r = 234, .g = 104, .b = 71, .a = 255 };
    const bodyColour = Colour{ .r = 255, .g = 162, .b = 0, .a = 255 };
    pub const sectionSize = 10;
    const maxSize = (screenWidth / Snake.sectionSize) * (screenHeight / Snake.sectionSize);
    const sectionGap = 0.01;
    body: [maxSize]Section = undefined,
    head: Rectangle = Rectangle{ .x = screenWidth / 2, .y = screenHeight / 2, .width = sectionSize, .height = sectionSize },
    length: u16 = 2,
    direction: Direction = Direction.left,
    speed: f16 = 0.8,
    pub fn init() Snake {
        var snake = Snake{};

        for (&snake.body, 0..) |*section, idx| {
            if (idx > snake.length) {
                break;
            }
            if (idx == 0) {
                section.* = Section.init(Rectangle{ .x = snake.head.x + @as(f32, @floatFromInt(sectionSize)) + @as(f32, @floatFromInt(snake.length)) + sectionGap, .y = snake.head.y, .width = sectionSize, .height = sectionSize });
                continue;
            }
            const prevSection = &snake.body[idx - 1].section;
            section.* = Section.init(Rectangle{ .x = prevSection.*.x + @as(f32, @floatFromInt(sectionSize)) + @as(f32, @floatFromInt(snake.length)) + sectionGap, .y = prevSection.*.y, .width = sectionSize, .height = sectionSize });
        }

        return snake;
    }

    pub fn handleKeyPress(self: *Snake, key: Keys) void {
        switch (key) {
            Keys.key_up, Keys.key_k => {
                switch (self.direction) {
                    Direction.down, Direction.up => {
                        return;
                    },
                    else => {
                        self.direction = Direction.up;
                    },
                }
            },
            Keys.key_down, Keys.key_j => {
                switch (self.direction) {
                    Direction.up, Direction.down => {
                        return;
                    },
                    else => {
                        self.direction = Direction.down;
                    },
                }
            },
            Keys.key_left, Keys.key_h => {
                switch (self.direction) {
                    Direction.right, Direction.left => {
                        return;
                    },
                    else => {
                        self.direction = Direction.left;
                    },
                }
            },
            Keys.key_right, Keys.key_l => {
                switch (self.direction) {
                    Direction.left, Direction.right => {
                        return;
                    },
                    else => {
                        self.direction = Direction.right;
                    },
                }
            },
            else => {},
        }
    }

    pub fn move(self: *Snake) void {
        switch (self.direction) {
            .up => {
                self.head.y = self.head.y - self.speed;
                if (self.head.y < 0) {
                    self.head.y = screenHeight;
                }
            },
            .down => {
                self.head.y = self.head.y + self.speed;
                if (self.head.y > screenHeight) {
                    self.head.y = 0;
                }
            },
            .left => {
                self.head.x = self.head.x - self.speed;
                if (self.head.x < 0.0) {
                    self.head.x = screenWidth;
                }
            },
            .right => {
                self.head.x = self.head.x + self.speed;
                if (self.head.x > screenWidth) {
                    self.head.x = 0;
                }
            },
        }
        for (&self.*.body, 0..) |*bodyPart, idx| {
            if (idx > self.length) {
                break;
            }
            switch (self.direction) {
                .up => {
                    bodyPart.section.y = bodyPart.section.y - self.speed;
                    if (bodyPart.section.y < 0) {
                        bodyPart.section.y = screenHeight;
                    }
                },
                .down => {
                    bodyPart.section.y = bodyPart.section.y + self.speed;
                    if (bodyPart.section.y > screenHeight) {
                        bodyPart.section.y = 0;
                    }
                },
                .left => {
                    bodyPart.section.x = bodyPart.section.x - self.speed;
                    if (bodyPart.section.x < 0.0) {
                        bodyPart.section.x = screenWidth;
                    }
                },
                .right => {
                    bodyPart.section.x = bodyPart.section.x + self.speed;
                    if (bodyPart.section.x > screenWidth) {
                        bodyPart.section.x = 0;
                    }
                },
            }
        }
    }

    pub fn draw(self: Snake) void {
        for (&self.body, 0..) |*bodyPart, idx| {
            if (idx > self.length) {
                break;
            }
            if (idx == 0) {
                raylib.drawRectangleRec(bodyPart.section, headColour);
                continue;
            }
            raylib.drawRectangleRec(bodyPart.section, bodyColour);
        }
    }
};
