const std = @import("std");
const raylib = @import("raylib");
const Global = @import("global.zig");

const runMode = @import("builtin").mode;
const OptimizedMode = std.builtin.OptimizeMode;
const print = std.debug.print;
const Rectangle = raylib.Rectangle;
const Colour = raylib.Color;
const Keys = raylib.KeyboardKey;
// TODO: this should not be replicated here

const Direction = enum { up, down, left, right };

const Point = struct { x: f32, y: f32 };
const Target = struct { position: Point, nextDirection: Direction };

const Section = struct {
    section: Rectangle,
    direction: Direction = Direction.left,
    // NOTE: If this gets too big it will cause a segment fault
    // needs to be investigated, for now, we will keep 50
    // TODO: Replace array with deque
    targets: [50]Target = undefined,
    queuPosition: usize = 0,
    pub fn printStatus(self: Section) void {
        print(
            "\t\tSection.x: {d}\t Section.y: {d}\t Section.queuPosition: {any}\n",
            .{ self.section.x, self.section.y, self.queuPosition },
        );
        for (&self.targets, 0..) |*value, i| {
            if (i == self.queuPosition) {
                break;
            }
            print("\t\t\tSection.targets[{d}]: {any}\n", .{ i, value });
        }
    }
    fn queuShiftLeft(self: *Section) void {
        for (&self.targets, 0..) |*target, idx| {
            if (idx == self.queuPosition) {
                return;
            }
            target.* = self.targets[idx + 1];
        }
    }
    pub fn handleQueue(self: *Section) void {
        // TODO: Fix this with new method to have a Point be a target

        const nextTarget = self.targets[0];
        const minMarginY = nextTarget.position.y - 0.75;
        const maxMarginY = nextTarget.position.y + 0.75;
        const minMarginX = nextTarget.position.x - 0.75;
        const maxMarginX = nextTarget.position.x + 0.75;
        const section = &self.section;
        if (section.y > minMarginY and
            section.y < maxMarginY and
            section.x > minMarginX and
            section.x < maxMarginX)
        {
            self.section.x = nextTarget.position.x;
            self.section.y = nextTarget.position.y;
            self.direction = self.targets[0].nextDirection;
            self.queuShiftLeft();
        }
        if (self.queuPosition != 0) {
            self.queuPosition = self.queuPosition - 1;
        }
    }
    pub fn pushNewTarget(self: *Section, direction: Direction, target: *Rectangle) void {
        if (self.queuPosition == (self.targets.len - 1)) {
            return;
        }
        self.targets[self.queuPosition] = Target{
            .nextDirection = direction,
            .position = Point{ .x = target.x, .y = target.y },
        };
        self.queuPosition += 1;
    }
    pub fn move(self: *Section, speed: f16) void {
        switch (self.direction) {
            .up => {
                if (self.section.y < 0) {
                    self.section.y = Global.screenHeight;
                    return;
                }
                self.section.y = self.section.y - speed;
            },
            .down => {
                if (self.section.y > Global.screenHeight) {
                    self.section.y = 0;
                    return;
                }
                self.section.y = self.section.y + speed;
            },
            .left => {
                if (self.section.x < 0.0) {
                    self.section.x = Global.screenWidth;
                    return;
                }
                self.section.x = self.section.x - speed;
            },
            .right => {
                if (self.section.x > Global.screenWidth) {
                    self.section.x = 0;
                    return;
                }
                self.section.x = self.section.x + speed;
            },
        }
    }
    pub fn init(rec: Rectangle) Section {
        return Section{
            .section = rec,
            .queuPosition = 0,
        };
    }
};

