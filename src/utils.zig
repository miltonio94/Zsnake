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

// TODO: author collision function

pub inline fn moveRecIfNoColision(
    source: *Rectangle,
    check: *Rectangle,
    direction: Direction,
    x: f32,
    y: f32,
) void {
    switch (direction) {
        .left, .right => {
            if (source.y == check.y) {
                if ((source.x < (check.x + check.width) and
                    (source.x + source.width) > check.x) and
                    (source.y < (check.y + check.height) and
                    (source.y + source.height) > check.y))
                {
                    source.y += y;
                } else {
                    source.x += x;
                    source.y += y;
                }
            } else {
                source.x += x;
                source.y += y;
            }
        },
        .up, .down => {
            if (source.x == check.x) {
                if ((source.x < (check.x + check.width) and
                    (source.x + source.width) > check.x) and
                    (source.y < (check.y + check.height) and
                    (source.y + source.height) > check.y))
                {
                    source.x += x;
                } else {
                    source.x += x;
                    source.y += y;
                }
            } else {
                source.x += x;
                source.y += y;
            }
        },
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
    menu_toggle,
    select,
    no_op,
};

pub const Command = union(Command_) {
    direction: Direction,
    pause_toggle,
    menu_toggle,
    select,
    no_op,

    pub fn keyToCommand(key: Keys) Command {
        return switch (key) {
            Keys.key_escape => .menu_toggle,
            Keys.key_enter => .select,
            Keys.key_p => .pause_toggle,
            Keys.key_up, Keys.key_k => Command{ .direction = Direction.up },
            Keys.key_down, Keys.key_j => Command{ .direction = Direction.down },
            Keys.key_left, Keys.key_h => Command{ .direction = Direction.left },
            Keys.key_right, Keys.key_l => Command{ .direction = Direction.right },
            else => .no_op,
        };
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

pub inline fn drawTextCentered(text: [*:0]const u8, fontSize: i32, font: raylib.Font, fontSpacing: f32, colour: raylib.Color, yOffset: f32) void {
    const textWidth = raylib.measureText(text, fontSize);
    raylib.drawTextEx(
        font,
        text,
        .{ .x = global.screenWidth / 2 - @as(f32, @floatFromInt(@divTrunc(textWidth, 2))), .y = global.screenHeight / 2 + yOffset },
        fontSize,
        fontSpacing,
        colour,
    );
}

pub inline fn printRecPos(prefix: []const u8, rec: Rectangle) void {
    std.debug.print("{s}x: {d}, y: {d}\n", .{ prefix, rec.x, rec.y });
}
