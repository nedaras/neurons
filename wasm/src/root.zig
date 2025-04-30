const std = @import("std");
const tensors = @import("tensors.zig");
const assert = std.debug.assert;

const allocator = std.heap.wasm_allocator;

var network: []f32 = undefined;

const layers = [_]type{
    tensors.Tensor(f32, 16, 28 * 28),
    tensors.Tensor(f32, 16, 16),
    tensors.Tensor(f32, 10, 16),
};

pub export fn init() void {
    comptime var network_len = 0;
    inline for (layers) |layer| {
        network_len += layer.len() + layer.Rows;
    }

    network = allocator.alloc(f32, network_len) catch unreachable;

    var pcg = std.Random.Pcg.init(0);
    const rand = pcg.random();

    for (network) |*i| {
        i.* = rand.float(f32) * 2.0 - 1.0;
    }
}

pub export fn deinit() void {
    allocator.free(network);
}

pub export fn guess(src: [*]const f32, src_len: usize, dst: [*]f32, dst_len: usize) void {
    assert(src_len == 28 * 28);
    assert(dst_len == 10);

    var input: [28 * 28]f32 = undefined;
    var out: [16]f32 = undefined;

    @memcpy(&input, src[0..src_len]);

    comptime var idx = 0;
    inline for (layers) |layer| {
        const Vec1 = tensors.Tensor(f32, layer.Rows, 1);
        const Vec2 = tensors.Tensor(f32, layer.Cols, 1);

        const weights = layer.fromSlice(network[idx .. idx + layer.len()]);
        const biases = Vec1.fromSlice(network[idx + layer.len() .. idx + layer.len() + Vec1.len()]);

        defer idx += layer.len() + Vec1.len();

        tensors.mul(weights, Vec2.fromSlice(input[0..Vec2.len()]), out[0..Vec1.len()]);
        tensors.add(Vec1.fromSlice(out[0..Vec1.len()]), biases, input[0..Vec1.len()]);

        // sigmoid
        for (0..Vec1.len()) |i| {
            input[i] = 1.0 / (1.0 + @exp(-input[i]));
        }
    }

    @memcpy(dst[0..10], input[0..10]);
}

test {
    _ = tensors;
}
