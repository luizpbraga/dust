# Dust
A toy-buggy-scrip Language written in zig

### How to play

To start the repl, just run it
```bash
  cd dust
  zig build-exe main.zig
  ./main
  ## or zig run main.zig
```

To execute using a file
```bash
  ./main run file.dst
```

### Goals
1. Learn;
2. Be fast as fuck;

### Journey
- DOING:
  * Variable declaration;
  * Struct declaration;

- TODO:
  * Strings, Floats
  * Function/enum/struct/error/trait declaration;
  * if/else/while/for
  * Build System


### Code Example

At this moment, we have null, bool, number and struct kinds;

```Rust
let a = 666;

const Foo = struct {
  .a,
  .x = 10 * 100 - 10 / 2,
  .b = 100,
  .c = struct{
    .d = null,
    .e = true
  }
};

let z1;
let z2;
let z3 = 99;

z1 = z2 = z3
```

