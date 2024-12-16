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
