# BE SAP-1 8-bit CPU Emulator

Emulates the Breadboard "Simple As Possible" 8-bit CPU as outlined in Ben Eater's videos:
https://youtube.com/playlist?list=PLowKtXNTBypGqImE405J2565dvjafglHU

## Installation

Check out the releases for the executable

#### macOS

1. Install crystal: `brew install crystal`
2. build the program: `shards build --release`

## Usage

Build a program:

```zsh
$ becpu build examples/multiply.asm -o a.out
```

Run a program:

```zsh
$ becpu run examples/multiply.eat
```

Run and build a program:

```zsh
$ becpu run examples/multiply.asm -a
```

```
Usage: bemu [arguments]
    -v, --verbose                    Run verbosely
    build                            assemble a file
    dasm                             dis-assemble a binary
    run                              run a program
    -h, --help                       Show this help
```

## Contributors

- [Alex Clink](https://github.com/sleepinginsomniac) - creator and maintainer
