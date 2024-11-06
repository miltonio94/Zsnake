const std = @import("std");
const raylib = @import("raylib");
const Snake = @import("snake.old.zig").Snake;
const snake = @import("snake.zig");
const Fruit = @import("fruit.zig").Fruit;
const Global = @import("global.zig");
const builtin = @import("builtin");
const Font = raylib.Font;
const currentPath = std.fs.cwd();

const runMode = builtin.mode;
const Colour = raylib.Color;
const OptimizedMode = std.builtin.OptimizeMode;
const Keys = raylib.KeyboardKey;
const Rectangle = raylib.Rectangle;
const print = std.debug.print;
const BitPotionFont = @embedFile("./assets/BitPotion.ttf");
const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const pager = std.heap.page_allocator;

pub const World = struct {
    const backgroundColour = Colour{ .r = 7, .g = 15, .b = 28, .a = 255 };
    const pauseColour = Colour{ .r = 7, .g = 15, .b = 28, .a = 188 };
    const pausedFontColour = Colour{ .r = 93, .g = 178, .b = 248, .a = 255 };
    const rectOverlay = Rectangle{
        .x = 0,
        .y = 0,
        .width = Global.screenWidth,
        .height = Global.screenHeight,
    };
    const pausedTxt = "Paused";
    const fontSize = 24;
    const fontSpacing = 2.0;
    var font: Font = undefined;
    const sectionMaxSize = 10000;

    dt: f32 = 0,
    movementSpeed: f32 = 100,
    fba: FixedBufferAllocator = undefined,
    allocator: std.mem.Allocator = undefined,
    memBuffer: []u8,
    recBuffer: []Rectangle = undefined,
    sectionBuffer: []snake.Section = undefined,
    targetBuffer: []snake.Target = undefined,
    directionBuffer: []snake.Direction = undefined,
    head: snake.Head = undefined,

    sectionBufferLength: usize = 2,
    recBufferLength: usize = 0,
    directionBufferLength: usize = 0,
    state: State,
    fontPos: raylib.Vector2 = raylib.Vector2{
        .x = Global.screenWidth / 2,
        .y = Global.screenHeight / 2,
    },

    pub fn deinit(self: *World) void {
        pager.free(self.memBuffer);
    }

    pub fn init() !World {
        font = Font.fromMemory("ttf", BitPotionFont, 24, null);

        var self = World{
            .state = .play,
            .fontPos = raylib.Vector2{
                .x = Global.screenWidth / 2 - 70.0,
                .y = 100.0,
            },
            .dt = raylib.getFrameTime(),
            .memBuffer = try pager.alloc(u8, 100 * 1024 * 1024),
        };

        self.fba = FixedBufferAllocator.init(self.memBuffer);
        self.allocator = self.fba.allocator();
        self.recBuffer = try self.allocator.alloc(Rectangle, sectionMaxSize);
        self.sectionBuffer = try self.allocator.alloc(snake.Section, sectionMaxSize);
        self.targetBuffer = try self.allocator.alloc(snake.Target, sectionMaxSize * 50);
        self.directionBuffer = try self.allocator.alloc(snake.Direction, sectionMaxSize);

        self.head = snake.Head{
            .recIdx = 0,
            .directionIdx = 0,
        };

        self.recBuffer[0] = Rectangle{
            .x = (Global.screenWidth / 2),
            .y = Global.screenHeight / 2,
            .width = snake.startingSize,
            .height = snake.startingSize,
        };
        self.recBuffer[1] = Rectangle{
            .x = (Global.screenWidth / 2) + snake.startingSize,
            .y = Global.screenHeight / 2,
            .width = snake.startingSize,
            .height = snake.startingSize,
        };
        self.recBuffer[2] = Rectangle{
            .x = (Global.screenWidth / 2) + (snake.startingSize * 2),
            .y = Global.screenHeight / 2,
            .width = snake.startingSize,
            .height = snake.startingSize,
        };

        self.sectionBuffer[0] = snake.Section{
            .recIdx = 1,
            .directionIdx = 1,
            .targetPoolStart = 0,
            .targetPoolEnd = 49,
        };
        self.sectionBuffer[1] = snake.Section{
            .recIdx = 2,
            .directionIdx = 2,
            .targetPoolStart = 50,
            .targetPoolEnd = 99,
        };

        self.directionBuffer[0] = snake.Direction.left;
        self.directionBuffer[1] = snake.Direction.left;
        self.directionBuffer[2] = snake.Direction.left;

        self.recBufferLength = 3;
        self.directionBufferLength = 3;

        return self;
    }

    fn pauseOverlay(self: *World) void {
        raylib.drawRectangleRec(rectOverlay, pauseColour);
        raylib.drawTextEx(
            font,
            pausedTxt,
            self.fontPos,
            fontSize,
            fontSpacing,
            pausedFontColour,
        );
    }

    fn moveEntities(self: *World) void {
        if (self.state != State.play) return;
        var i: usize = 0;

        moveRec(
            &self.recBuffer[self.head.recIdx],
            switch (self.directionBuffer[self.head.directionIdx]) {
                .left => -(self.movementSpeed * self.dt),
                .right => (self.movementSpeed * self.dt),
                else => 0,
            },
            switch (self.directionBuffer[self.head.directionIdx]) {
                .up => -(self.movementSpeed * self.dt),
                .down => (self.movementSpeed * self.dt),
                else => 0,
            },
        );

        while (i < self.sectionBufferLength) : (i += 1) {
            moveRec(
                &self.recBuffer[self.sectionBuffer[i].recIdx],
                switch (self.directionBuffer[self.sectionBuffer[i].directionIdx]) {
                    .left => -(self.movementSpeed * self.dt),
                    .right => (self.movementSpeed * self.dt),
                    else => 0,
                },
                switch (self.directionBuffer[self.sectionBuffer[i].directionIdx]) {
                    .up => -(self.movementSpeed * self.dt),
                    .down => (self.movementSpeed * self.dt),
                    else => 0,
                },
            );
        }
    }

    fn updateEntitiesDirection(self: *World, direction: snake.Direction) void {
        self.directionBuffer[self.head.directionIdx] = direction;
    }

    pub fn run(self: *World) void {
        raylib.initWindow(Global.screenWidth, Global.screenHeight, "Znake");
        defer raylib.closeWindow();

        raylib.setTargetFPS(200);

        while (!raylib.windowShouldClose()) {
            self.dt = raylib.getFrameTime();
            const command = Command.keyToCommand(raylib.getKeyPressed());

            switch (command) {
                .pause_toggle => {
                    if (self.state == State.play) {
                        self.state = State.paused;
                    } else {
                        self.state = State.play;
                    }
                },
                .direction => |direction| {
                    if (self.state == State.play) {
                        self.updateEntitiesDirection(direction);
                    }
                },
                else => {},
            }

            if (self.state == State.play) {
                self.moveEntities();
            }

            raylib.beginDrawing();
            defer raylib.endDrawing();

            raylib.clearBackground(backgroundColour);

            self.render();

            if (self.state == .paused) {
                self.pauseOverlay();
            }

            if (runMode == OptimizedMode.Debug) {
                raylib.drawFPS(5, 5);
            }
        }
    }

    fn render(self: *World) void {
        var i: usize = 0;

        while (i < self.sectionBufferLength) : (i += 1) {
            raylib.drawRectangleRounded(
                self.recBuffer[self.sectionBuffer[i].recIdx],
                0.45,
                500,
                snake.bodyColour,
            );
        }

        raylib.drawRectangleRounded(self.recBuffer[self.head.recIdx], 0.45, 500, snake.headColour);
    }
};

const Command_ = enum {
    direction,
    pause_toggle,
    no_op,
};

const Command = union(Command_) {
    direction: snake.Direction,
    pause_toggle,
    no_op,

    pub fn keyToCommand(key: Keys) Command {
        switch (key) {
            Keys.key_p => return .pause_toggle,
            Keys.key_up, Keys.key_k => return Command{ .direction = snake.Direction.up },
            Keys.key_down, Keys.key_j => return Command{ .direction = snake.Direction.down },
            Keys.key_left, Keys.key_h => return Command{ .direction = snake.Direction.left },
            Keys.key_right, Keys.key_l => return Command{ .direction = snake.Direction.right },
            else => return .no_op,
        }
        return .no_op;
    }
};

const State = enum {
    paused,
    play,
};

inline fn moveRec(rec: *Rectangle, x: f32, y: f32) void {
    if (rec.x > Global.screenWidth) {
        rec.x = 0;
        return;
    }
    if (rec.x < 0) {
        rec.x = Global.screenWidth;
        return;
    }
    if (rec.y > Global.screenHeight) {
        rec.y = 0;
        return;
    }
    if (rec.y < 0) {
        rec.y = Global.screenHeight;
        return;
    }
    rec.x += x;
    rec.y += y;
}
