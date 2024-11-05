const std = @import("std");
const World = @import("World.zig").World;

pub fn main() !void {
    var world = try World.init();
    defer world.deinit();
    world.run();
}
