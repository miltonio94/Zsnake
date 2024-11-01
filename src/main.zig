const std = @import("std");
const World = @import("World.zig").World;

pub fn main() !void {
    var world = World.Init();
    world.run();
}
