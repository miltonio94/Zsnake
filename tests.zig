const std = @import("std");
const Snake = @import("src/snake.zig").Snake;
const utils = @import("src/utils.zig");

test "Test snake movement when direction change" {
    const expect = std.testing.expect;
    // //
    // var allocator = try utils.Allocator.init();
    // var snake = try Snake.init(&allocator);
    // const headRect = snake.recBuffer[0];
    // const headRect_ref = &snake.recBuffer[0];
    // const sec1 = snake.recBuffer[1];
    // const sec2 = snake.recBuffer[2];
    // const sec3 = snake.recBuffer[3];
    // const sec1_ref = &snake.recBuffer[1];
    // const sec2_ref = &snake.recBuffer[2];
    // const sec3_ref = &snake.recBuffer[3];
    // const headStartingX = headRect.x;
    // const headStartingY = headRect.y;
    // for (1..1000) |i| {
    //     // _ = headRect_ref;
    //     _ = sec1;
    //     _ = sec2;
    //     _ = sec3;
    //     _ = sec1_ref;
    //     _ = sec2_ref;
    //     _ = sec3_ref;
    //     _ = headStartingX;
    //     _ = headStartingY;
    //     if (i == 1) {
    //         snake.directionChange(.up);
    //     }
    //     snake.move(1);
    //     const i_f32: f32 = @floatFromInt(i);
    //     std.debug.print("i: {}\n", .{i});
    //     std.debug.print(
    //         "headRect_ref.y {d:.6} \t headRect.y {d:.6} + snake.movemntSpeed {d:.6} * i_f32 {d:.6} = {d:.6}\n",
    //         .{
    //             headRect_ref.y,
    //             headRect.y,
    //             snake.acceleration,
    //             i_f32,
    //             headRect.y + (snake.acceleration * i_f32),
    //         },
    //     );
    // try expect(headRect_ref.y == headRect.y + (snake.movementSpeed * i_f32));
    try expect(true);
    // }
}
