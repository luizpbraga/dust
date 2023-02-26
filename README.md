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
  * Function/enum/struct/error/trait declaration etc;


### Code Example

```Rust
let a = 666;

const Foo = struct {
  .a,
  .x = 10,
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

