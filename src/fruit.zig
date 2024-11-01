const std = @import("std");
const raylib = @import("raylib");
const Global = @import("global.zig");
const Colour = raylib.Color;

pub const Fruit = struct {
    const colour = Colour{ .r = 217, .g = 67, .b = 168, .a = 255 };

    dimension: f32 = 7.75,
    fruit: raylib.Rectangle,
    visible: bool,

    pub fn Init() Fruit {
        const x: f32 = @floatFromInt(raylib.getRandomValue(0, Global.screenWidth));
        const y: f32 = @floatFromInt(raylib.getRandomValue(0.0, Global.screenHeight));

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
        self.fruit.x = @floatFromInt(raylib.getRandomValue(0, Global.screenWidth));
        self.fruit.y = @floatFromInt(raylib.getRandomValue(0, Global.screenHeight));

        self.visible = true;
    }

    pub fn draw(self: *Fruit) void {
        if (self.visible) {
            raylib.drawRectangleRec(self.fruit, colour);
        }
    }
};
