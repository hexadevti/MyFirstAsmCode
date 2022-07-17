;original code by Cyberdemon^i8
;decompiled(used IDA Pro) and adapted for SjASMPlus by Aprisobal 
;27.07.2006
		device noslot64k
		
		PRESENTATION: 	EQU $0F80
		INCBYTE:        EQU $F000
		PORT0:          EQU 0x0
		PORT1:          EQU 0x1
		PORT2:          EQU 0x2

		org     0000h

		push HL
			ld HL,PRESENTATION  
			ld b,120
			ld d,0
			lines:
				ld a,d 

				push BC 
						ld b,160
						ld c,0
						columns:
							ld a,(HL)
							out (0x0),a
							inc HL
							ld a,c 	 
							out (0x1),a
							ld a,d
							out (0x2),a
							inc c
							XOR a
						djnz columns
				pop BC
				inc d
			djnz lines	
		pop HL
		halt

		



		;savesna "3color.sna",start

		;savebin "3color.bin",$8200,image.end-$8200
