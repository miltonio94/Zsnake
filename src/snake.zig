const std = @import("std");
const raylib = @import("raylib");

const print = std.debug.print;
const Rectangle = raylib.Rectangle;
const Colour = raylib.Color;
const Keys = raylib.KeyboardKey;
// TODO: this should not be replicated here
const screenWidth = 1080;
const screenHeight = 720;

const Direction = enum { up, down, left, right };
const SectionTarget = union(Direction) {
    up: f32,
    down: f32,
    left: f32,
    right: f32,
};

const Section = struct {
    section: Rectangle,
    // NOTE: If this gets too big it will cause a segment fault
    // needs to be investigated, for now, we will keep 50
    // TODO: Replace array with deque
    targets: [50]SectionTarget = undefined,
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
    fn queuShiftLeft(self: Section) void {
        for (&self.targets, 0..) |*target, idx| {
            if (idx == self.queuPosition) {
                return;
            }
            var t = target.*;
            t = self.targets[idx + 1];
        }
    }
    pub fn handleQueue(self: *Section) void {
        switch (self.targets[0]) {
            .up => |targetY| {
                if (self.section.y < targetY) {
                    return;
                }
                self.queuShiftLeft();
            },
            .down => |targetY| {
                if (self.section.y > targetY) {
                    return;
                }
                self.queuShiftLeft();
            },
            .left => |targetX| {
                if (self.section.x < targetX) {
                    return;
                }
                self.queuShiftLeft();
            },
            .right => |targetX| {
                if (self.section.x > targetX) {
                    return;
                }
                self.queuShiftLeft();
            },
        }
        if (self.queuPosition != 0) {
            self.queuPosition = self.queuPosition - 1;
        }
    }
    pub fn pushNewTarget(
        self: *Section,
        nextDirection: Direction,
        target: Rectangle,
    ) void {
        if (self.queuPosition == (self.targets.len - 1)) {
            return;
        }
        switch (nextDirection) {
            .up => {
                self.targets[self.queuPosition] = SectionTarget{ .up = target.y };
            },
            .down => {
                self.targets[self.queuPosition] = SectionTarget{ .down = target.y };
            },
            .left => {
                self.targets[self.queuPosition] = SectionTarget{ .left = target.x };
            },
            .right => {
                self.targets[self.queuPosition] = SectionTarget{ .right = target.x };
            },
        }
        self.queuPosition += 1;
    }
    pub fn move(self: *Section, direction: Direction, speed: f16) void {
        // print(
        //     "\n\nIn Section.move direction param: {any}\n queuPosition: {d}\n",
        //     .{ direction, self.queuPosition },
        // );
        if (self.queuPosition == 0) {
            // print("queu position is 0\n\n", .{});
            switch (direction) {
                .up => {
                    self.*.section.y = self.section.y - speed;
                    if (self.section.y < 0) {
                        self.section.y = screenHeight;
                    }
                },
                .down => {
                    self.*.section.y = self.section.y + speed;
                    if (self.section.y > screenHeight) {
                        self.section.y = 0;
                    }
                },
                .left => {
                    self.*.section.x = self.section.x - speed;
                    if (self.section.x < 0.0) {
                        self.section.x = screenWidth;
                    }
                },
                .right => {
                    self.*.section.x = self.section.x + speed;
                    if (self.section.x > screenWidth) {
                        self.section.x = 0;
                    }
                },
            }
            return;
        }
        switch (self.targets[0]) {
            .up => |targetY| {
                // print("in section swith statement up\n", .{});
                if (targetY > self.section.y) {
                    // TODO shitf everything by one to the left
                } else {
                    // print("in section swith statement up else part", .{});
                    self.section.y = self.section.y - speed;
                }
            },
            .down => |targetY| {
                // print("in section swith statement down\n", .{});
                if (targetY < self.section.y) {
                    // TODO shitf everything by one to the left
                } else {
                    // print("in section swith statement down else part", .{});
                    self.section.y = self.section.y + speed;
                }
            },
            .left => |targetX| {
                // print("in section swith statement left\n", .{});
                if (targetX > self.section.x) {
                    // TODO shitf everything by one to the left
                } else {
                    // print("in section swith statement left else part", .{});
                    self.section.x = self.section.x - speed;
                }
            },
            .right => |targetX| {
                // print("in section swith statement right\n", .{});
                if (targetX < self.section.x) {
                    // TODO shitf everything by one to the left
                } else {
                    // print("in section swith statement right else part", .{});
                    self.section.x = self.section.x + speed;
                }
            },
        }
    }
    // pub fn shiftTargetsToLeft(self: *Section) void {

    // }
    pub fn init(rec: Rectangle) Section {
        return Section{
            .section = rec,
            // .targets = undefined,
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
    const maxSize = (screenWidth / Snake.sectionSize) * (screenHeight / Snake.sectionSize);
    const sectionGap = 0.01;
    body: [maxSize]Section = undefined,
    head: Rectangle = Rectangle{
        .x = screenWidth / 2,
        .y = screenHeight / 2,
        .width = sectionSize,
        .height = sectionSize,
    },
    length: u16 = 8,
    direction: Direction = Direction.left,
    speed: f16 = 0.8,

    pub fn handleTargetQueue(self: *Snake) void {
        for (&self.body, 0..) |*bodyPart, idx| {
            if (idx == self.length - 1) {
                return;
            }
            bodyPart.*.handleQueue();
        }
    }

    pub fn printStatus(self: Snake) void {
        print("Snake.length: {d}\t Snake.head.x: {d}\t Snake.head.y: {d}\t Snake.direction: {any}\n", .{ self.length, self.head.x, self.head.y, self.direction });
        for (&self.body, 0..) |*value, i| {
            if (i > self.length) {
                break;
            }
            print("\tSnake.body[{d}]\n", .{i});
            value.printStatus();
        }
    }

    pub fn init() Snake {
        var snake = Snake{};

        for (&snake.body, 0..) |*section, idx| {
            if (idx > snake.length) {
                break;
            }
            if (idx == 0) {
                section.* = Section.init(Rectangle{
                    .x = snake.head.x + @as(f32, @floatFromInt(sectionSize)) + @as(f32, @floatFromInt(snake.length)) + sectionGap,
                    .y = snake.head.y,
                    .width = sectionSize,
                    .height = sectionSize,
                });
                continue;
            }
            const prevSection = &snake.body[idx - 1].section;
            section.* = Section.init(Rectangle{
                .x = prevSection.*.x + @as(f32, @floatFromInt(sectionSize)) + @as(f32, @floatFromInt(snake.length)) + sectionGap,
                .y = prevSection.*.y,
                .width = sectionSize,
                .height = sectionSize,
            });
        }

        return snake;
    }

    pub fn handleKeyPress(self: *Snake, key: Keys) void {
        const headDirection = self.direction;
        // var previousSectionDirection: Direction = undefined;
        switch (key) {
            Keys.key_up, Keys.key_k => {
                switch (self.direction) {
                    Direction.down, Direction.up => {
                        return;
                    },
                    else => {
                        self.direction = Direction.up;
                        var prev_section = self.head;
                        for (&self.body, 0..) |*section, idx| {
                            if (idx == 0) {
                                Section.pushNewTarget(section, headDirection, prev_section);
                                prev_section = section.section;
                                continue;
                            }
                            Section.pushNewTarget(section, headDirection, prev_section);
                            prev_section = section.section;
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
                        var prev_section = self.head;
                        for (&self.body, 0..) |*section, idx| {
                            if (idx == 0) {
                                Section.pushNewTarget(section, headDirection, prev_section);
                                prev_section = section.section;
                                continue;
                            }
                            Section.pushNewTarget(section, headDirection, prev_section);
                            prev_section = section.section;
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
                        var prev_section = self.head;
                        for (&self.body, 0..) |*section, idx| {
                            if (idx == 0) {
                                Section.pushNewTarget(section, headDirection, prev_section);
                                prev_section = section.section;
                                continue;
                            }
                            Section.pushNewTarget(section, headDirection, prev_section);
                            prev_section = section.section;
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
                        var prev_section = self.head;
                        for (&self.body, 0..) |*section, idx| {
                            if (idx == 0) {
                                Section.pushNewTarget(section, headDirection, prev_section);
                                prev_section = section.section;
                                continue;
                            }
                            Section.pushNewTarget(section, headDirection, prev_section);
                            prev_section = section.section;
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
                self.printStatus();
            },
            else => {},
        }
    }

    pub fn move(self: *Snake) void {
        switch (self.direction) {
            .up => {
                if (self.head.y < 0) {
                    self.head.y = screenHeight;
                    return;
                }
                self.head.y = self.head.y - self.speed;
            },
            .down => {
                if (self.head.y > screenHeight) {
                    self.head.y = 0;
                    return;
                }
                self.head.y = self.head.y + self.speed;
            },
            .left => {
                if (self.head.x < 0.0) {
                    self.head.x = screenWidth;
                    return;
                }
                self.head.x = self.head.x - self.speed;
            },
            .right => {
                if (self.head.x > screenWidth) {
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
                    bodyPart.move(Direction.up, self.speed);
                    // if (bodyPart.section.y < 0) {
                    //     bodyPart.section.y = screenHeight;
                    // }
                },
                .down => {
                    bodyPart.move(Direction.down, self.speed);
                    // if (bodyPart.section.y > screenHeight) {
                    //     bodyPart.section.y = 0;
                    // }
                },
                .left => {
                    bodyPart.move(Direction.left, self.speed);
                    // if (bodyPart.section.x < 0.0) {
                    //     bodyPart.section.x = screenWidth;
                    // }
                },
                .right => {
                    bodyPart.move(Direction.right, self.speed);
                    // if (bodyPart.section.x > screenWidth) {
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
