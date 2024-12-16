# W

A virtual computer (fantasy computer) with its own assembly language and system interface.

The whole thing is a single program that can both assemble source files and run the resulting machine code.

In an optimize mode other than Debug or ReleaseSafe,
the program makes zero usage of the Zig standard library, uses zero error codes (a feature of the Zig language), and does not panic (i.e. no `@panic`/`std.debug.panic`, etc.).
Instead it uses pure libc (see `c.zig` for everything used) with zero abstractions and in case of an error the program simply exits after printing the error message
instead of propagating anything.

This makes the binary size incredibly small:

```
$ zig build -Doptimize=ReleaseSmall
$ wc -c zig-out/bin/W
19944 zig-out/bin/W
```

This program does link libc and uses it for all the interactions with the operating system which does offload a lot of things as libc is not statically linked.
0.01 MBs is still impressive considering that this program on its own can 1. assemble programs, 2. execute them, and 3. has a graphical interface opening a window using Wayland
in which user programs are executed.

This only runs on Unix-like operating systems (or perhaps only Linux) by talking to the Wayland server directly, without any graphics library in between.

It depends on libc and a wayland-client system library.

I'm archiving this project here as it is with TODOs and all left in the source code that I wouldn't understand now.

To assemble a source file pass the source file with the extension .W:
```
$ W COUNTER.W
```
To run a source file pass the machine code file without an extension:
```
$ W COUNTER
```
To view the manual, run:
```
$ W
```

I'm repeating it here:

```
MANUAL
======

ADDI (INTEGER):  ADD INTEGER
CLRS (INTEGER):  CLEAR SCREEN
CPTO (REGISTER): COPY REGISTER VALUE TO REGISTER
DECR (REGISTER): DECREMENT
DDEC (NONE):     DISABLE DECIMAL MODE
DRAW (INTEGER):  DRAW PIXELS
EDEC (NONE):     ENABLE DECIMAL MODE
GOTO (INTEGER):  JUMP TO ADDRESS
HALT (NONE):     HALT EXECUTION
IFEQ (INTEGER):  IF EQUAL, EXECUTE NEXT INSTRUCTION; OTHERWISE SKIP
IFNE (INTEGER):  IF NOT EQUAL, EXECUTE NEXT INSTRUCTION; OTHERWISE SKIP
IFPP (NONE):     IF POINTER PRESSED, EXECUTE NEXT INSTRUCTION; OTHERWISE SKIP
INCR (REGISTER): INCREMENT
LDPP (NONE):     LOAD POINTER POSITION INTO X AND Y
LDKK (NONE):     LOAD KEYBOARD KEY INTO W
LOAD (INTEGER):  LOAD
PRNT (NONE):     PRINT W AS CHARACTER TO (X, Y)
RSTR (REGISTER): POP FROM STACK
SAVE (REGISTER): PUSH TO STACK
SEXH (INTEGER):  SET EXCEPTION HANDLER
SCLR (INTEGER):  SET COLOR
SETW (INTEGER):  SET W
SETX (INTEGER):  SET X
SETY (INTEGER):  SET Y
TRGT (REGISTER): SET OPERATION TARGET
WAIT (INTEGER):  DO NOTHING FOR AN AMOUNT OF MILLISECONDS

NONE:     NO ARGUMENT
INTEGER:  32-BIT INTEGER ARGUMENT
REGISTER: W, X, Y, OR XY
```

To compile from source and run the moon example:
```
.../W$ zig build
.../W$ zig-out/bin/W MOON.W
.../W$ zig-out/bin/W MOON
```

![moon](moon.png)

What's special about the encoding of the instructions is that all mnemonics are 4 bytes and the encoding is the same: the same 4 bytes used for the mnemonic.
This is particularly useful for writing self-modifying code. You can look at a hexdump of an assembled program and see the instructions because they're ASCII:
```
$ zig-out/bin/W CHICKEN.W
$ hexdump -C CHICKEN
00000000  43 4c 52 53 b7 01 00 00  53 43 4c 52 a7 01 00 00  |CLRS....SCLR....|
00000010  44 52 41 57 67 01 00 00  49 4e 43 52 58 53 43 4c  |DRAWg...INCRXSCL|
00000020  52 ab 01 00 00 44 52 41  57 67 01 00 00 49 4e 43  |R....DRAWg...INC|
00000030  52 58 53 43 4c 52 ab 01  00 00 44 52 41 57 67 01  |RXSCLR....DRAWg.|
00000040  00 00 49 4e 43 52 58 53  43 4c 52 a7 01 00 00 44  |..INCRXSCLR....D|
00000050  52 41 57 67 01 00 00 53  45 54 58 00 00 00 00 49  |RAWg...SETX....I|
00000060  4e 43 52 59 53 43 4c 52  b3 01 00 00 44 52 41 57  |NCRYSCLR....DRAW|
00000070  67 01 00 00 49 4e 43 52  58 53 43 4c 52 b3 01 00  |g...INCRXSCLR...|
00000080  00 44 52 41 57 67 01 00  00 49 4e 43 52 58 53 43  |.DRAWg...INCRXSC|
00000090  4c 52 b3 01 00 00 44 52  41 57 67 01 00 00 49 4e  |LR....DRAWg...IN|
000000a0  43 52 58 53 43 4c 52 b3  01 00 00 44 52 41 57 67  |CRXSCLR....DRAWg|
000000b0  01 00 00 53 45 54 58 00  00 00 00 49 4e 43 52 59  |...SETX....INCRY|
000000c0  53 43 4c 52 ab 01 00 00  44 52 41 57 67 01 00 00  |SCLR....DRAWg...|
```
