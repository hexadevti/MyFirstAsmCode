PRESENTATION:   EQU 0x4000
OUTRA:          EQU 0x1000
PORT0:          EQU 0x00
PORT1:          EQU 0x01
PORT2:          EQU 0x02
PORT3:          EQU 0x03

org     0x0000

main:
    ld HL,PRESENTATION
    call show
    call clear
    jp main


clear:
    ld e,152
    ld d,0
    clines:
        ld a, d
        out (PORT1),a
        ld b,0xff
        ld c,0
        ccolumns:
            ld a, c
            out (PORT0),a
            ld a, 0x0
            out (PORT2),a
            inc c
        djnz ccolumns
        inc d
        dec e
        ld b, e
    djnz clines
    ret
 
show:
    ld e,76
    ld d,0
    lines:
        ld a, d
        out (PORT1),a
        ld b,128
        ld c,0
        columns:
            ld a, c
            out (PORT0),a
            ld a, (hl)
            out (PORT2),a
            inc c
            inc HL
        djnz columns
        inc d
        dec e
        ld b, e
    djnz lines
    ret

