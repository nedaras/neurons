const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;

pub fn Tensor(comptime T: type, Rows: comptime_int, Cols: comptime_int) type {
    return struct {
        ptr: [*]const T,

        comptime rows: comptime_int = Rows,
        comptime cols: comptime_int = Cols,

        const Self = @This();

        pub fn fromSlice(data: []const T) Self {
            assert(data.len == Rows * Cols);
            return .{ .ptr = data.ptr };
        }

        pub fn len() comptime_int {
            return Rows * Cols;
        }

    };
}

// pub fn add(a: anytype, b: anytype) void {
    //if (a.rows != b.rows) {
        // @compileError(std.fmt.comptimePrint("Cannot add tensors: {d}x{d} not compatible with {d}x{d}", .{ a.rows, a.cols, b.rows, b.cols }));
    //}

    // as we cant use simd perhaps in wasm we can use idk gpu or if not multithread
    //if (b.cols == 1) {
        //for (0..a.rows * a.cols) |i| {
            //a.ptr[i] += b.ptr[i % (b.rows * b.cols)];
        //}
    //} else {
        //if (a.cols != b.cols) {
            //@compileError(std.fmt.comptimePrint("Cannot add tensors: {d}x{d} not compatible with {d}x{d}", .{ a.rows, a.cols, b.rows, b.cols }));
        //}

        //for (0..a.rows * a.cols) |i| {
            //a.ptr[i] += b.ptr[i];
        //}
    //}
//}

//test add {
    //const Mat3 = Tensor(u8, 3, 3);
    //const Vec3 = Tensor(u8, 3, 1);
    //const Vec6 = Tensor(u8, 6, 1);

    //{
        //var ap = [_]u8{
            //1, 2, 3,
            //4, 5, 6,
            //7, 8, 9,
        //};

        //var bp = [_]u8{
            //1, 2, 3,
            //4, 5, 6,
            //7, 8, 9,
        //};

        //const a = Mat3.cast(&ap);
        //const b = Mat3.cast(&bp);

        //add(a, b);

        //try std.testing.expectEqualSlices(u8, a.ptr[0 .. a.rows * a.cols], &.{
            //2,  4,  6,
            //8,  10, 12,
            //14, 16, 18,
        //});
    //}

    //{
        //var ap = [_]u8{
            //1, 2, 3, 4, 5, 6,
        //};

        //var bp = [_]u8{
            //1, 2, 3, 4, 5, 6,
        //};

        //const a = Vec6.cast(&ap);
        //const b = Vec6.cast(&bp);

        //add(a, b);

        //try std.testing.expectEqualSlices(u8, a.ptr[0 .. a.rows * a.cols], &.{
            //2,  4,  6,
            //8,  10, 12,
        //});
    //}

    //{
        //var ap = [_]u8{
            //1, 2, 3,
            //4, 5, 6,
            //7, 8, 9,
        //};

        //var bp = [_]u8{
            //1, 2, 3,
        //};

        //const a = Mat3.cast(&ap);
        //const b = Vec3.cast(&bp);

        //add(a, b);

        //try std.testing.expectEqualSlices(u8, a.ptr[0 .. a.rows * a.cols], &.{
            //2,  4,  6,
            //5,  7,  9,
            //8, 10, 12,
        //});
    //}
//}

pub fn mul(a: anytype, b: anytype, c: []u8) void {
    if (a.cols != b.rows) {
        @compileError(std.fmt.comptimePrint("Cannot mul tensors: {d}x{d} not compatible with {d}x{d}", .{ a.rows, a.cols, b.rows, b.cols }));
    }

    // some killing cache locality for a var, so we would not need to memset output to zero
    for (0..b.cols) |i| {
        for (0..a.cols) |j| {
            var sum: std.meta.Child(@TypeOf(c)) = 0;
            for (0..a.rows) |k| {
                sum += a.ptr[k * a.rows + j] * b.ptr[i * b.rows + k];
            }
            c[i * b.rows + j] = sum;
        }
    }
}

test mul {
    const Mat3 = Tensor(u8, 3, 3);
    const Vec3 = Tensor(u8, 3, 1);

    {
        const a = Mat3.fromSlice(&.{
            1, 2, 3,
            4, 5, 6,
            7, 8, 9,
        });

        const b = Vec3.fromSlice(&.{
            1, 2, 3,
        });

        var out: [Vec3.len()]u8 = undefined;
        mul(a, b, &out);

        try std.testing.expectEqualSlices(u8, &.{ 30, 36, 42, }, &out);
    }

    {
        const a = Mat3.fromSlice(&.{
            1, 2, 3,
            4, 5, 6,
            7, 8, 9,
        });

        const b = Tensor(u8, 3, 2).fromSlice(&.{
            1, 2, 3,
            4, 5, 6,
        });

        var out: [Tensor(u8, 3, 2).len()]u8 = undefined;
        mul(a, b, &out);

        try std.testing.expectEqualSlices(u8, &.{ 
            30, 36, 42,
            66, 81, 96,
        }, &out);
    }
}
