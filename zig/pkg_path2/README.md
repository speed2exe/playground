# Import path outside package path
- Example of depending a file outside package path
- set the package path manually like so below
  - `zig run cmd/main.zig --main-pkg-path .`
  - use `--main-mod-path .` for zig version 0.12.0-dev.891+2254882eb onwards?
