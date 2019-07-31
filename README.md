# Pahole-fmt

Reformats output of [Pahole
utility](https://git.kernel.org/pub/scm/devel/pahole/pahole.git). Prints fields
of structs and unions based on compiled debugging info, including type
information where there is room. Empty space (padding) is denoted using X's.

## Examples

Source code:

```
struct foo {
    char   a;
    bool   b;
    int    c;
    double d;
};

union bar {
    char   a;
    bool   b;
    int    c;
    double d;
};
```

Formatted output:

```
struct foo:

0               4               8               12              16
|               |               |               |               |
-----------------------------------------------------------------
| a | b |#######|    c : int    |          d : double           |
-----------------------------------------------------------------


union bar:

0               4               8
|               |               |
-----
| a |
-----
| b |
-----------------
|    c : int    |
---------------------------------
|          d : double           |
---------------------------------
```

Source code:

```
#define NUMREGS 15
typedef int64_t y86_reg_t;
typedef int32_t y86_stat_t;

typedef struct y86 {

    y86_reg_t reg[NUMREGS];     // 64-bit general-purpose registers

    bool zf;                    // zero flag
    bool sf;                    // negative flag
    bool of;                    // overflow flag

    y86_reg_t pc;               // program counter
    y86_stat_t stat;            // program status

} y86_t;
```

Formatted output:

```
struct y86:

0               4               8               12              16
|               |               |               |               |
-----------------------------------------------------------------
|                      reg[15] : y86_reg_t                      |
-----------------------------------------------------------------
|                                                               |
-----------------------------------------------------------------
|                                                               |
-----------------------------------------------------------------
|                                                               |
-----------------------------------------------------------------
|                                                               |
-----------------------------------------------------------------
|                                                               |
-----------------------------------------------------------------
|                                                               |
-----------------------------------------------------------------
|                               |zf |sf |of |###################|
-----------------------------------------------------------------
|        pc : y86_reg_t         |     stat      |
-------------------------------------------------
```

Source code:

```
typedef uint64_t address_t;

typedef struct y86_inst {

    uint8_t opcode;             // icode:ifun/fn

    // enumerations
    y86_inst_class_t icode;     // icode
    y86_cmov_t cmov;            // ifun/fn  (cmovXX only)
    y86_op_t op;                // ifun/fn  (OPq only)
    y86_jump_t jump;            // ifun/fn  (jXX only)
    y86_iotrap_t id;            // trap id  (iotrap only)

    // 32-bit unsigned
    y86_regnum_t ra;            // rA
    y86_regnum_t rb;            // rB

    address_t dest;             // Dest     (jXX and call only)
    int64_t v;                  // V        (irmovq only)
    int64_t d;                  // D        (rmmovq and mrmovq only)

    uint8_t size;               // hard-coded for each instruction

} y86_inst_t;
```

Formatted output:

```
struct y86_inst:

0               4               8               12              16
|               |               |               |               |
-----------------------------------------------------------------
|opc|###########|     icode     |     cmov      | op : y86_op_t |
-----------------------------------------------------------------
|     jump      |      id       |      ra       |      rb       |
-----------------------------------------------------------------
|       dest : address_t        |          v : int64_t          |
-----------------------------------------------------------------
|          d : int64_t          |siz|
-------------------------------------
```

## Installing Pahole-fmt

This utility depends on the availability of the [`pahole`
utility](https://git.kernel.org/pub/scm/devel/pahole/pahole.git), so follow the
directions in that repository for downloading, compiling, and installing
Pahole.

After Pahole is available, simply clone this repository and make sure the
`pahole-fmt.rb` script is in your executable path.

## Using Pahole-fmt

Just run `pahole` on your binary executable and redirect the output through
this utility. For example, if both of them are in your path, you should be able
to run a command similar to this:

```
pahole <your-executable> | pahole-fmt.rb
```

Your executable must be compiled with debugging information (`-g` in most
compilers), and your structs and unions must be named. C++ classes will be
detected as structs (e.g., data layout only).

## Getting Involved

To get involved, submit an issue or email the author directly.

## Contributing

To contribute, submit a pull request or email the author directly.

## Release

This software is released under the MIT license.
