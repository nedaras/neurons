const std = @import("std");
const tensors = @import("tensors.zig");
const assert = std.debug.assert;

const allocator = std.testing.allocator;

var network: []f32 = undefined;

const layers = [_]type{
    tensors.Tensor(f32, 16, 28 * 28),
    tensors.Tensor(f32, 16, 16),
    tensors.Tensor(f32, 10, 16),
};

pub export fn init() void {
    //const network_len = Weights1.len() + Weights2.len() + Weights3.len() + Biases1.len() + Biases2.len() + Biases3.len() + Output.len();
    //const slice = allocator.alloc(f32, network_len) catch unreachable;

    //for(slice) |*i| {
        //i.* = 1.0;
    //}

    comptime var network_len = 0;
    inline for (layers) |layer| {
        network_len += layer.len() + layer.Rows;
    }

    network = allocator.alloc(f32, network_len) catch unreachable;
    for (network) |*i| {
        i.* = std.crypto.random.float(f32) * 2.0 - 1.0;
    }
}

pub export fn deinit() void {
    allocator.free(network);
}

pub export fn guess(ptr: [*]const f32, len: usize) void {
    assert(len == 28 * 28);

    var input: [28 * 28]f32 = undefined;
    var out: [16]f32 = undefined;

    @memcpy(&input, ptr[0..len]);

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
            input[i] = 1 / (1 + std.math.pow(f32, std.math.e, -input[i]));
        }
    }

    std.debug.print("{d}\n", .{input[0..10]});
}

test {
    _ = tensors;

    init();
    defer deinit();

    const input = allocator.alloc(f32, 28 * 28) catch unreachable;
    defer allocator.free(input);

    @memset(input, 1.0);

    guess(input.ptr, input.len);
}
