CLRS GRAY

SCLR BLACK
DRAW PIXELS

INCR X
SCLR WHITE
DRAW PIXELS

INCR X
SCLR WHITE
DRAW PIXELS

INCR X
SCLR BLACK
DRAW PIXELS

SETX 0
INCR Y

SCLR YELLOW
DRAW PIXELS

INCR X
SCLR YELLOW
DRAW PIXELS

INCR X
SCLR YELLOW
DRAW PIXELS

INCR X
SCLR YELLOW
DRAW PIXELS

SETX 0
INCR Y

SCLR WHITE
DRAW PIXELS

INCR X
SCLR RED
DRAW PIXELS

INCR X
SCLR RED
DRAW PIXELS

INCR X
SCLR WHITE
DRAW PIXELS

LOOP:
    SETX 5
    SETY 5
    SCLR GRAY
    DRAW PIXELS
    LDKK
    SCLR WHITE
    PRNT
    IFPP
    GOTO DO
    GOTO DONT
DO:
    LDPP
    DRAW PIXELS
DONT:
    GOTO LOOP

PIXELS:
    DATA %1111111111111111
    DATA %1111111111111111
    DATA %1111111111111111
    DATA %1111111111111111
    DATA %1111111111111111
    DATA %1111111111111111
    DATA %1111111111111111
    DATA %1111111111111111
    DATA %1111111111111111
    DATA %1111111111111111
    DATA %1111111111111111
    DATA %1111111111111111
    DATA %1111111111111111
    DATA %1111111111111111
    DATA %1111111111111111
    DATA %1111111111111111

BLACK:
    DATA $000000

WHITE:
    DATA $FFFFFF

RED:
    DATA $FF0000

YELLOW:
    DATA $FFFF00

GRAY:
    DATA $444444
