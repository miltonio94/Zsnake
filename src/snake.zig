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
    const sectionMaxSize = 500;
    const initLength: usize = 2;
    const movement: f32 = 10.0;
    const startingDimension: f32 = 40.0;

    acceleration: f32 = 1,

    posBuffer: []f32 = undefined,
    sectionBuffer: []Section = undefined,
    targetBuffer: []Target = undefined,
    directionBuffer: []utils.Direction = undefined,
    head: Head = undefined,

    sectionBufferLength: usize = 0,
    posBufferLength: usize = 0,
    directionBufferLength: usize = 0,

    pub inline fn init(allocator: *std.mem.Allocator) !Snake {
        var self = Snake{};

        self.sectionBufferLength = initLength;
        self.posBuffer = try allocator.alloc(f32, (sectionMaxSize * 2) + 2);
        self.sectionBuffer = try allocator.alloc(Section, sectionMaxSize);
        self.targetBuffer = try allocator.alloc(Target, sectionMaxSize * 50);
        self.directionBuffer = try allocator.alloc(utils.Direction, sectionMaxSize + 1);

        utils.initBuffer(f32, self.posBuffer.ptr, 0.0, self.posBuffer.len);
        utils.initBuffer(Section, self.sectionBuffer.ptr, .{
            .posIdx = 0,
            .directionIdx = 0,
            .targetPool = undefined,
            .targetCurrentIdx = 0,
        }, self.posBuffer.len);
        utils.initBuffer(
            Target,
            self.targetBuffer.ptr,
            .{
                .position = .{
                    .x = 0.0,
                    .y = 0.0,
                },
                .nextDirection = utils.Direction.left,
            },
            self.targetBuffer.len,
        );
        utils.initBuffer(utils.Direction, self.directionBuffer.ptr
                             , utils.Direction.left
                             , self.directionBuffer.len,);

        self.head = Head{
            .positionIdx = 0,
            .directionIdx = 0,
        };
        self.posBuffer[0] = (global.screenWidth / 2);
        self.posBuffer[1] = global.screenHeight / 2;

        self.directionBuffer[0] = utils.Direction.left;
        for ((self.sectionBuffer[0..self.sectionBufferLength]), 0..) |*section, idx| {
            const i_f32: f32 = @floatFromInt(idx + 1);
            self.posBuffer[(idx * 2) + 2] = (global.screenWidth / 2) + (startingDimension * i_f32);
            self.posBuffer[(idx * 2) + 3] = global.screenHeight / 2;

            section.* = Section{
                .posIdx = (idx * 2) + 2,
                .directionIdx = idx + 1,
                .targetPool = self.targetBuffer.ptr + (idx * 50),
            };
            self.directionBuffer[idx + 1] = utils.Direction.left;
        }

        self.posBufferLength = (self.sectionBufferLength + 1) * 2;
        self.directionBufferLength = self.sectionBufferLength + 1;

        return self;
    }

    pub inline fn reinit(self: *Snake) void {
        self.head = Head{
            .positionIdx = 0,
            .directionIdx = 0,
        };
        self.posBuffer[0] = (global.screenWidth / 2);
        self.posBuffer[1] = global.screenHeight / 2;
        self.directionBuffer[0] = utils.Direction.left;

        self.sectionBufferLength = initLength;
        for ((self.sectionBuffer[0..self.sectionBufferLength]), 0..) |*section, idx| {
            const i_f32: f32 = @floatFromInt(idx + 1);

            self.posBuffer[(idx * 2) + 2] = (global.screenWidth / 2) + (startingDimension * i_f32);
            self.posBuffer[(idx * 2) + 3] = global.screenHeight / 2;

            section.* = Section{
                .posIdx = (idx * 2) + 2,
                .directionIdx = idx + 1,
                .targetPool = self.targetBuffer.ptr + (idx * 50),
            };
            self.directionBuffer[idx + 1] = utils.Direction.left;
        }
        self.posBufferLength = (self.sectionBufferLength + 1) * 2;
        self.directionBufferLength = self.sectionBufferLength + 1;
    }

    pub inline fn grow(self: *Snake) void {
        const section = &self.sectionBuffer[self.sectionBufferLength];
        const prevSection = &self.sectionBuffer[self.sectionBufferLength - 1];
        section.* = .{
            .posIdx = self.posBufferLength,
            .directionIdx = self.directionBufferLength,
            .targetPool = self.targetBuffer.ptr + (self.sectionBufferLength * 50),
        };
        self.sectionBufferLength += 1;
        self.posBufferLength += 2;
        self.directionBufferLength += 1;

        // TODO: Need to copy all targets from prev section to new section
        var idx: usize = 0;
        while (idx < prevSection.targetCurrentIdx) : (idx += 1) {
            section.targetPool[idx] = prevSection.targetPool[idx];
        }

        self.posBuffer[section.posIdx] = switch (self.directionBuffer[prevSection.directionIdx]) {
            .up => self.posBuffer[prevSection.posIdx],
            .down => self.posBuffer[prevSection.posIdx],
            .left => self.posBuffer[prevSection.posIdx] + startingDimension,
            .right => self.posBuffer[prevSection.posIdx] - startingDimension,
        };
        self.posBuffer[section.posIdx + 1] = switch (self.directionBuffer[prevSection.directionIdx]) {
            .up => self.posBuffer[prevSection.posIdx + 1] + startingDimension,
            .down => self.posBuffer[prevSection.posIdx + 1] - startingDimension,
            .left => self.posBuffer[prevSection.posIdx + 1],
            .right => self.posBuffer[prevSection.posIdx + 1],
        };
        self.directionBuffer[section.directionIdx] = self.directionBuffer[prevSection.directionIdx];
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
                    .x = self.posBuffer[self.head.positionIdx],
                    .y = self.posBuffer[self.head.positionIdx + 1],
                },
            };

            section.*.targetCurrentIdx += 1;
        }
    }

    pub inline fn selfCollision(self: *Snake) bool {
        const checkOverlapArea = switch (self.directionBuffer[self.head.directionIdx]) {
            .up => Rectangle{
                .x = self.posBuffer[self.head.positionIdx] + (startingDimension * 0.25),
                .y = self.posBuffer[self.head.positionIdx + 1],
                .width = startingDimension * 0.25,
                .height = 1.0,
            },
            .down => Rectangle{
                .x = self.posBuffer[self.head.positionIdx] + (startingDimension * 0.25),
                .y = self.posBuffer[self.head.positionIdx + 1] + startingDimension,
                .width = startingDimension * 0.25,
                .height = 1.0,
            },
            .left => Rectangle{
                .x = self.posBuffer[self.head.positionIdx],
                .y = self.posBuffer[self.head.positionIdx + 1] + (startingDimension * 0.25),
                .width = 1.0,
                .height = startingDimension * 0.25,
            },
            .right => Rectangle{
                .x = self.posBuffer[self.head.positionIdx] + startingDimension,
                .y = self.posBuffer[self.head.positionIdx + 1] + (startingDimension * 0.25),
                .width = 1.0,
                .height = startingDimension * 0.25,
            },
        };

        // NOTE: Impossible to collide with first two sections
        for (self.sectionBuffer[2..self.sectionBufferLength]) |*section| {
            // TODO: Stop depending on Rectangle for collision
            const sectionRec = Rectangle{
                .x = self.posBuffer[section.posIdx],
                .y = self.posBuffer[section.posIdx + 1],
                .width = startingDimension,
                .height = startingDimension,
            };
            if (checkOverlapArea.checkCollision(sectionRec)) {
                return true;
            }
        }
        return false;
    }

    pub inline fn hasEatenFruit(self: Snake, fruit: Fruit) bool {
        // TODO: Look into checkCollisionPoint
        return fruit.fruit.checkCollision(
            Rectangle{
                .x = self.posBuffer[self.head.positionIdx],
                .y = self.posBuffer[self.head.positionIdx + 1],
                .width = startingDimension,
                .height = startingDimension,
            },
        );
    }

    pub inline fn fruitOverlap(self: Snake, fruit: Fruit) bool {
        var idx: usize = 0;
        while (idx < self.posBufferLength) : (idx += 1) {
            if (fruit.fruit.checkCollision(
                Rectangle{
                    .x = self.posBuffer[idx * 2],
                    .y = self.posBuffer[(idx * 2) + 1],
                    .width = startingDimension,
                    .height = startingDimension,
                },
            )) {
                return true;
            }
        }
        return false;
    }

    inline fn handleQueue(self: *Snake) void {
        for (self.sectionBuffer[0..self.sectionBufferLength]) |*section| {
            const collisionArea = switch (self.directionBuffer[section.directionIdx]) {
                .down => Rectangle{
                    .x = section.targetPool[0].position.x,
                    .y = section.targetPool[0].position.y + (startingDimension - 1),
                    .width = 2,
                    .height = 2,
                },
                .right => Rectangle{
                    .x = section.targetPool[0].position.x + (startingDimension - 2) - 1,
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
            if (collisionArea.checkCollision(
                Rectangle{
                    .x = self.posBuffer[section.posIdx],
                    .y = self.posBuffer[section.posIdx + 1],
                    .width = startingDimension,
                    .height = startingDimension,
                },
            )) {
                self.posBuffer[section.posIdx] = section.targetPool[0].position.x;
                self.posBuffer[section.posIdx + 1] = section.targetPool[0].position.y;

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

        utils.movePos(
            (self.posBuffer.ptr + self.head.positionIdx),
            switch (self.directionBuffer[self.head.directionIdx]) {
                .left => -(movement * (self.acceleration * dt)),
                .right => movement * (self.acceleration * dt),
                else => 0,
            },
            switch (self.directionBuffer[self.head.directionIdx]) {
                .up => -(movement * (self.acceleration * dt)),
                .down => movement * (self.acceleration * dt),
                else => 0,
            },
        );

        utils.teleport((self.posBuffer.ptr + self.head.positionIdx), startingDimension);

        var prevRec = self.posBuffer.ptr + self.head.positionIdx;
        while (i < self.sectionBufferLength) : (i += 1) {
            utils.movePosIfNoColision(
                (self.posBuffer.ptr + self.sectionBuffer[i].posIdx),
                prevRec,
                startingDimension,
                startingDimension,
                self.directionBuffer[self.sectionBuffer[i].directionIdx],
                switch (self.directionBuffer[self.sectionBuffer[i].directionIdx]) {
                    .left => -(movement * self.acceleration * dt),
                    .right => (movement * self.acceleration * dt),
                    else => 0,
                },
                switch (self.directionBuffer[self.sectionBuffer[i].directionIdx]) {
                    .up => -(movement * self.acceleration * dt),
                    .down => (movement * self.acceleration * dt),
                    else => 0,
                },
            );
            prevRec = self.posBuffer.ptr + self.sectionBuffer[i].posIdx;
            utils.teleport((self.posBuffer.ptr + self.sectionBuffer[i].posIdx), startingDimension);
        }

        self.handleQueue();
    }

    pub fn render(self: Snake) void {
        var i: usize = 0;

        while (i < self.sectionBufferLength) : (i += 1) {
            raylib.drawRectangleRounded(
                Rectangle{
                    .x = self.posBuffer[self.sectionBuffer[i].posIdx],
                    .y = self.posBuffer[self.sectionBuffer[i].posIdx + 1],
                    .width = startingDimension,
                    .height = startingDimension,
                },
                0.45,
                500,
                global.yellow,
            );
        }

        raylib.drawRectangleRounded(
            Rectangle{
                .x = self.posBuffer[self.head.positionIdx],
                .y = self.posBuffer[self.head.positionIdx + 1],
                .width = startingDimension,
                .height = startingDimension,
            },
            0.45,
            500,
            global.orange,
        );
    }
};

const Head = struct {
    positionIdx: usize,
    directionIdx: usize,
};

const Section = struct {
    posIdx: usize,
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
