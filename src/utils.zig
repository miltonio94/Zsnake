const std = @import("std");
const raylib = @import("raylib");
const global = @import("global.zig");

const Rectangle = raylib.Rectangle;
const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const pager = std.heap.page_allocator;
const Error = std.mem.Allocator.Error;
const Keys = raylib.KeyboardKey;

pub const Allocator = struct {
    fba: FixedBufferAllocator = undefined,
    allocator: std.mem.Allocator = undefined,
    memBuffer: []u8,

    // TODO: Pass allocator size to function
    pub fn init() !Allocator {
        var self = Allocator{
            .memBuffer = try pager.alloc(u8, 100 * 1024 * 1024),
        };

        self.fba = FixedBufferAllocator.init(self.memBuffer);
        self.allocator = self.fba.allocator();

        return self;
    }

    pub fn deinit(self: *Allocator) void {
        pager.free(self.memBuffer);
    }

    pub fn alloc(self: *Allocator, comptime T: type, size: usize) Error![]T {
        return self.allocator.alloc(T, size);
    }
};

pub inline fn moveRec(rec: *Rectangle, x: f32, y: f32) void {
    rec.x += x;
    rec.y += y;
}

pub inline fn moveRecIfNoColision(sourceRec: *Rectangle, checkForColisionRec: *Rectangle, x: f32, y: f32) void {
    const newX = sourceRec.x + x;
    const newY = sourceRec.y + y;
    if ((newX < (checkForColisionRec.x + checkForColisionRec.width) and (newX + sourceRec.width) > checkForColisionRec.x)) {
        sourceRec.x = newX;
    }
    if ((newY < (checkForColisionRec.y + checkForColisionRec.height) and (newY + sourceRec.height) > checkForColisionRec.y)) {
        sourceRec.y = newY;
    }
}

pub fn teleport(rec: *Rectangle) void {
    if (rec.x > global.screenWidth + rec.width) {
        rec.x = 0;
        return;
    }
    if (rec.x < 0 - rec.width) {
        rec.x = global.screenWidth;
        return;
    }
    if (rec.y > global.screenHeight + rec.height) {
        rec.y = 0;
        return;
    }
    if (rec.y < 0 - rec.height) {
        rec.y = global.screenHeight;
        return;
    }
}

pub const Command_ = enum {
    direction,
    pause_toggle,
    no_op,
};

pub const Command = union(Command_) {
    direction: Direction,
    pause_toggle,
    no_op,

    pub fn keyToCommand(key: Keys) Command {
        switch (key) {
            Keys.key_p => return .pause_toggle,
            Keys.key_up, Keys.key_k => return Command{ .direction = Direction.up },
            Keys.key_down, Keys.key_j => return Command{ .direction = Direction.down },
            Keys.key_left, Keys.key_h => return Command{ .direction = Direction.left },
            Keys.key_right, Keys.key_l => return Command{ .direction = Direction.right },
            else => return .no_op,
        }
        return .no_op;
    }
};

pub const Direction = enum {
    up,
    down,
    left,
    right,
    pub inline fn opposite(direction: Direction) Direction {
        return switch (direction) {
            .up => .down,
            .down => .up,
            .left => .right,
            .right => .left,
        };
    }
};

pub const Point = struct { x: f32, y: f32 };
