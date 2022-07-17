CPU Z80
FNAME   "output2.bin"
PRESENTATION: 	EQU $0F80

INCBYTE:        EQU $F000
PORT0:          EQU 0x0
PORT1:          EQU 0x1

PORT2:          EQU 0x2

PORT3:          EQU 0x3

org     0000h
ld a,0
out (PORT0),a
push HL
    ld HL,PRESENTATION  
    ld b,120
    ld d,0
    lines:
        push BC 
                ld b,80
                ld c,0
                columns:
                    ld a,d
                    out (PORT1),a
                    ld a,c 	 
                    out (PORT1),a
                    inc c
                    ld a,(HL)
                    out (PORT2),a
                    inc HL
                djnz columns
        pop BC
        inc d
    djnz lines	
pop HL
ld a,0
out (PORT3),a
halt