pub const Snake = struct {
    const headColour = Colour{
        .r = 234,
        .g = 104,
        .b = 71,
        .a = 255,
    };
    const bodyColour = Colour{
        .r = 255,
        .g = 162,
        .b = 0,
        .a = 255,
    };

    pub const sectionSize = 10;
    const maxSize = (Global.screenWidth / Snake.sectionSize) * (Global.screenHeight / Snake.sectionSize);
    const sectionGap = 1.25;
    body: [maxSize]Section = undefined,
    head: Rectangle = Rectangle{
        .x = Global.screenWidth / 2,
        .y = Global.screenHeight / 2,
        .width = sectionSize,
        .height = sectionSize,
    },
    length: u16 = 30,
    direction: Direction = Direction.left,
    speed: f16 = 0.8,

    pub fn handleTargetQueue(self: *Snake) void {
        for (&self.body, 0..) |*bodyPart, idx| {
            if (idx == self.length) {
                return;
            }
            bodyPart.*.handleQueue();
        }
    }

    pub fn printStatus(self: Snake) void {
        print("Snake.length: {d}\t Snake.head.x: {d}\t Snake.head.y: {d}\t Snake.direction: {any}\n", .{ self.length, self.head.x, self.head.y, self.direction });
        for (&self.body, 0..) |*value, i| {
            if (i == self.length) {
                break;
            }
            print("\tSnake.body[{d}]\n", .{i});
            value.printStatus();
        }
    }

    pub fn Init() Snake {
        var snake = Snake{};

        var prevSection = &snake.head;
        for (&snake.body, 0..) |*section, idx| {
            if (idx == snake.length) {
                break;
            }
            section.* = Section.init(Rectangle{
                .x = prevSection.*.x +
                    @as(f32, @floatFromInt(sectionSize)) +
                    sectionGap,
                .y = prevSection.*.y,
                .width = sectionSize,
                .height = sectionSize,
            });
            prevSection = &snake.body[idx].section;
        }

        return snake;
    }

    pub fn handleKeyPress(self: *Snake, key: Keys) void {
        // var previousSectionDirection: Direction = undefined;
        switch (key) {
            Keys.key_up, Keys.key_k => {
                switch (self.direction) {
                    Direction.down, Direction.up => {
                        return;
                    },
                    else => {
                        self.direction = Direction.up;
                        const prev_section = &self.head;
                        for (&self.body) |*section| {
                            section.pushNewTarget(Direction.up, prev_section);
                        }
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
                        const prev_section = &self.head;
                        for (&self.body) |*section| {
                            section.pushNewTarget(Direction.down, prev_section);
                        }
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
                        const prev_section = &self.head;
                        for (&self.body) |*section| {
                            section.pushNewTarget(Direction.left, prev_section);
                        }
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
                        const prev_section = &self.head;
                        for (&self.body) |*section| {
                            section.pushNewTarget(Direction.right, prev_section);
                        }
                    },
                }
            },
            else => {},
        }
        switch (key) {
            Keys.key_left,
            Keys.key_up,
            Keys.key_down,
            Keys.key_right,
            Keys.key_h,
            Keys.key_j,
            Keys.key_k,
            Keys.key_l,
            => {
                if (runMode == OptimizedMode.Debug) {
                    self.printStatus();
                }
            },
            else => {},
        }
    }

    pub fn move(self: *Snake) void {
        switch (self.direction) {
            .up => {
                if (self.head.y < 0) {
                    self.head.y = Global.screenHeight;
                    return;
                }
                self.head.y = self.head.y - self.speed;
            },
            .down => {
                if (self.head.y > Global.screenHeight) {
                    self.head.y = 0;
                    return;
                }
                self.head.y = self.head.y + self.speed;
            },
            .left => {
                if (self.head.x < 0.0) {
                    self.head.x = Global.screenWidth;
                    return;
                }
                self.head.x = self.head.x - self.speed;
            },
            .right => {
                if (self.head.x > Global.screenWidth) {
                    self.head.x = 0;
                    return;
                }
                self.head.x = self.head.x + self.speed;
            },
        }
        for (&self.*.body, 0..) |*bodyPart, idx| {
            if (self.length < idx) {
                break;
            }
            switch (self.direction) {
                .up => {
                    bodyPart.move(self.speed);
                    // if (bodyPart.section.y < 0) {
                    //     bodyPart.section.y = Global.screenHeight;
                    // }
                },
                .down => {
                    bodyPart.move(self.speed);
                    // if (bodyPart.section.y > Global.screenHeight) {
                    //     bodyPart.section.y = 0;
                    // }
                },
                .left => {
                    bodyPart.move(self.speed);
                    // if (bodyPart.section.x < 0.0) {
                    //     bodyPart.section.x = Global.screenWidth;
                    // }
                },
                .right => {
                    bodyPart.move(self.speed);
                    // if (bodyPart.section.x > Global.screenWidth) {
                    //     bodyPart.section.x = 0;
                    // }
                },
            }
        }
    }

    pub fn draw(self: Snake) void {
        raylib.drawRectangleRec(self.head, headColour);
        for (&self.body, 0..) |*bodyPart, idx| {
            if (idx > self.length) {
                break;
            }
            raylib.drawRectangleRec(bodyPart.section, bodyColour);
        }
    }
};
