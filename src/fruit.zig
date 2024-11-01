const std = @import("std");
const raylib = @import("raylib");
const Global = @import("global.zig");

pub const Fruit = struct {
    const dimension: f32 = 5.0;

    fruit: raylib.Rectangle,
    visible: bool,

    pub fn Init() Fruit {
        var timestamp: u32 = std.time.timestamp() / (std.time.ms_per_day * 365);
        raylib.setRandomSeed(timestamp);
        const x = raylib.getRandomValue(0, Global.screenWidth);

        timestamp = std.time.timestamp() / (std.time.ms_per_day);
        raylib.setRandomSeed(timestamp);
        const y = raylib.getRandomValue(0, Global.screenHeight);

        return Fruit{
            .fruit = raylib.Rectangle{ .x = x, .y = y, .width = dimension, .height = dimension },
            .visible = false,
        };
    }

    pub fn respawn(self: *Fruit) void {
        var timestamp: u32 = std.time.timestamp() / (std.time.ms_per_day * 365);
        raylib.setRandomSeed(timestamp);
        self.x = raylib.getRandomValue(0, Global.screenWidth);

        timestamp = std.time.timestamp() / (std.time.ms_per_day);
        raylib.setRandomSeed(timestamp);
        self.y = raylib.getRandomValue(0, Global.screenHeight);

        self.visible = true;
    }
};
