const std = @import("std");
const tensors = @import("tensors.zig");
const assert = std.debug.assert;

// const allocator = std.heap.wasm_allocator;
const allocator = std.testing.allocator;

const Mat = tensors.Tensor(f32, 16, 28 * 28);
const Vec = tensors.Tensor(f32, 28 * 28, 1);

var mat: Mat = undefined;

pub export fn init() void {
    const slice = allocator.alloc(f32, Mat.len()) catch unreachable;

    for (0..Mat.len()) |i| {
        slice[i] = std.crypto.random.float(f32);
    }

    mat = Mat.fromSlice(slice);
}

pub export fn deinit() void {
    allocator.free(mat.ptr[0..Mat.len()]);
}

pub export fn guess(ptr: [*]const f32, len: usize) void {
    const input = ptr[0..len];
    const vec = Vec.fromSlice(input);

    const out = allocator.alloc(f32, 16) catch unreachable;
    defer allocator.free(out);

    const Vec16 = tensors.Tensor(f32, 16, 1);

    tensors.mul(mat, vec, out);
    tensors.add(Vec16.fromSlice(out), Vec16.fromSlice(&.{
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
    }), out);

    std.debug.print("len: {d}\n", .{out});
}

pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test {
    _ = tensors;

    init();
    defer deinit();

    const input = allocator.alloc(f32, Vec.len()) catch unreachable;
    defer allocator.free(input);

    @memset(input, 1);

    guess(input.ptr, input.len);
}
