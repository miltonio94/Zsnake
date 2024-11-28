const std = @import("std");
const raylib = @import("raylib");
const Global = @import("global.zig");
const runMode = @import("builtin").mode;
const Fruit = @import("fruit.zig").Fruit;
const utils = @import("utils.zig");

const OptimizedMode = std.builtin.OptimizeMode;
const Rectangle = raylib.Rectangle;
const Colour = raylib.Color;
const Keys = raylib.KeyboardKey;
const print = std.debug.print;

pub const Snake = struct {
    const sectionMaxSize = 50000;
    const headColour = Colour{ .r = 234, .g = 104, .b = 71, .a = 255 };
    const bodyColour = Colour{ .r = 255, .g = 162, .b = 0, .a = 255 };
    const initSize: usize = 3;
    pub const startingSize: f32 = 40.0;

    movementSpeed: f32 = 100,

    recBuffer: []Rectangle = undefined,
    sectionBuffer: []Section = undefined,
    targetBuffer: []Target = undefined,
    directionBuffer: []utils.Direction = undefined,
    head: Head = undefined,

    sectionBufferLength: usize = 0,
    recBufferLength: usize = 0,
    directionBufferLength: usize = 0,

    pub inline fn reinit(self: *Snake) void {
        self.head = Head{
            .recIdx = 0,
            .directionIdx = 0,
        };
        self.recBuffer[0] = Rectangle{
            .x = (Global.screenWidth / 2),
            .y = Global.screenHeight / 2,
            .width = startingSize,
            .height = startingSize,
        };
        self.directionBuffer[0] = utils.Direction.left;

        self.sectionBufferLength = initSize;
        for ((self.sectionBuffer[0..self.sectionBufferLength]), 0..) |*section, idx| {
            const i_f32: f32 = @floatFromInt(idx + 1);
            self.recBuffer[idx + 1] = Rectangle{
                .x = (Global.screenWidth / 2) + (startingSize * i_f32),
                .y = Global.screenHeight / 2,
                .width = startingSize,
                .height = startingSize,
            };
            section.* = Section{
                .recIdx = idx + 1,
                .directionIdx = idx + 1,
                .targetPool = self.targetBuffer.ptr + (idx * 50),
            };
            self.directionBuffer[idx + 1] = utils.Direction.left;
        }
        self.recBufferLength = self.sectionBufferLength + 1;
        self.directionBufferLength = self.sectionBufferLength + 1;
    }

    pub inline fn init(allocator: *utils.Allocator) !Snake {
        var self = Snake{};

        self.sectionBufferLength = initSize;
        self.recBuffer = try allocator.alloc(Rectangle, sectionMaxSize);
        self.sectionBuffer = try allocator.alloc(Section, sectionMaxSize);
        self.targetBuffer = try allocator.alloc(Target, sectionMaxSize * 50);
        self.directionBuffer = try allocator.alloc(utils.Direction, sectionMaxSize);

        self.head = Head{
            .recIdx = 0,
            .directionIdx = 0,
        };
        self.recBuffer[0] = Rectangle{
            .x = (Global.screenWidth / 2),
            .y = Global.screenHeight / 2,
            .width = startingSize,
            .height = startingSize,
        };
        self.directionBuffer[0] = utils.Direction.left;

        for ((self.sectionBuffer[0..self.sectionBufferLength]), 0..) |*section, idx| {
            const i_f32: f32 = @floatFromInt(idx + 1);
            self.recBuffer[idx + 1] = Rectangle{
                .x = (Global.screenWidth / 2) + (startingSize * i_f32),
                .y = Global.screenHeight / 2,
                .width = startingSize,
                .height = startingSize,
            };
            section.* = Section{
                .recIdx = idx + 1,
                .directionIdx = idx + 1,
                .targetPool = self.targetBuffer.ptr + (idx * 50),
            };
            self.directionBuffer[idx + 1] = utils.Direction.left;
        }

        self.recBufferLength = self.sectionBufferLength + 1;
        self.directionBufferLength = self.sectionBufferLength + 1;

        return self;
    }

    pub inline fn update(self: *Snake, direction: utils.Direction) void {
        if (self.directionBuffer[self.head.directionIdx] == direction or
            self.directionBuffer[self.head.directionIdx] == direction.opposite()) return;

        self.directionBuffer[self.head.directionIdx] = direction;

        for ((self.sectionBuffer[0..(self.sectionBufferLength)]), 0..) |*section, idx| {
            _ = idx;
            section.targetPool[section.targetCurrentIdx] = Target{
                .nextDirection = direction,
                .position = utils.Point{
                    .x = self.recBuffer[self.head.recIdx].x,
                    .y = self.recBuffer[self.head.recIdx].y,
                },
            };

            section.*.targetCurrentIdx += 1;
        }
    }

    pub inline fn selfCollision(self: *Snake) bool {
        const head = self.recBuffer[self.head.recIdx];
        const direction = self.directionBuffer[self.head.directionIdx];

        for (self.sectionBuffer[0..self.sectionBufferLength]) |*section| {
            const sectionRec = self.recBuffer[section.recIdx];
            switch (direction) {
                .up => {
                    if (head.x == sectionRec.x and head.y == sectionRec.y + sectionRec.height)
                        return true;
                },
                .down => {
                    if (head.x == sectionRec.x and head.y + head.height == sectionRec.y)
                        return true;
                },
                .left => {
                    if (head.x == sectionRec.x + sectionRec.width and head.y == sectionRec.y)
                        return true;
                },
                .right => {
                    if (head.x + head.width == sectionRec.x and head.y == sectionRec.y)
                        return true;
                },
            }
        }
        return false;
    }

    pub inline fn fruitOverlap(self: Snake, fruit: Fruit) bool {
        var idx: usize = 0;
        while (idx < self.recBufferLength) : (idx += 1) {
            if (self.recBuffer[idx].checkCollision(fruit.fruit))
                return true;
        }
        return false;
    }

    inline fn handleQueue(self: *Snake) void {
        for (self.sectionBuffer[0..self.sectionBufferLength]) |*section| {
            if (self.recBuffer[section.recIdx].y >= (section.targetPool[0].position.y - 1.05) and
                self.recBuffer[section.recIdx].y <= (section.targetPool[0].position.y + 1.05) and
                self.recBuffer[section.recIdx].x >= (section.targetPool[0].position.x - 1.05) and
                self.recBuffer[section.recIdx].x <= (section.targetPool[0].position.x + 1.05))
            {
                self.recBuffer[section.recIdx].x = section.targetPool[0].position.x;
                self.recBuffer[section.recIdx].y = section.targetPool[0].position.y;

                self.directionBuffer[section.directionIdx] = section.targetPool[0].nextDirection;

                queueShift(section.targetPool);

                if (section.targetCurrentIdx != 0) {
                    section.targetCurrentIdx -= 1;
                }
            }
        }
    }

    pub inline fn move(self: *Snake, dt: f32) void {
        var i: usize = 0;

        utils.moveRec(
            &self.recBuffer[self.head.recIdx],
            switch (self.directionBuffer[self.head.directionIdx]) {
                .left => -(self.movementSpeed * dt),
                .right => (self.movementSpeed * dt),
                else => 0,
            },
            switch (self.directionBuffer[self.head.directionIdx]) {
                .up => -(self.movementSpeed * dt),
                .down => (self.movementSpeed * dt),
                else => 0,
            },
        );

        utils.teleport(&self.recBuffer[self.head.recIdx]);

        var prevRec = &self.recBuffer[self.head.recIdx];
        while (i < self.sectionBufferLength) : (i += 1) {
            utils.moveRecIfNoColision(
                &self.recBuffer[self.sectionBuffer[i].recIdx],
                prevRec,
                self.directionBuffer[self.sectionBuffer[i].directionIdx],
                switch (self.directionBuffer[self.sectionBuffer[i].directionIdx]) {
                    .left => -(self.movementSpeed * dt),
                    .right => (self.movementSpeed * dt),
                    else => 0,
                },
                switch (self.directionBuffer[self.sectionBuffer[i].directionIdx]) {
                    .up => -(self.movementSpeed * dt),
                    .down => (self.movementSpeed * dt),
                    else => 0,
                },
            );
            prevRec = &self.recBuffer[self.sectionBuffer[i].recIdx];
            utils.teleport(&self.recBuffer[self.sectionBuffer[i].recIdx]);
        }

        self.handleQueue();
    }

    pub fn render(self: *Snake) void {
        var i: usize = 0;

        while (i < self.sectionBufferLength) : (i += 1) {
            raylib.drawRectangleRounded(
                self.recBuffer[self.sectionBuffer[i].recIdx],
                0.45,
                500,
                bodyColour,
            );
        }

        raylib.drawRectangleRounded(self.recBuffer[self.head.recIdx], 0.45, 500, headColour);
    }
};

const Head = struct {
    recIdx: usize,
    directionIdx: usize,
};

const Section = struct {
    recIdx: usize,
    directionIdx: usize,
    targetPool: [*]Target,
    targetCurrentIdx: usize = 0,
};

const Target = struct { position: utils.Point, nextDirection: utils.Direction };

inline fn queueShift(targets: [*]Target) void {
    var idx: usize = 0;
    while (idx < 50) : (idx += 1) {
        if (idx == 49) {
            targets[idx] = undefined;
            continue;
        }
        targets[idx] = targets[idx + 1];
    }
}
