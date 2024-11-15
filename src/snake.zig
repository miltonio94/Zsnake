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

pub const startingSize: f32 = 40.0;

pub const Snake = struct {
    const sectionMaxSize = 50000;
    const headColour = Colour{ .r = 234, .g = 104, .b = 71, .a = 255 };
    const bodyColour = Colour{ .r = 255, .g = 162, .b = 0, .a = 255 };

    movementSpeed: f32 = 100,

    recBuffer: []Rectangle = undefined,
    sectionBuffer: []Section = undefined,
    targetBuffer: []Target = undefined,
    directionBuffer: []utils.Direction = undefined,
    head: Head = undefined,

    sectionBufferLength: usize = 3,
    recBufferLength: usize = 0,
    directionBufferLength: usize = 0,

    pub inline fn init(allocator: *utils.Allocator) !Snake {
        var self = Snake{};

        self.recBuffer = try allocator.alloc(Rectangle, sectionMaxSize);
        self.sectionBuffer = try allocator.alloc(Section, sectionMaxSize);
        self.targetBuffer = try allocator.alloc(Target, sectionMaxSize * 50);
        self.directionBuffer = try allocator.alloc(utils.Direction, sectionMaxSize);

        print("self.recBuffer {any}\n", .{self.recBuffer.len});
        print("self.sectionBuffer {any}\n", .{self.sectionBuffer.len});
        print("self.targetBuffer {any}\n", .{self.targetBuffer.len});
        print("self.directionBuffer {any}\n", .{self.directionBuffer.len});

        // init Head
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
            print("idx: {}, i_f32 {d:.6}\n", .{ idx, i_f32 });
            self.recBuffer[idx + 1] = Rectangle{
                .x = (Global.screenWidth / 2) + (startingSize * i_f32),
                .y = Global.screenHeight / 2,
                .width = startingSize,
                .height = startingSize,
            };
            section.* = Section{
                .recIdx = idx + 1,
                .directionIdx = idx + 1,
                .targetPool = &self.sectionBuffer[(idx * 50)..(((idx + 1) * 50))],
                .targetPoolStart = idx * 50,
                .targetPoolEnd = ((idx + 1) * 50) - 1,
            };
            self.directionBuffer[idx + 1] = utils.Direction.left;
        }

        self.recBufferLength = 4;
        self.directionBufferLength = 3;

        return self;
    }

    pub fn update(self: *Snake, direction: utils.Direction) void {
        if (self.directionBuffer[self.head.directionIdx] == direction or
            self.directionBuffer[self.head.directionIdx] == direction.opposite()) return;

        self.directionBuffer[self.head.directionIdx] = direction;

        var i: usize = 0;

        while (i < self.sectionBufferLength) : (i += 1) {
            self.targetBuffer[self.sectionBuffer[i].targetCurrentIdx] = Target{
                .nextDirection = direction,
                .position = utils.Point{
                    .x = self.recBuffer[self.head.recIdx].x,
                    .y = self.recBuffer[self.head.recIdx].y,
                },
            };
        }
    }

    inline fn handleQueue(self: *Snake) void {
        var i: usize = 0;

        // print("buffer len {}\n", .{self.sectionBufferLength});

        while (i < self.sectionBufferLength) : (i += 1) {
            // print("handleQueue i {}\n", .{i}); //
            const nextTarget = &self.targetBuffer[self.sectionBuffer[i].targetPoolStart];
            const section = &self.recBuffer[self.sectionBuffer[i].recIdx];
            if (section.y > (nextTarget.position.y - 0.25) and
                section.y < (nextTarget.position.y + 0.25) and
                section.x > (nextTarget.position.x - 0.25) and
                section.x < (nextTarget.position.x + 0.25))
            {
                // print("in if\n", .{});
                section.x = nextTarget.position.x;
                section.y = nextTarget.position.y;
                self.directionBuffer[self.sectionBuffer[i].directionIdx] = nextTarget.nextDirection;

                // print("\t {any}  \n", .{self.sectionBuffer[i]});

                // print("\t start {} end {} \n", .{
                //     self.sectionBuffer[i].targetPoolStart,
                //     self.sectionBuffer[i].targetPoolEnd,
                // });

                queueShift(
                    self.targetBuffer,
                    self.sectionBuffer[i].targetPoolStart,
                    self.sectionBuffer[i].targetPoolStart,
                );

                if (self.sectionBuffer[i].targetCurrentIdx != self.sectionBuffer[i].targetPoolStart) {
                    self.sectionBuffer[i].targetCurrentIdx -= 1;
                }
            }
        }
    }

    pub fn move(self: *Snake, dt: f32) void {
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

        while (i < self.sectionBufferLength) : (i += 1) {
            // print("sectionBuffer[{}]\n", .{i});
            // print("self.sectionBuffer[{}].recIdx = {}\n", .{ i, self.sectionBuffer[i].recIdx });
            utils.moveRec(
                &self.recBuffer[self.sectionBuffer[i].recIdx],
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
    targetPool: *const []Section,
    targetCurrentIdx: usize = 0,
    targetPoolStart: usize,
    targetPoolEnd: usize,
};

const Target = struct { position: utils.Point, nextDirection: utils.Direction };

inline fn queueShift(targets: []Target, start: usize, end: usize) void {
    var i: usize = start;
    while (i < end) : (i += 1) {
        // print("\t\t queueShift i {}\n", .{i});
        if (i == end) return;
        targets[i] = targets[i + 1];
    }
}
