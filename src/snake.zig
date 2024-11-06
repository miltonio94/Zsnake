const std = @import("std");
const raylib = @import("raylib");
const Global = @import("global.zig");
const runMode = @import("builtin").mode;
const Fruit = @import("fruit.zig").Fruit;

const OptimizedMode = std.builtin.OptimizeMode;
const Rectangle = raylib.Rectangle;
const Colour = raylib.Color;
const Keys = raylib.KeyboardKey;

pub const startingSize: f32 = 40.0;

pub const Head = struct {
    recIdx: usize,
    directionIdx: usize,
};

pub const Section = struct {
    recIdx: usize,
    directionIdx: usize,
    targetPoolStart: usize,
    targetPoolEnd: usize,
};

pub const Direction = enum { up, down, left, right };

const Point = struct { x: f32, y: f32 };

pub const Target = struct { position: Point, nextDirection: Direction };

const print = std.debug.print;

pub const headColour = Colour{ .r = 234, .g = 104, .b = 71, .a = 255 };
pub const bodyColour = Colour{ .r = 255, .g = 162, .b = 0, .a = 255 };
