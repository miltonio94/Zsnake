const std = @import("std");
const raylib = @import("raylib");
const global = @import("global.zig");
const builtin = @import("builtin");

const Rectangle = raylib.Rectangle;
const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const pager = std.heap.page_allocator;
const HeapAllocator = std.heap.HeapAllocator;
const Error = std.mem.Allocator.Error;
const Keys = raylib.KeyboardKey;

pub const Allocator = switch (builtin.os.tag) {
    .windows => struct {
        fba: FixedBufferAllocator = undefined,
        ha: HeapAllocator = undefined,
        heapAllocator: std.mem.Allocator = undefined,
        allocator: std.mem.Allocator = undefined,
        memBuffer: []u8 = undefined,

        pub fn init(size: usize) !Allocator {
            var self = Allocator{
                .ha = HeapAllocator.init(),
            };
            self.heapAllocator = self.ha.allocator();
            self.memBuffer = try self.heapAllocator.alloc(u8, size);

            self.fba = FixedBufferAllocator.init(self.memBuffer);
            self.allocator = self.fba.allocator();

            return self;
        }

        pub fn deinit(self: *Allocator) void {
            self.ha.deinit();
        }

        pub fn alloc(self: *Allocator, comptime T: type, size: usize) Error![]T {
            return self.allocator.alloc(T, size);
        }
    },
    else => struct {
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
            std.debug.print("allocating \n", .{});
            return self.allocator.alloc(T, size);
        }
    },
};

pub inline fn movePos(pos: [*]f32, x: f32, y: f32) void {
    pos[0] += x;
    pos[1] += y;
}

pub inline fn movePosIfNoColision(
    source: [*]f32,
    check: [*]f32,
    sourceDimension: f32,
    checkDimension: f32,
    direction: Direction,
    x: f32,
    y: f32,
) void {
    switch (direction) {
        .left, .right => {
            if (source[1] == check[1]) {
                if ((source[0] < (check[0] + checkDimension) and
                    (source[0] + sourceDimension) > check[0]) and
                    (source[1] < (check[1] + checkDimension) and
                    (source[1] + sourceDimension) > check[1]))
                {
                    source[1] += y;
                } else {
                    source[0] += x;
                    source[1] += y;
                }
            } else {
                source[0] += x;
                source[1] += y;
            }
        },
        .up, .down => {
            if (source[0] == check[0]) {
                if ((source[0] < (check[0] + checkDimension) and
                    (source[0] + sourceDimension) > check[0]) and
                    (source[1] < (check[1] + checkDimension) and
                    (source[1] + sourceDimension) > check[1]))
                {
                    source[0] += x;
                } else {
                    source[0] += x;
                    source[1] += y;
                }
            } else {
                source[0] += x;
                source[1] += y;
            }
        },
    }
}

pub inline fn teleport(pos: [*]f32, dimension: f32) void {
    if (pos[0] > global.screenWidth + dimension) {
        pos[0] = 0;
        return;
    }
    if (pos[0] < 0 - dimension) {
        pos[0] = global.screenWidth;
        return;
    }
    if (pos[1] > global.screenHeight + dimension) {
        pos[1] = 0;
        return;
    }
    if (pos[1] < 0 - dimension) {
        pos[1] = global.screenHeight;
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
