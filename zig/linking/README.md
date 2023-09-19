# Linking
## Static linking
- `zig build-obj main.zig` -> produces `main.o`
- `zig build-obj mymath.zig` -> produces `a.o`
- `zig build-exe main.o mymath.o` -> produces `main` executable

## dyn link
 - create archive: `zig build-lib -fPIC mymath.zig -femit-h` -> `mymath.so` + `mymath.h` // .h is extra(remove -femit-h if need)
 - create shared: `zig cc -shared -o libmymath.so libmymath.a.o` -> `libmymath.so`
 - use `zig ar` to get `.o` from `.a` if needed
 - see `main2.zig`
