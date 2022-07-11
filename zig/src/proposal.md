# Tagged union can take multiple Enums

```zig
// Enum
const CarBrandA = enum {
    Model_1,
    Model_2,
};

const CarBrandB = enum {
    Model_3,
    Model_4,
};

// all variants of DataType MUST be inside
const CarModel = union(CarBrandA, CarBrandB) {
    Model_1,
    Model_2,
    Model_3,
    Model_4,
};
```
