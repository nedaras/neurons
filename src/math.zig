const std = @import("std");
const assert = std.debug.assert;

pub fn Tensor(comptime T: type, Rows: comptime_int, Cols: comptime_int) type {
    return struct {
        ptr: [*]T,

        comptime rows: comptime_int = Rows,
        comptime cols: comptime_int = Cols,

        const Self = @This();

        pub fn cast(data: []T) Self {
            assert(data.len == Rows * Cols);
            return .{ .ptr = data.ptr };
        }
    };
}

pub fn add(a: anytype, b: anytype) void {
    const Child = std.meta.Child(@TypeOf(a.ptr));

    if (a.rows != b.rows or a.cols != b.cols) {
        @compileError(std.fmt.comptimePrint("Cannot add tensors: {d}x{d} not compatible with {d}x{d}", .{a.rows, a.cols, b.rows, b.cols}));
    }

    var idx: usize = 0;
    const len = a.rows * a.cols;
    if (std.simd.suggestVectorLength(Child)) |block_len| {
        const Block = @Vector(block_len, Child);
        while (len > idx + block_len * 2) {
            inline for (0..2) |_| {
                const block_a: Block = a.ptr[idx..][0..block_len].*;
                const block_b: Block = b.ptr[idx..][0..block_len].*;

                a.ptr[idx..][0..block_len].* = block_a + block_b;
                idx += block_len;
            }
        }


        inline for (0..2) |j| {
            const block_x_len = block_len / (1 << j);
            comptime if (block_x_len < 4) break;

            const BlockX = @Vector(block_x_len, Child);
            if (idx + block_x_len < len) {
                const block_a: BlockX = a.ptr[idx..][0..block_x_len].*;
                const block_b: BlockX = b.ptr[idx..][0..block_x_len].*;

                a.ptr[idx..][0..block_x_len].* = block_a + block_b;
                idx += block_x_len;
            }
        }
    }

    for (idx..len) |i| {
        a.ptr[i] += b.ptr[i];
    }
}

test {
    const Mat3 = Tensor(f32, 3, 3);
    //const Vec3 = Tensor(u8, 3, 1);

    var ap = [_]f32{
        1, 2, 3,
        4, 5, 6,
        7, 8, 9,
    };

    var bp = [_]f32{
        1, 2, 3,
        4, 5, 6,
        7, 8, 9,
    };

    const a = Mat3.cast(&ap);
    const b = Mat3.cast(&bp);

    add(a, b);

    std.debug.print("{d}\n", .{a.ptr[0..a.rows * a.cols]});
}
