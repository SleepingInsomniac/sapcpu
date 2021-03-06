# SAP 8-bit CPU Emulator

Emulates a version of the ["Simple As Possible"](https://en.wikipedia.org/wiki/Simple-As-Possible_computer) 8-bit CPU

## Installation

#### macOS

1. Install crystal: `brew install crystal`
2. build the program: `shards build --release`

The build will be placed in `bin`

## CLI Usage

Build a program:

```zsh
$ sapcpu build examples/multiply.asm -o a.out
```

Run a program:

```zsh
$ sapcpu run examples/multiply.eat
```

Run and build a program:

```zsh
$ sapcpu run examples/multiply.asm -a
```

```
Usage: sapcpu [arguments]
    -v, --verbose                    Run verbosely
    build                            assemble a file
    dasm                             dis-assemble a binary
    run                              run a program
    -h, --help                       Show this help

Usage: sapcpu build [arguments]
    -v, --verbose                    Run verbosely
    -h, --help                       Show this help
    -o NAME                          Output file name

Usage: sapcpu dasm [arguments]
    -v, --verbose                    Run verbosely
    -h, --help                       Show this help

Usage: sapcpu run [arguments]
    -v, --verbose                    Run verbosely
    -h, --help                       Show this help
    -a, --asm                        Assemble before running
    -g, --gui                        Run with a gui
    -d DELAY, --delay DELAY          Add a delay to each clock pulse (s)
```

## Instructions

```
  NOP -  No-op
  LDA -  Load A
  ADD -  Add A with memory
  SUB -  Subtract A with memory
  STA -  Store A to memory
  LDI -  Load Immediate to A
  JMP -  Jump to Immediate
  JC  -  Jump on Carry
  JZ  -  Jump on Zero
  ADI -  Add immediate
  OUT -  Output                    (Prints to STDOUT)
  HLT -  Halt execution            (Exits the emulator)
```

## CPU Layout

```
                    Bus
 Memory Address     ●●●●●●●●           Prog Counter  RAM
     ●●●● ⫦-------⫣ ⎪⎪⎪⎪⎪⎪⎪⎪ ⫦-------⫣ ●●●●●●●●      00: 00000000
 $00                ⎪⎪⎪⎪⎪⎪⎪⎪           $00           01: 00000000
 Memory Contents    ⎪⎪⎪⎪⎪⎪⎪⎪           A Register    02: 00000000
 ●●●●●●●● ⫦-------⫣ ⎪⎪⎪⎪⎪⎪⎪⎪ ⫦-------⫣ ●●●●●●●●      03: 00000000
 $00                ⎪⎪⎪⎪⎪⎪⎪⎪           000           04: 00000000
 Instruction        ⎪⎪⎪⎪⎪⎪⎪⎪           Sum Register  05: 00000000
 ●●●●●●●● ⫦-------⫣ ⎪⎪⎪⎪⎪⎪⎪⎪ ⫦-------⫣ ●●●●●●●●      06: 00000000
 HLT                ⎪⎪⎪⎪⎪⎪⎪⎪           000           07: 00000000
 Flags  MC Step     ⎪⎪⎪⎪⎪⎪⎪⎪           B Register    08: 00000000
 ●●     ●●●         ⎪⎪⎪⎪⎪⎪⎪⎪ ⫦-------⫣ ●●●●●●●●
 ZC                 ⎪⎪⎪⎪⎪⎪⎪⎪           000
 Control Word       ⎪⎪⎪⎪⎪⎪⎪⎪           Output
 ●●●●●●●●●●●●●●●●●● ⎪⎪⎪⎪⎪⎪⎪⎪ ⫦-------⫣ ●●●●●●●●
 JJFJCCOBSEAAIIRRMH                    000
 ZCI OEIIUOOIIOOIIL
                  T
```

## Contributors

- [Alex Clink](https://github.com/sleepinginsomniac) - creator and maintainer
