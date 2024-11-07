const std = @import("std");

const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const pager = std.heap.page_allocator;
const Error = std.mem.Error;

pub const screenWidth: f32 = 1080;
pub const screenHeight: f32 = 720;

pub const Allocator = struct {
    fba: FixedBufferAllocator = undefined,
    allocator: std.mem.Allocator = undefined,
    memBuffer: []u8,

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
