const std = @import("std");
const testing = std.testing;

// findMedianSortedArray returns the median of a slice of integers.
// If the slice is empty, it returns 0.
// If the slice has an odd number of elements, it returns the middle element.
// If the slice has an even number of elements, it returns the average of the two middle elements.
// The slices are not modified.
// The slices must be sorted.
// The slices must not be empty.
// Solution is in 0(lg n) time.
fn findMedianSortedArray(arr1: []u64, arr2: []u64) u64 { // arr1: [2, 3, 5, 8], arr2: [10, 12, 14, 16, 18, 20]
    if (arr1.len > arr2.len) {
        return findMedianSortedArray(arr2, arr1);
    }

    // pi: partition index
    var pi1 = arr1.len / 2;
    var pi2 = arr2.len / 2;

    // change pi1 and pi2 until all elems to the left of pi1 and left of pi2
    // are less than all elems to the right of pi1 and pi2
    while (true) {

        // [.....l_1] [r_1...]
        // [...l_2] [r2.....]
        const l_1 = if (pi1 == 0) std.math.minInt(u64) else arr1[pi1 - 1];
        const r_1 = if (pi1 == arr1.len) std.math.maxInt(u64) else arr1[pi1];
        const l_2 = if (pi2 == 0) std.math.minInt(u64) else arr2[pi2 - 1];
        const r_2 = if (pi2 == arr2.len) std.math.maxInt(u64) else arr2[pi2];

        if (l_1 > r_2) {
            const steps_1 = pi1;
            const steps_2 = (arr2.len - pi2);
            const steps = std.math.min(steps_1, steps_2) / 2;
            pi1 -= steps;
            pi2 += steps;
            continue;
        }

        if (l_2 > r_1) {
            const steps_1 = pi2;
            const steps_2 = (arr1.len - pi1);
            const steps = std.math.min(steps_1, steps_2) / 2;
            pi1 += steps;
            pi2 -= steps;
            continue;
        }

        return if (arr1.len + arr2.len % 2 == 0)
            std.math.max(l_1, l_2)
        else
            std.math.min(r_1, r_2);
    }
}


test "findMedianSortArrays" {
    {
        var arr1 = [_]u64{2, 4, 6, 8, 10};
        var arr2 = [_]u64{3, 5, 7, 9, 11, 13};
        try testing.expectEqual(@as(u64, 7), findMedianSortedArray(&arr1, &arr2));
    }
    {
        var arr1 = [_]u64{2, 4, 6, 8, 10};
        var arr2 = [_]u64{3, 5, 7, 9, 11};
        try testing.expectEqual(@as(u64, 6), findMedianSortedArray(&arr1, &arr2));
        // 6.5 is the correct answer, but we're rounding down.
    }
    {
        var arr1 = [_]u64{2, 3, 4, 8, 9, 10};
        var arr2 = [_]u64{5, 6, 7};
        try testing.expectEqual(@as(u64, 6), findMedianSortedArray(&arr1, &arr2));
        // 6.5 is the correct answer, but we're rounding down.
    }
    {
        var arr1 = [_]u64{2, 3, 6, 7, 10, 11, 12};
        var arr2 = [_]u64{4, 5, 8, 9};
        try testing.expectEqual(@as(u64, 7), findMedianSortedArray(&arr1, &arr2));
        // 6.5 is the correct answer, but we're rounding down.
    }
}
