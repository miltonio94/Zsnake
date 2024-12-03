const std = @import("std");
const raylib = @import("raylib");
const global = @import("global.zig");
const runMode = @import("builtin").mode;
const Fruit = @import("fruit.zig").Fruit;
const utils = @import("utils.zig");

const OptimizedMode = std.builtin.OptimizeMode;
const Rectangle = raylib.Rectangle;
const Keys = raylib.KeyboardKey;
const print = std.debug.print;

pub const Snake = struct {
    const sectionMaxSize = 50000;
    const initLength: usize = 9;
    const startingSpeed: f32 = 100.0;
    const movement: f32 = 1.0;
    pub const startingSize: f32 = 40.0;

    acceleration: f32 = 100,

    recBuffer: []Rectangle = undefined,
    sectionBuffer: []Section = undefined,
    targetBuffer: []Target = undefined,
    directionBuffer: []utils.Direction = undefined,
    head: Head = undefined,

    sectionBufferLength: usize = 0,
    recBufferLength: usize = 0,
    directionBufferLength: usize = 0,

    pub inline fn reinit(self: *Snake) void {
        // self.movementSpeed = startingSpeed;

        self.head = Head{
            .recIdx = 0,
            .directionIdx = 0,
        };
        self.recBuffer[0] = Rectangle{
            .x = (global.screenWidth / 2),
            .y = global.screenHeight / 2,
            .width = startingSize,
            .height = startingSize,
        };
        self.directionBuffer[0] = utils.Direction.left;

        self.sectionBufferLength = initLength;
        for ((self.sectionBuffer[0..self.sectionBufferLength]), 0..) |*section, idx| {
            const i_f32: f32 = @floatFromInt(idx + 1);
            self.recBuffer[idx + 1] = Rectangle{
                .x = (global.screenWidth / 2) + (startingSize * i_f32),
                .y = global.screenHeight / 2,
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

    pub inline fn grow(self: *Snake) void {
        const section = &self.sectionBuffer[self.sectionBufferLength];
        const prevSection = &self.sectionBuffer[self.sectionBufferLength - 1];
        section.* = .{
            .recIdx = self.recBufferLength,
            .directionIdx = self.directionBufferLength,
            .targetPool = self.targetBuffer.ptr + (self.sectionBufferLength * 50),
        };
        self.sectionBufferLength += 1;
        self.recBufferLength += 1;
        self.directionBufferLength += 1;

        // TODO: Need to copy all targets from prev section to new section
        var idx: usize = 0;
        while (idx < prevSection.targetCurrentIdx) : (idx += 1) {
            section.targetPool[idx] = prevSection.targetPool[idx];
        }

        self.recBuffer[section.recIdx] = Rectangle{
            .x = switch (self.directionBuffer[prevSection.directionIdx]) {
                .up => self.recBuffer[prevSection.recIdx].x,
                .down => self.recBuffer[prevSection.recIdx].x,
                .left => self.recBuffer[prevSection.recIdx].x + startingSize,
                .right => self.recBuffer[prevSection.recIdx].x - startingSize,
            },
            .y = switch (self.directionBuffer[prevSection.directionIdx]) {
                .up => self.recBuffer[prevSection.recIdx].y + startingSize,
                .down => self.recBuffer[prevSection.recIdx].y - startingSize,
                .left => self.recBuffer[prevSection.recIdx].y,
                .right => self.recBuffer[prevSection.recIdx].y,
            },
            .width = startingSize,
            .height = startingSize,
        };
        self.directionBuffer[section.directionIdx] = self.directionBuffer[prevSection.directionIdx];
    }

    pub inline fn init(allocator: *utils.Allocator) !Snake {
        var self = Snake{};

        self.sectionBufferLength = initLength;
        self.recBuffer = try allocator.alloc(Rectangle, sectionMaxSize);
        self.sectionBuffer = try allocator.alloc(Section, sectionMaxSize);
        self.targetBuffer = try allocator.alloc(Target, sectionMaxSize * 50);
        self.directionBuffer = try allocator.alloc(utils.Direction, sectionMaxSize);

        self.head = Head{
            .recIdx = 0,
            .directionIdx = 0,
        };
        self.recBuffer[0] = Rectangle{
            .x = (global.screenWidth / 2),
            .y = global.screenHeight / 2,
            .width = startingSize,
            .height = startingSize,
        };
        self.directionBuffer[0] = utils.Direction.left;

        for ((self.sectionBuffer[0..self.sectionBufferLength]), 0..) |*section, idx| {
            const i_f32: f32 = @floatFromInt(idx + 1);
            self.recBuffer[idx + 1] = Rectangle{
                .x = (global.screenWidth / 2) + (startingSize * i_f32),
                .y = global.screenHeight / 2,
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

    pub inline fn directionChange(self: *Snake, direction: utils.Direction) void {
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
        const checkOverlapArea = switch (self.directionBuffer[self.head.directionIdx]) {
            .up => Rectangle{
                .x = self.recBuffer[self.head.recIdx].x + (self.recBuffer[self.head.recIdx].width * 0.25),
                .y = self.recBuffer[self.head.recIdx].y,
                .width = self.recBuffer[self.head.recIdx].width * 0.25,
                .height = 1.0,
            },
            .down => Rectangle{
                .x = self.recBuffer[self.head.recIdx].x + (self.recBuffer[self.head.recIdx].width * 0.25),
                .y = self.recBuffer[self.head.recIdx].y + self.recBuffer[self.head.recIdx].height,
                .width = self.recBuffer[self.head.recIdx].width * 0.25,
                .height = 1.0,
            },
            .left => Rectangle{
                .x = self.recBuffer[self.head.recIdx].x,
                .y = self.recBuffer[self.head.recIdx].y + (self.recBuffer[self.head.recIdx].height * 0.25),
                .width = 1.0,
                .height = self.recBuffer[self.head.recIdx].height * 0.25,
            },
            .right => Rectangle{
                .x = self.recBuffer[self.head.recIdx].x + self.recBuffer[self.head.recIdx].width,
                .y = self.recBuffer[self.head.recIdx].y + (self.recBuffer[self.head.recIdx].height * 0.25),
                .width = 1.0,
                .height = self.recBuffer[self.head.recIdx].height * 0.25,
            },
        };

        // NOTE: Impossible to collide with first two sections
        for (self.sectionBuffer[2..self.sectionBufferLength]) |*section| {
            const sectionRec = self.recBuffer[section.recIdx];
            if (checkOverlapArea.checkCollision(sectionRec)) {
                return true;
            }
        }
        return false;
    }

    pub inline fn hasEatenFruit(self: Snake, fruit: Fruit) bool {
        return fruit.fruit.checkCollision(self.recBuffer[self.head.recIdx]);
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
            const collisionArea = switch (self.directionBuffer[section.directionIdx]) {
                .up => Rectangle{
                    .x = section.targetPool[0].position.x,
                    .y = section.targetPool[0].position.y + (self.recBuffer[section.recIdx].height - 1),
                    .width = 2,
                    .height = 2,
                },
                .right => Rectangle{
                    .x = section.targetPool[0].position.x + (self.recBuffer[section.recIdx].width - 2) - 1,
                    .y = section.targetPool[0].position.y,
                    .width = 2,
                    .height = 2,
                },
                else => Rectangle{
                    .x = section.targetPool[0].position.x,
                    .y = section.targetPool[0].position.y,
                    .width = 2,
                    .height = 2,
                },
            };
            if (self.recBuffer[section.recIdx].checkCollision(collisionArea)) {
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
        // TODO: implement acceleration
        var i: usize = 0;

        self.handleQueue();

        utils.moveRec(
            &self.recBuffer[self.head.recIdx],
            switch (self.directionBuffer[self.head.directionIdx]) {
                .left => -(movement * dt),
                .right => (movement * dt),
                else => 0,
            },
            switch (self.directionBuffer[self.head.directionIdx]) {
                .up => -(movement * dt),
                .down => (movement * dt),
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
                    .left => -(movement * dt),
                    .right => (movement * dt),
                    else => 0,
                },
                switch (self.directionBuffer[self.sectionBuffer[i].directionIdx]) {
                    .up => -(movement * dt),
                    .down => (movement * dt),
                    else => 0,
                },
            );
            prevRec = &self.recBuffer[self.sectionBuffer[i].recIdx];
            utils.teleport(&self.recBuffer[self.sectionBuffer[i].recIdx]);
        }
    }

    pub fn render(self: Snake) void {
        var i: usize = 0;

        while (i < self.sectionBufferLength) : (i += 1) {
            raylib.drawRectangleRounded(
                self.recBuffer[self.sectionBuffer[i].recIdx],
                0.45,
                500,
                global.yellow,
            );
        }

        raylib.drawRectangleRounded(self.recBuffer[self.head.recIdx], 0.45, 500, global.orange);
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
