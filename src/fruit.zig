const std = @import("std");
const raylib = @import("raylib");
const global = @import("global.zig");
const Colour = raylib.Color;

pub const Fruit = struct {
    dimension: f32 = 35.75,
    fruit: raylib.Rectangle,
    visible: bool,

    pub fn Init() Fruit {
        const x: f32 = @floatFromInt(raylib.getRandomValue(0, global.screenWidth));
        const y: f32 = @floatFromInt(raylib.getRandomValue(0.0, global.screenHeight));

        var fruit = Fruit{ .visible = true, .fruit = undefined };
        fruit.fruit = raylib.Rectangle{
            .x = x,
            .y = y,
            .width = fruit.dimension,
            .height = fruit.dimension,
        };

        return fruit;
    }

    pub fn respawn(self: *Fruit) void {
        self.fruit.x = @floatFromInt(raylib.getRandomValue(0, global.screenWidth));
        self.fruit.y = @floatFromInt(raylib.getRandomValue(0, global.screenHeight));

        self.visible = true;
    }

    pub fn render(self: *Fruit) void {
        if (self.visible) {
            raylib.drawRectangleRec(self.fruit, global.pink);
        }
    }
};
