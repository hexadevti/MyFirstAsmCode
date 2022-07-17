; Programme n°65 v0.3
; Assembleur Z80
; pour la carte de Video display 160*120*16c  : PAC-MAN
; Le 10/02/2022

CPU Z80         					; switch to Z80 mode
FNAME "output3.bin"     			; output file name

; ###############################################################
; #										 			 			#
; # GLOBAL MEMORY ORGANIZATION (64Ko)				 			#
; # 												 			#
; # |--------|-------------|-------------------|-------------|	#
; # | EEPROM |  VIDEO RAM  |  	 FREE RAM      | STACK =1023 | 	#
; # |--------|-------------|-------------------|-------------|	#
; #										 		 	 			#
; # $0000    $8000	    $A580	   			  $FC00  	  $FFFF #
; #													 			#
; ###############################################################
 

; ###############################################################
; #								  								#
; #  READY PIXEL ADR1 ADR0 			D7 D6 D5 D4 D3 D2 D1 D0 	#
; #   3		 2	  1    0       		 7  6  5  4  3  2  1  0		#
; # 	    LCD	PORT 0						LCD	PORT 1 			#
; #																#
; ###############################################################


; ######## VARIABLE DEFINITION ########

PORT0:			EQU 0x0		; VIDEO CARD INSTRUCTION PORT
PORT1:			EQU 0x1		; VIDEO CARD DATA PORT
PORT2:			EQU 0x2
PORT3:			EQU 0x3
PORT4:			EQU 0x4
PORT7:			EQU 0x7		; BREADBOARD JOYPAD

STACKTOP: 		EQU 0xffff 



;######## VIDEO RAM ADDRESS - start at $8000 - need 9600 byte ########
BUFFER_VIDEO: 	EQU $8000	; Address use to refresh video on the LCD screen : RAM $8000 -> $A580 : 9600 byte reserved (screen 160x120 pixel 4 bit color)



 
;######## FREE RAM ADDRESS - start at $A580 - MAX $FC00 ########
BUFFER_COLOR:	EQU $A581	   
BUFFER_X: 		EQU $A582
BUFFER_Y:		EQU $A583
ADDR0:			EQU $A584
ADDR1:			EQU $A585
COLOR:			EQU $A586
DUALPIXEL:		EQU $A590 
PIXEL:			EQU $A60F

PAC_X:			EQU $A610
PAC_Y:			EQU $A611
PAC_TX:			EQU $A612
PAC_TY:			EQU $A613
SPRITE_X:		EQU $A614
SPRITE_Y:		EQU $A615
ORIGINE_X:		EQU $A616
ORIGINE_Y:		EQU $A617
SPRITE_H:		EQU $A618
SPRITE_W:		EQU $A619
PAC_DIR:		EQU $A61A
CHANGE:			EQU $A61B
SCORE:			EQU $A61C ; -> $A61D : 16 bit value
SCORE_DIS:		EQU $A61E ; -> $A61F : 16 bit value
DIGIT:			EQU $A620
LIFE:			EQU $A621
PGUM1:			EQU $A622
PGUM2:			EQU $A623
PGUM3:			EQU $A624
PGUM4:			EQU $A625
IMMORTAL:		EQU $A626 ; -> $A627 : 16 bit value
X_DIR:			EQU $A628
Y_DIR:			EQU $A629
GHOST_X:		EQU $A62A
GHOST_Y:		EQU $A62B
GHOST_RX:		EQU $A62C
GHOST_RY:		EQU $A62D
GHOST_SPEED_R:	EQU $A62E
GHOST_BX:		EQU $A62F
GHOST_BY:		EQU $A630
GHOST_SPEED_B:	EQU $A631
GHOST_YX:		EQU $A632
GHOST_YY:		EQU $A633
GHOST_SPEED_Y:	EQU $A634
GHOST_PX:		EQU $A635
GHOST_PY:		EQU $A636
GHOST_SPEED_P:	EQU $A637
NB_GUM:			EQU $A638 ; -> $A639 : 16 bit value
AREA_ORIGINE:   EQU $0C26
PRESENTATION: 	EQU $0F80
MAP_PACMAN:     EQU $3500
VICTORY:        EQU $5A80

AREA:			EQU $A700 ; -> $AA5A : 858 byte reserved for the MAP


; ###################
; # FUNCTION LIST : #
; ###################

; delai_1s
; delai_250ms
; delai_40ms
; delai_10ms
; delai_100us
; delai_2us

; update_dualpixel_VRAM     ; mise à jour d'un double pixel (2X4bits) à l'adresse [@ADDR1 , @ADDR0] (15bits adresse) et de couleur COLOR (1byte)
; update_VRAM				; COPY all 9600 byte from BUFFER_VIDEO into the VRAM (VIDEO CARD)
; fill_buff					; SET (160*120 * 4bit = 9600 byte) from address BUFFER_VIDEO with value BUFFER_COLOR 	: (BUFFER_COLOR)
; cls_screen				; SET BUFFER_VIDEO and COPY IT TO VRAM 	 : (BUFFER_COLOR)
; cls_VRAM					; cls all VRAM to clean out of range pixel
; load_image				; LOAD 160*120 * 4bit (9600 byte) from address in (HL) into BUFFER_VIDEO
; G_putpixel_dual			; PUT a dual pixel 8bit at the corresponding address into the BUFFER_VIDEO				:  (BUFFER_X [0-79], BUFFER_Y[0-119], DUALPIXEL[0-15]) 


; M_ADD						; 16 bit Signed Addition 
; M_SUB						; 16 bit Signed Substraction 
; M_MUL						; 16 bit Signed Multiplication 
; M_MUL_16					; 16 bit unsigned Multiplication 
; M_DIV						; 16 bit unsigned Division
; M_DIV_8bit				; 8/8 unsigned Division 


; U_put_sprite				; copy sprite from image in HL (ORIGINE_X,ORIGINE_Y) To Buffer video (SPRITE_X, SPRITE_Y) , with  width/height (SPRITE_W,SPRITE_H)  in dualpixel

 
 
 
; We start in ROM address @ $0000 :

	ORG 0000h
	;FORG 0000h

  

; #######################################
; ############ USER PROGRAM #############
; #######################################

main:
 
 
 
	   
		; COLOR :
		; 0 = NOIR 			-> $00
		; 1 = ROUGE 		-> $11
		; 2 = VERT FONCE	-> $22
		; 3 = BEIGE			-> $33
		; 4 = BLEU FONCE 	-> $44
		; 5 = ROSE FONCE 	-> $55
		; 6 = BLEU			-> $66
		; 7 = GRIS CLAIRE	-> $77
		; 8 = GRIS FONCE	-> $88
		; 9 = ORANGE		-> $99
		; A = VERT 			-> $AA
		; B = JAUNE			-> $BB
		; C = BLEU VERT		-> $CC
		; D	= ROSE 			-> $DD
		; E = BLEU CIEL		-> $EE
		; F = BLANC			-> $FF
		
	   

; black screen :

	; XOR a
	; ld (BUFFER_COLOR),a	  
	; call cls_VRAM	 				; Remove all outside screen pixel


	; ld a,$44						; Blue screen
	; ld (BUFFER_COLOR),a
	; call cls_screen
 
	
; synchro with youtube video start
	;call delai_1s  
	;call delai_1s  
	;call delai_1s    
	;call delai_1s  
 
 
 
; #######################
; # 	 START IMAGE	#
; #######################
 
	; ld HL,PRESENTATION
	; call load_image  
 	;call update_VRAM

; delais 10s :
	;call delai_1s 
	;call delai_1s  
	;call delai_1s  
	;call delai_1s  
	;call delai_1s   
	;call delai_1s 
	;call delai_1s  
	;call delai_1s  
	;call delai_1s  
	;call delai_1s	
 
  
 
; #######################
; #  	  PAC-MAN		#
; #######################

; INITIALISATION VARIABLES

	call U_copy_area

; READY: (VALIDE)
; SCORE: (VALUE)
	LD HL,0
	ld (SCORE),HL
; VIE :  (NB)
	ld a,3
	ld (LIFE),a	
; POWERGUM1-2-3-4:
	ld a,1
	ld (PGUM1),a
	ld (PGUM2),a
	ld (PGUM3),a
	ld (PGUM4),a	
;	NB GUM CATCHED
	ld HL,0
	ld (NB_GUM),HL
; IMMORTAL PACMAN :
	XOR a
	ld (IMMORTAL),a
; RED GHOST: (X,Y,SPEED)
	ld a,15
	ld (GHOST_RX),a
	ld a,10
	ld (GHOST_RY),a
	ld a,30											; NB loop before release the RED Ghost
	ld (GHOST_SPEED_R),a
; BLUE GHOST: (X,Y,SPEED)
	ld a,18
	ld (GHOST_BX),a
	ld a,10
	ld (GHOST_BY),a
	ld a,50											; NB loop before release the BLUE Ghost
	ld (GHOST_SPEED_B),a
; YELLOW GHOST: (X,Y,SPEED)
	ld a,21
	ld (GHOST_YX),a
	ld a,10
	ld (GHOST_YY),a
	ld a,70											; NB loop before release the BLUE Ghost
	ld (GHOST_SPEED_Y),a
; PINK GHOST: (X,Y,)
	ld a,24
	ld (GHOST_PX),a
	ld a,10
	ld (GHOST_PY),a
	ld a,90											; NB loop before release the BLUE Ghost
	ld (GHOST_SPEED_P),a
; PACMAN: (PAC_X,PAC_Y,DIRECTION)
	ld a,19
	ld (PAC_X),a
	ld a,16
	ld (PAC_Y),a	
	ld a,15 									;(RIGHT)
	ld (PAC_DIR),a	




	; AFFICHAGE DEMARRAGE 3s	
		ld HL,MAP_PACMAN
		call U_load_image_7_112	
	
	; AFFICHAGE READY!
		call U_Load_Ready 
	; AFFICHAGE des GUM
		call U_display_gum
	; AFFICHAGE POWER GUM A RAMASSER  dans VIDEORAM
		call U_display_PGUM

	; AFFICHAGE PACMAN  dans VIDEORAM		
		call U_display_PacMan

	; AFFICHAGE GHOST  dans VIDEORAM :
		; RED		
		call U_display_ghost_R
		; BLUE		
		call U_display_ghost_B
		; YELLOW		
		call U_display_ghost_Y		
		; PINK		
		call U_display_ghost_P			

	;call update_VRAM
	
	; call delai_1s  
	; call delai_1s  
	; call delai_1s		
	
	
	
	
	
loop_game:

 
	
	; AFFICHAGE DU PLAN dans VIDEORAM		
		; ld HL,MAP_PACMAN
		; call U_load_image_7_112	

	; AFFICHAGE SCORE : XXXX  dans VIDEORAM
		call U_display_score
		
	; AFFICHAGE des VIES dans VIDEORAM
		call U_display_life
		
	; AFFICHAGE IMMORTAL
		call U_display_immortal 
		
	; AFFICHAGE des GUM
		call U_display_gum

	; AFFICHAGE POWER GUM A RAMASSER  dans VIDEORAM
		call U_display_PGUM

	; AFFICHAGE PACMAN  dans VIDEORAM		
		call U_display_PacMan

	; AFFICHAGE GHOST  dans VIDEORAM :
		; RED		
		call U_display_ghost_R
		; BLUE		
		call U_display_ghost_B
		; YELLOW		
		call U_display_ghost_Y		
		; PINK		
		call U_display_ghost_P		
 	
	; AFFICHAGE SUR ECRAN LCD
		call update_VRAM
		

; TEST COLLISION RED GHOST :	
		call U_collision_RED		

; TEST COLLISION BLUE GHOST :	
		call U_collision_BLUE	

; TEST COLLISION BLUE GHOST :	
		call U_collision_YELLOW

; TEST COLLISION BLUE GHOST :	
		call U_collision_PINK
		
		
	; DEPLACEMENT RED GHOST :
		; Free the Ghost when GHOST_SPEED_R = 5
		ld a,(GHOST_SPEED_R)		
		CP 5												; If A == N, then Z flag is set.
		JP NZ,suite_gsa_1
		; move Ghost oursite the box
			ld a,19
			ld (GHOST_RX),a
			ld a,8
			ld (GHOST_RY),a	
		
		suite_gsa_1:
		; move only on time :
		ld a,(GHOST_SPEED_R)
		OR a
		JP NZ,suite_gsa_2
		; move is possible, if speed  == 0 :
			ld a,(GHOST_RX)
			ld (GHOST_X),a
			ld a,(GHOST_RY)
			ld (GHOST_Y),a
			
			call U_move_ghost
			
			ld a,(GHOST_X)
			ld (GHOST_RX),a
			ld a,(GHOST_Y)
			ld (GHOST_RY),a			
			
			ld a,3
			ld (GHOST_SPEED_R),a
		
		suite_gsa_2:
		ld a,(GHOST_SPEED_R)
		dec a
		ld (GHOST_SPEED_R),a	
	 
	 
; DEPLACEMENT BLUE GHOST :
		; Free the Ghost when GHOST_SPEED_B = 5
		ld a,(GHOST_SPEED_B)		
		CP 5												; If A == N, then Z flag is set.
		JP NZ,suite_gsb_1
		; move Ghost oursite the box
			ld a,19
			ld (GHOST_BX),a
			ld a,8
			ld (GHOST_BY),a	
		
		suite_gsb_1:
		; move only on time :
		ld a,(GHOST_SPEED_B)
		OR a
		JP NZ,suite_gsb_2
		; move is possible, if speed  == 0 :
			ld a,(GHOST_BX)
			ld (GHOST_X),a
			ld a,(GHOST_BY)
			ld (GHOST_Y),a
			
			call U_move_ghost
			
			ld a,(GHOST_X)
			ld (GHOST_BX),a
			ld a,(GHOST_Y)
			ld (GHOST_BY),a			
			
			ld a,2
			ld (GHOST_SPEED_B),a
		
		suite_gsb_2:
		ld a,(GHOST_SPEED_B)
		dec a
		ld (GHOST_SPEED_B),a


; DEPLACEMENT YELLOW GHOST :
		; Free the Ghost when GHOST_SPEED_Y = 5
		ld a,(GHOST_SPEED_Y)		
		CP 5												; If A == N, then Z flag is set.
		JP NZ,suite_gsy_1
		; move Ghost oursite the box
			ld a,19
			ld (GHOST_YX),a
			ld a,8
			ld (GHOST_YY),a	
		
		suite_gsy_1:
		; move only on time :
		ld a,(GHOST_SPEED_Y)
		OR a
		JP NZ,suite_gsy_2
		; move is possible, if speed  == 0 :
			ld a,(GHOST_YX)
			ld (GHOST_X),a
			ld a,(GHOST_YY)
			ld (GHOST_Y),a
			
			call U_move_ghost
			
			ld a,(GHOST_X)
			ld (GHOST_YX),a
			ld a,(GHOST_Y)
			ld (GHOST_YY),a			
			
			ld a,5
			ld (GHOST_SPEED_Y),a
		
		suite_gsy_2:
		ld a,(GHOST_SPEED_Y)
		dec a
		ld (GHOST_SPEED_Y),a
	 
	 
; DEPLACEMENT PINK GHOST :
		; Free the Ghost when GHOST_SPEED_Y = 5
		ld a,(GHOST_SPEED_P)		
		CP 5												; If A == N, then Z flag is set.
		JP NZ,suite_gsp_1
		; move Ghost oursite the box
			ld a,19
			ld (GHOST_PX),a
			ld a,8
			ld (GHOST_PY),a	
		
		suite_gsp_1:
		; move only on time :
		ld a,(GHOST_SPEED_P)
		OR a
		JP NZ,suite_gsp_2
		; move is possible, if speed  == 0 :
			ld a,(GHOST_PX)
			ld (GHOST_X),a
			ld a,(GHOST_PY)
			ld (GHOST_Y),a
			
			call U_move_ghost
			
			ld a,(GHOST_X)
			ld (GHOST_PX),a
			ld a,(GHOST_Y)
			ld (GHOST_PY),a			
			
			ld a,1
			ld (GHOST_SPEED_P),a
		
		suite_gsp_2:
		ld a,(GHOST_SPEED_P)
		dec a
		ld (GHOST_SPEED_P),a	 
	 
	 
	 ; manage immortal pacman :

		ld a, (IMMORTAL)
		OR A
		JP Z, not_immortal
			dec a
			ld (IMMORTAL),a
		
		not_immortal:




; DETECTION JOYPAD PACMAN MOVE :
	call U_PacMan_move


; CHECK IF ALL GUM ARE CATCHED (273 GUM) :
 
	push DE
		LD HL,(NB_GUM)
		ld DE,273
		OR A      ; efface la retenue sans modifier le registre A
		SBC HL,DE ; Le registre HL est modifié par la soustraction avec retenue  -> Si HL=DE alors Z=1
		JP Z,victoire
	pop DE	
	
; DELAI
	 call delai_100us 
	;call delai_10ms

 
JP loop_game


 
victoire:

; load victory screen
 

	ld HL,VICTORY
	call load_image  
 	call update_VRAM 


	
HALT




 
 HALT
 
  

 

    
	
; #######################################
; ############  FUNCTIONS  ##############
; #######################################

; ####################################################################################
; ############ DELAI FUNCTIONS #######################################################
; ####################################################################################

delai_1s:
; @ 8Mhz -> periode T = 0.125 µs 
;   1s = 1 000 000 µs => T*8 000 000

	push BC
	; count until 8 000 000 / 17,4 = 460 000 -> 1s  
	; b=46 -> 1s
	ld b,46	
	count_s3:
		push BC
		ld b,100		
		count_s2:
			push BC
			ld b,100
			count_s1:
				NOP
			djnz count_s1
			pop BC
		djnz count_s2		
		pop BC
	djnz count_s3

	pop BC
ret


delai_250ms:
; @ 8Mhz -> periode T = 0.125 µs 
;   250ms = 250 000 µs => T*2 000 000

	push BC
	; count until 2 000 000 / 17,4 = 115 000 -> 250 ms
	; b=12 -> a little more than 250ms
	ld b,11	
	count_d3:
		push BC
		ld b,100		
		count_d2:
			push BC
			ld b,100
			count_d1:
				NOP
			djnz count_d1
			pop BC
		djnz count_d2		
		pop BC
	djnz count_d3

	pop BC
ret

delai_40ms:
; @ 8Mhz -> periode T = 0.125 µs 
;   40ms = 40 000 µs => T*320 000

	push BC
	; count until 320 000 / 17,4 = 18 390 -> 40ms
	; b=2 -> a little more than 40ms
	ld b,2	
	count_m3:
		push BC
		ld b,100		
		count_m2:
			push BC
			ld b,100
			count_m1:
				NOP
			djnz count_m1
			pop BC
		djnz count_m2		
		pop BC
	djnz count_m3

	pop BC
ret


delai_10ms:
; @ 8Mhz -> periode T = 0.125 µs 
;   10ms = 10 000 µs => T*80 000

	push BC
	; count until 80000 / 17,4 = 4600 -> 5ms 
		ld b,46		
		count_1m2:
			push BC
			ld b,100
			count_1m1:
				NOP
			djnz count_1m1
			pop BC
		djnz count_1m2	

	pop BC
ret



delai_100us:
; @ 8Mhz -> periode T = 0.125 µs 
;  100µs => T*800

	push BC
	; count until 800
	ld b,8		
	count_u2:
		push BC
		ld b,100
		count_u1:
			NOP
		djnz count_u1
		pop BC
	djnz count_u2

	pop BC
ret

delai_2us:
; The fatest execution time for LCD is: tCYC=2us (0.5MHz at 5V).
; @ 8Mhz -> periode T = 0.125 µs 
;  2µs => T*16

	push BC
	; count until 16

	ld b,16
	count_2us:
		NOP
	djnz count_2us

	pop BC
ret	
	
	


; ####################################################################################
; ############ GRAPHICAL FUNCTIONS ###################################################
; ####################################################################################


update_dualpixel_VRAM_3:      
; ; mise à jour d'un double pixel (2X4bits) à l'adresse [@ADDR1 , @ADDR0] (15bits adresse) et de couleurs COLOR (1byte)
; ; Variables (ADDR0 ; ADDR1 ; COLOR) -> Port1
; ; Instructions                      -> Port0

; 	;push BC
	
; 	; 1/ READY = 1, PIXEL = 0, ADDR1 = 0, ADDR0 = 0
; 	; INSTR = 00001000
; 	ld a,%00001000
; 	out (PORT0),a	

; 	; 2/ SEND ADDR0 -> port 1
; 	ld a,(ADDR0)
; 	out (PORT1),a

; 	; -> Activation when LE go from High to LOW
; 	; 3/ READY = 1, PIXEL = 0, ADDR1 = 0, ADDR0 = 1-0
; 	; INSTR = 00001001
; 	ld a,%00001001
; 	out (PORT0),a	
; 	ld a,%00001000
; 	out (PORT0),a

; 	; 4/ SEND ADDR1 -> port 1
; 	ld a,(ADDR1)
; 	out (PORT1),a

; 	; -> Activation when LE go from High to LOW
; 	; 5/ READY = 1, PIXEL = 0, ADDR1 = 1-0, ADDR0 = 0
; 	; INSTR = 00001010
; 	ld a,%00001010
; 	out (PORT0),a
; 	ld a,%00001000
; 	out (PORT0),a	
	
; 	; 6/ SEND COLOR -> port 1
; 	ld a,(COLOR)
; 	out (PORT1),a

; 	; -> Activation when LE go from High to LOW
; 	; 7/ READY = 1, PIXEL = 1-0, ADDR1 = 0, ADDR0 = 0
; 	; INSTR = 00001100
; 	ld a,%00001100
; 	out (PORT0),a
; 	ld a,%00001000
; 	out (PORT0),a
	
; 	; -> UPDATE VRAM :	
; 	; WAIT  PORT n° 02 say it is ready (pin0=0)
 	
; 	; boucle_wait_ready:
; 	; IN a,(PORT2)
; 	; OR a
; 	; JP nz,boucle_wait_ready 	
	
; 	; 8/ READY = 0, PIXEL = 0, ADDR1 = 0, ADDR0 = 0
; 	; INSTR = 00000000
; 	; a == 0 here
; 	XOR a
; 	out (PORT0),a

; 	; 9/ Delay minimum for timing
; 	;NOP

; 	; 10/ READY = 1, PIXEL = 0, ADDR1 = 0, ADDR0 = 0
; 	; INSTR = 00001000
; 	ld a,%00001000
; 	out (PORT0),a

; 	;pop BC

ret


update_VRAM:
; ; Update VIDEO_RAM from BUFFER_VIDEO :			
; ; For each byte from BUFFER_VIDEO (9600 byte ; 15 bits address), copy the byte (= 2 X 4bit Color) to the corresponding VIDEO_RAM
; ; BUFFER_VIDEO 	: address $8000 -> $A580
; ; VRAM 			: address $0 to $79 , then $128 to $207 ...	x120 time (VRAM :  7 + 8 = 15 bit address -> 16384 byte )
 
; 	push BC
; 	push HL

; 	; INSTR = 00001000
; 	ld a,%00001000
; 	out (PORT0),a	
	
; 	ld HL,BUFFER_VIDEO  
; 	ld b,120
; 	ld c,0
; 	boucle_ligne_color:
; 		ld a,c				
; 		; SEND ADDR1 -> port 1
; 		out (PORT1),a
; 		; -> Activation when LE go from High to LOW
; 		; 5/ READY = 1, PIXEL = 0, ADDR1 = 1-0, ADDR0 = 0
; 		; INSTR = 00001010
; 		ld a,%00001010
; 		out (PORT0),a
; 		ld a,%00001000
; 		out (PORT0),a
		
; 		push BC 
; 			ld b,80
; 			ld c,0
; 			boucle_dual_pixel_color: 
; 				ld a,(HL)
				
; 				; 6/ SEND COLOR -> port 1
; 				out (PORT1),a
; 				; -> Activation when LE go from High to LOW
; 				; 7/ READY = 1, PIXEL = 1-0, ADDR1 = 0, ADDR0 = 0
; 				; INSTR = 00001100
; 				ld a,%00001100
; 				out (PORT0),a
; 				ld a,%00001000
; 				out (PORT0),a
										
; 			    inc HL
; 				ld a,c 	 
				
; 				; 2/ SEND ADDR0 -> port 1
; 				out (PORT1),a
; 				; -> Activation when LE go from High to LOW
; 				; 3/ READY = 1, PIXEL = 0, ADDR1 = 0, ADDR0 = 1-0
; 				; INSTR = 00001001
; 				ld a,%00001001
; 				out (PORT0),a				
; 				ld a,%00001000
; 				out (PORT0),a
				
; 				inc c
				
; 				; 8/ READY = 0, PIXEL = 0, ADDR1 = 0, ADDR0 = 0
; 				; INSTR = 00000000
; 				; a == 0 here
; 				XOR a
; 				out (PORT0),a
; 				; 9/ READY = 1, PIXEL = 0, ADDR1 = 0, ADDR0 = 0
; 				; INSTR = 00001000
; 				ld a,%00001000
; 				out (PORT0),a	
				
; 			djnz boucle_dual_pixel_color
; 		pop BC	
; 		inc c
; 	djnz boucle_ligne_color

; 	pop HL 
; 	pop BC

ret


fill_buff:												;  (BUFFER_COLOR)
; SET (160*120*4bit = 9600 byte) from address BUFFER_VIDEO with value BUFFER_COLOR 	

	push HL
	push BC
	
	ld HL,BUFFER_VIDEO
	ld B,$26
	ld C,$AC											; BC contient 9600 (= $2580)   $26AC
	ld a,(BUFFER_COLOR)
	
	boucle_fill_graphic:
		ld (HL),a
		inc HL
		dec C
	jp nz,boucle_fill_graphic
	djnz boucle_fill_graphic							; dec B + jp NZ 

	pop BC
	pop HL
ret







cls_screen:			
; SET BUFFER_VIDEO and COPY IT TO VRAM 	: (BUFFER_COLOR)
	
	call fill_buff	
	call update_VRAM
ret


 


cls_VRAM: 
; SET VRAM with color #0 (BLACK)
	push BC
	push HL
  
	ld b,120
	ld c,0
	boucle_VRAM_L:
		ld a,c
		ld (ADDR1),a	
		push BC 
			ld b,128
			ld c,0
			boucle_VRAM_P: 
				XOR a
			    ld (COLOR),a
			    inc HL
				ld a,c 	 
				ld (ADDR0),a
				inc c
				call update_dualpixel_VRAM_3	
			djnz boucle_VRAM_P
		pop BC	
		inc c
	djnz boucle_VRAM_L

	pop HL 
	pop BC

ret


load_image:				
; LOAD 160*120 * 4bit (9600 byte) from address in (HL) into BUFFER_VIDEO
; HL = IMAGE address ; DE = BUFFER_VIDEO address

	push BC
	push DE
	
; /!\ verifier si une image BMP 16 color est au format 4 bit ou 8 bit
	
	; LDIR : Cette instruction exécute la copie mémoire ( d'un octet de (HL) vers (DE), puis incrémente HL,DE et décrémente BC) tant que BC est supérieur à zéro
	; HL contient l'adresse en memoire de l'image
	ld DE,BUFFER_VIDEO
	ld BC,$2580						; 9600 byte
	LDIR 							; copie BC octets depuis HL vers DE 

	;call update_VRAM
	
	pop DE
	pop BC	
ret	




G_putpixel_dual:								; (BUFFER_X, BUFFER_Y, DUALPIXEL) 
; PUT a dual pixel 8bit at the corresponding address into the BUFFER_VIDEO			
; BUFFER_X = [0->79] ; BUFFER_Y = [0->119] ; DUALPIXEL = [0-15]

	push BC
	push DE
	push HL

	; calculer l'adresse en RAM ((BUFFER_Y*80) + (BUFFER_X/2)
	; copier les 4bit de la couleur au bon endroit dans le byte adress (4bitHIGH / 4bitLow)

	ld D,0
	ld a,(BUFFER_Y)
	ld E,a
	ld B,0
	ld C,80
	call M_MUL_16								; DE = DE * BC
	
	ld H,0
	ld a,(BUFFER_X)
	;SRL a
	ld L,a
	ADD HL,DE									; HL contient l'adresse du dualpixel = ((BUFFER_Y*80) + (BUFFER_X/2)

	ld DE,BUFFER_VIDEO
	add HL,DE									; HL contient l'adresse du dualPixel dans BUFFER_VIDEO

	ld a,(DUALPIXEL)	
	ld (HL),a
	
	pop HL
	pop DE
	pop BC

ret
  
 
 
 

 



; ###############################################
; ############ MATHS FUNCTIONS ##################
; ###############################################


M_ADD:						; 16 bit Signed Addition 
							; INPUT  : DE + BC 
							; OUTPUT : DE

	ld a,e 
	add c					; "add" ajoute les deux valeurs "fractionnelles" et garde la retenue (Carry)
	ld e,a

	ld a,d 
	adc b					; "adc" ajoute les deux valeurs "entiere" et ajoute la precedente retenue si necessaire
	ld d,a
ret


M_SUB:						; 16bit Signed Substraction 
							; INPUT  : DE - BC 
							; OUTPUT : DE

	ld a,e
	sub c					; e = e - c 	et garde la retenue
	ld e,a
	
	ld a,d
	sbc b					; d = d - b - carry
	ld d,a
ret 



M_MUL:						; 16 bit Signed Multiplication 
							; INPUT1 : DE * BC
							; OUTPUT : DE
	push HL

	; First, find out if the output is positive or negative
	  ld a,b
	  xor d
	  push af   ;sign bit is the result sign bit

	; Now make sure the inputs are positive
	  xor d     ;A now has the value of H, since I XORed it with D twice (cancelling)
	  jp p,suite_F_MUL1   ;if Positive, don't negate
	  xor a
	  sub c
	  ld c,a
	  sbc a,a
	  sub b
	  ld b,a
	  
	suite_F_MUL1:
	  bit 7,d
	  jr z,suite_F_MUL2
	  xor a
	  sub e
	  ld e,a
	  sbc a,a
	  sub d
	  ld d,a
 	  
	suite_F_MUL2:
	
	; This routine performs the operation DEHL=BC*DE
	ld hl,0
	ld a,16
	Mul16Loop:		 		
	  add hl,hl
	  rl e
	  rl d
	jp nc,NoMul16
	  add hl,bc
	  jp nc,NoMul16
	  inc de                ; This instruction (with the jump) is like an "ADC DE,0"
	NoMul16:
	  dec a
	  jp nz,Mul16Loop
 
 		ld d,e
		ld e,h			 	 ;  result value in DE now  & ordered	
	
	; Now we need to restore the sign
		pop af
	jp p,fin_F_MUL    		; don't need to do anything, result is already positive
	
	; Now we need to negat the result for the MULT d EH l :	
		ld hl,0
		and a				 ; C and N flags cleared
		sbc hl,de
		ld d,h
		ld e,l
		
 	
	fin_F_MUL:

	; keep only (E.H) for output value (need to grab the 8 bits above and below the decimal in order to keep the output as 8.8 fixed)
  
	pop HL
ret



M_MUL_16:					; 16 bit unsigned Multiplication 
							; INPUT  : DE * BC
							; OUTPUT : DE
	push HL

	; This routine performs the operation DEHL=BC*DE
	ld hl,0
	ld a,16
	Mul_16Loop:		 		
	  add hl,hl
	  rl e
	  rl d
	jp nc,NoMul_16
	  add hl,bc
	  jp nc,NoMul_16
	  inc de               	; This instruction (with the jump) is like an "ADC DE,0"
	NoMul_16:
	  dec a
	  jp nz,Mul_16Loop
 
 		ld d,h
		ld e,l			 	;  result value in DE now  & ordered	

	pop HL
ret


M_DIV_16:					 ; 16 bit UNSIGNED  Division
; INPUT  : BC / DE   /!\ here BC and DE are not same as above math function. DE divide BC !!
; OUTPUT : BC 
;BC/DE ==> BC, remainder in HL
;NOTE: BC/0 returns 0 as the quotient.
;min: 1072cc
;max: 1232cc
;avg: 1152cc
;28 bytes

	push HL
	  xor a
	  ld h,a
	  ld l,a
	  sub e
	  ld e,a
	  sbc a,a
	  sub d
	  ld d,a

	  ld a,b
	  ld b,16

	div_loop:
	  ;shift the bits from BC into HL
	  rl c 
	  rla
	  adc hl,hl
	  add hl,de
	  jr c,div_loop_done
	  sbc hl,de

	div_loop_done:
	  djnz div_loop
	  rl c 
	  rla
	  ld b,a
	  
	pop HL  
ret
 




M_DIV:						; 16 bit UNSIGNED  Division
							; INPUT  : BC / DE   /!\ here BC and DE are not same as above math function. DE divide BC !!
							; OUTPUT : DE 
							
	; /!\ the code below is not from me, I find it on the WEB here : http://z80-heaven.wikidot.com/advanced-math#toc0		

		push HL

	; call update_cursor
	
	 
	;Make DE negative to optimize the remainder comparison
		ld a,d
		or d
		jp m,BC_Div_DE_88_lbl2
		ld hl,0
		and a
		sbc hl,de
		ld d,h
		ld e,l
	
	BC_Div_DE_88_lbl2:
	;The accumulator gets set to B if no overflow.
	;We can use H=0 to save a few cc in the meantime
		ld h,0
		
	;Now we can load the accumulator/remainder with B
	;H is already 0
		ld l,b

		ld a,c
		call div_fixed88_sub
		ld c,a

		ld a,b      ;A is now 0
		call div_fixed88_sub

		ld d,c
		ld e,a
 
	pop HL
ret

div_fixed88_sub:
;min: 456cc
;max: 536cc
;avg: 496cc
		ld b,8
	BC_Div_DE_88_lbl3:
		rla
		adc hl,hl
		add hl,de
		jr c,$+4
		sbc hl,de
		djnz BC_Div_DE_88_lbl3
		adc a,a
ret



M_DIV_8bit:					; 8/8 unsigned Division 
							; INPUT		: C / D 
							; OUTPUT	: C = result, A = rest ; B used.
	 ld b,8
     xor a
       sla c
       rla
       cp d
    jr c,$+4
         inc c
         sub d
    djnz $-8
ret	



 
 

; ###############################################
; ############ USER FUNCTIONS ##################
; ###############################################




U_load_image_7_112:
; LOAD from 0,7 to 159,112 from address in (HL) into BUFFER_VIDEO
; HL = IMAGE address ; DE = BUFFER_VIDEO address

; /!\ une image BMP 16 color est au format 4 bit

	push BC
	push DE
	
	; LDIR : Cette instruction exécute la copie mémoire ( d'un octet de (HL) vers (DE), puis incrémente HL,DE et décrémente BC) tant que BC est supérieur à zéro
	; HL contient l'adresse en memoire de l'image
	ld DE,BUFFER_VIDEO
	ld BC,$2580						; 9600 byte 
	LDIR 							; copie BC octets depuis HL vers DE 

; les 560 premiers dualpixel doivent etre mis à la couleur 0

	ld BC,560
	ld HL,BUFFER_VIDEO

	boucle_560_premier:
		XOR a
		ld (HL),a
		inc HL
		DEC BC
		ld a,B
		OR C
    JR nz,boucle_560_premier	

; les 560 derniers dualpixel doivent etre mis à la couleur 0

	ld BC,560
	ld HL,BUFFER_VIDEO
	ld DE,9040
	add HL,DE

	boucle_560_dernier:
		XOR a
		ld (HL),a
		inc HL
		DEC BC
		ld a,B
		OR C
    JR nz,boucle_560_dernier

	pop DE
	pop BC

ret


U_put_sprite: 									
; copy sprite from image in HL (ORIGINE_X,ORIGINE_Y) To Buffer video (SPRITE_X, SPRITE_Y) , with  width/height (SPRITE_W,SPRITE_H) in dualpixel

; copie image HL en BUFFER_VIDEO sur rectangle defini de (67,114 -> 74,118) vers (SPRITE_X,SPRITE_Y -> SPRITE_X+4,SPRITE_Y+5) : (48,6 -> 72,64) :
	
	push BC
	push DE
	push IX 
	push HL

	; HL = @MAP_PACMAN + ORIGINE_Y*80 + ORIGINE_X
	ld a,(ORIGINE_Y)
	ld D,0
	ld E,a
	ld BC,80
	call M_MUL_16							; 16 bit unsigned Multiplication 
											; INPUT  : DE * BC
											; OUTPUT : DE		
	ld a,(ORIGINE_X)
	ld B,0
	ld c,a
	call M_ADD								; 16 bit Signed Addition 
											; INPUT  : DE + BC 
											; OUTPUT : DE	
											
	ld HL,MAP_PACMAN
	add HL,DE								; HL contient l'adresse ou copier le SPRITE

 
	; IX = @BUFFER_VIDEO + (SPRITE_Y+5)*80 + SPRITE_X

	ld a,(SPRITE_Y)
	;add 5
	ld D,0
	ld E,a
	ld BC,80
	call M_MUL_16							; 16 bit unsigned Multiplication 
											; INPUT  : DE * BC
											; OUTPUT : DE
	ld a,(SPRITE_X)
	ld B,0
	ld C,a
	call M_ADD								; 16 bit Signed Addition 
											; INPUT  : DE + BC 
											; OUTPUT : DE
	ld IX,BUFFER_VIDEO							
	ADD IX,DE								; IX contient l'adresse ou coller le SPRITE
	
	
	
	; Loop on Y = SPRITE_H	
	ld a,(SPRITE_H)
	ld B,a
	boucle_SPRITE_H_dualpixel:
	
		push BC
		
		; Loop on X = SPRITE_W	
		ld a,(SPRITE_W)
		ld B,a
		boucle_SPRITE_W_dualpixel:
			ld a,(HL)
			ld (IX),a
			inc IX
			inc HL		
		djnz boucle_SPRITE_W_dualpixel
		
		; saut de ligne - SPRITE_W = 80 - SPRITE_W
		ld a,(SPRITE_W)
		ld b,a
		ld a,80						
		SUB B
		ld D,0
		ld E,a
		ADD HL,DE
		ADD IX,DE			
	
		pop BC
		
	djnz boucle_SPRITE_H_dualpixel		
	  
	pop HL
	pop IX
	pop DE
	pop BC



ret




U_copy_area:
; AREA = AREA_ORIGINE

	push HL
	push BC
	push DE
	
	; LDIR : Cette instruction exécute la copie mémoire ( d'un octet de (HL) vers (DE), puis incrémente HL,DE et décrémente BC) tant que BC est supérieur à zéro
	; HL contient l'adresse en memoire de l'image
	ld HL,AREA_ORIGINE
	ld DE,AREA
	ld BC,$035A						; 858 byte
	LDIR 							; copie BC octets depuis HL vers DE 
 
	pop DE
	pop BC	
	pop HL

ret


U_PacMan_move:
; PacMan se deplace de 4 pixels (=2dualpixel) horizontalement et de 5 pixels verticalement.

	push HL
	push BC
	push DE


; GESTION DEPLACEMENT / COLISION
	; test Joypad on Port 7 :

	IN a,(PORT7)
	ld E,a
	; check if a <> 0
	;OR a
	;JP z,FIN_GEST_DEP
	
	; verifier quelle direction est selectionnée :
	ld a,E
	CP %00000001									; If A == N, then Z flag is set.
	JP Z,JOY_UP
	ld a,E
	CP %00000010
	JP Z,JOY_LEFT
	ld a,E	
	CP %00000100
	JP Z,JOY_DOWN
	ld a,E	
	CP %00001000
	JP Z,JOY_RIGHT	
	
	; sinon on quitte
	JP FIN_GEST_DEP	
	
	JOY_UP:
	;generate new coordinate
	ld a,(PAC_Y)
	dec a
	ld (PAC_TY),a
	ld a,(PAC_X)
	ld (PAC_TX),a
	ld a,5
	ld (PAC_DIR),a
	 

	JP SUITE_GEST_DEP
	
	JOY_LEFT:
	;generate new coordinate
	ld a,(PAC_X)
	dec a
	ld (PAC_TX),a
	ld a,(PAC_Y)
	ld (PAC_TY),a
	ld a,10
	ld (PAC_DIR),a

	JP SUITE_GEST_DEP

	JOY_DOWN:
	ld a,(PAC_Y)
	inc a
	ld (PAC_TY),a
	ld a,(PAC_X)
	ld (PAC_TX),a	
	XOR a
	ld (PAC_DIR),a	
	 
	JP SUITE_GEST_DEP	
	
	JOY_RIGHT:
	;generate new coordinate
	ld a,(PAC_X)
	inc a
	ld (PAC_TX),a
	ld a,(PAC_Y)
	ld (PAC_TY),a	
	ld a,15
	ld (PAC_DIR),a	

	
	SUITE_GEST_DEP:
	
	; check if new coordinate is a wall	or not :
	
	ld a,(PAC_TY)	
	ld D,0
	ld E,a
	ld BC,39
	; multiplier par 39 car la MAP fait 39*22 donc 39 colonnes
	call M_MUL_16								; 16 bit unsigned Multiplication 
												; INPUT  : DE * BC
												; OUTPUT : DE
	
	; add PAC_TX
	ld a,(PAC_TX)
	ld B,0
	ld C,a
	call M_ADD									; 16 bit Signed Addition 
												; INPUT  : DE + BC 
												; OUTPUT : DE
	ld HL,AREA
	add HL,DE									; HL contient la case ou le joueur veut aller
	
	; check if case <> 0
	ld a,(HL)
	OR a
	JP Z, FIN_GEST_DEP							; MUR

 
 
 
	; check if PACMAN will be on PGUMx :
	ld a,(HL)
	CP 3
	jp Z,SUPERGUM1						;If A == N, then Z flag is set. 
	
	ld a,(HL)
	CP 4
	jp Z,SUPERGUM2						;If A == N, then Z flag is set. 	
	
	ld a,(HL)
	CP 5
	jp Z,SUPERGUM3						;If A == N, then Z flag is set. 
	
	ld a,(HL)
	CP 6
	jp Z,SUPERGUM4						;If A == N, then Z flag is set. 		
	
	; sinon
	JP SUITE_GEST_DEP1
	
	SUPERGUM1:	
	XOR a
	ld (PGUM1),a
	ld a,1
	ld (HL),a
	ld a,50								; 100 -> 5s
	ld (IMMORTAL),a
	JP SUITE_GEST_DEP1

	SUPERGUM2:	
	XOR a
	ld (PGUM2),a
	ld a,1
	ld (HL),a
	ld a,50
	ld (IMMORTAL),a
	JP SUITE_GEST_DEP1

	SUPERGUM3:	
	XOR a
	ld (PGUM3),a
	ld a,1
	ld (HL),a
	ld a,50
	ld (IMMORTAL),a	
	JP SUITE_GEST_DEP1

	SUPERGUM4:	
	XOR a
	ld (PGUM4),a
	ld a,1
	ld (HL),a
	ld a,50
	ld (IMMORTAL),a


	SUITE_GEST_DEP1:	
	
	; check if PAC_TX=0 ; alors PAC_TX=18	
		ld a,(PAC_TX)
		;dec a
		OR a
	JP NZ,SUITE_GEST_DEP2
	
	ld a,38
	ld (PAC_TX),a	
	
	JP SUITE_GEST_DEP3

	SUITE_GEST_DEP2:	
	; check if PAC_TX=19 ; alors PAC_TX=1
		ld a,(PAC_TX)
		sub 38
		OR a
	JP NZ,SUITE_GEST_DEP3	
	ld a,1
	ld (PAC_TX),a		

 
	SUITE_GEST_DEP3:
	; else move to the new coordinate	
	ld a,(PAC_TX)
	ld (PAC_X),a
	ld a,(PAC_TY)
	ld (PAC_Y),a

		; remove Gum from new coordinate if exit	
	ld a,(HL)

	dec a
	dec a
	OR a
	JP NZ,FIN_GEST_DEP							
	
	; if (a == 2) alors a = 1
	ld a,1
	ld (HL),a
	
	; incrementer le nombre de gum attrapées
	ld HL,(NB_GUM)
	inc HL
	ld (NB_GUM),HL
	
	; ajouter 4 points au score
	
	ld HL,(SCORE)
	ld DE,4
	ADD HL,DE 
	ld (SCORE),HL

	FIN_GEST_DEP: 

	pop DE
	pop BC	
	pop HL	
	
ret	


U_display_PacMan:
; copy sprite from image in HL (ORIGINE_X,ORIGINE_Y) To Buffer video (SPRITE_X, SPRITE_Y) , with  width/height (SPRITE_W,SPRITE_H)  in dualpixel

	push HL
	push BC
	push DE
 
	; SPRITE_X = (PAC_X) x 2 dualpixel
	ld a,(PAC_X)
	SLA a											; a Multiply by 2
	;SLA a											; a Multiply by 4
	ld (SPRITE_X),a
	
	; SPRITE_Y = (PAC_Y) x 5
	ld a,(PAC_Y)
	ld E,a
	SLA a											; a Multiply by 2
	SLA a											; a Multiply by 4
	add E											; a Multiply by 5
	add 5											; cause PacMan is 5 Pixel height
 	ld (SPRITE_Y),a

	; select PacMan orientation regarding (PAC_DIR)
	; 0 -> DOWN (33,114)
	; 5 -> UP   (38,114)
	; 10 -> LEFT (43,114)
	; 15 -> RIGHT(48,114)
	
	; ORIGINE_X = PAC_DIR_X en dualpixel
	ld a,(PAC_DIR)
	ld E,a	
	ld a,33
	ADD E
	ld (ORIGINE_X),a
	
	; ORIGINE_Y = PACMAN_DIR_Y (always the same)
	ld a,114
	ld (ORIGINE_Y),a	
	
	; SPRITE_W = PACMAN_W en dualpixel
	ld a,4
	ld (SPRITE_W),a
	
	; SPRITE_H = PACMAN_H
	ld a,5
	ld (SPRITE_H),a
	
	; display PACMAN 	
	call U_put_sprite


	pop DE
	pop BC	
	pop HL
	
ret


U_remove_PacMan:
; copy black square ( To Buffer video (SPRITE_X, SPRITE_Y) , with  width/height (4,5)  in dualpixel

	push HL
	push BC
	push DE
 
	; SPRITE_X = (PAC_X) x 2 dualpixel
	ld a,(PAC_X)
	SLA a											; a Multiply by 2
	ld (SPRITE_X),a
	
	; SPRITE_Y = (PAC_Y) x 5
	ld a,(PAC_Y)
	ld E,a
	SLA a											; a Multiply by 2
	SLA a											; a Multiply by 4
	add E											; a Multiply by 5
	add 5											; cause PacMan is 5 Pixel height
 	ld (SPRITE_Y),a



	; HL = @BUFFER_VIDEO + (SPRITE_Y+5)*80 + SPRITE_X

	ld a,(SPRITE_Y)
	ld D,0
	ld E,a
	ld BC,80
	call M_MUL_16							; 16 bit unsigned Multiplication 
											; INPUT  : DE * BC
											; OUTPUT : DE
	ld a,(SPRITE_X)
	ld B,0
	ld C,a
	call M_ADD								; 16 bit Signed Addition 
											; INPUT  : DE + BC 
											; OUTPUT : DE
	ld HL,BUFFER_VIDEO							
	ADD HL,DE								; IX contient l'adresse ou coller le SPRITE
	

	; remove PacMan 	

	ld B,5
	boucle_EMPTY_H_dualpixel:
	
		push BC

		ld B,4
		boucle_EMPTY_W_dualpixel:
			XOR a
			ld (HL),a
			inc HL		
		djnz boucle_EMPTY_W_dualpixel
		
		; saut de ligne = 80 - 4 = 76
		ld D,0
		ld E,76
		ADD HL,DE 		
	
		pop BC
		
	djnz boucle_EMPTY_H_dualpixel		


	pop DE
	pop BC	
	pop HL


ret


U_display_gum:
; display all the gum into 

	push HL
	push BC
	push DE
	push IX

	ld IX,AREA
	ld HL,BUFFER_VIDEO
	ld DE,562
	add HL,DE												; on avance de 7 lignes + 2 dualpixels 
	
	; pour Y[0->21]  
	ld D,22
	ld E,0
	boucle_MAP_Y:		 
		
		; pour X[0->38]
		ld B,39
		ld C,0
		boucle_MAP_X:
			
		 ld a,(IX)
				 
			; si AREA[Y*39+X] = 2 => gum
			dec a
			dec a
			OR a
			JP nz, suite_boucle_MAP
			
				;display dans @BUFFER_VIDEO			
				ld a,$F0 
				ld (HL),a				
	
		suite_boucle_MAP:
		
		; increment IX
		inc IX
		
		;increment HL de 2 dualpixel
		inc HL
		inc HL
		
		inc C
		djnz boucle_MAP_X
	
	;increment HL de 4 lignes de 80 dualpixel = 320 + 2
		push DE
			ld DE,322
			add HL,DE
		pop DE 
	inc E
	dec D
	JP NZ,boucle_MAP_Y

	pop IX
	pop DE
	pop BC	
	pop HL
	
ret 



U_display_score:
; display score game
; copy sprite from image in HL (ORIGINE_X,ORIGINE_Y) To Buffer video (SPRITE_X, SPRITE_Y) , with  width/height (SPRITE_W,SPRITE_H)  in dualpixel

	push HL
	push BC
	push DE
	push IX

	ld a,22
	ld (ORIGINE_X),a
	ld (SPRITE_X),a	
	ld a,1
	ld (ORIGINE_Y),a 
	ld (SPRITE_Y),a	

	ld a,19
	ld (SPRITE_W),a
	ld a,5
	ld (SPRITE_H),a

	; display SCORE 	
	call U_put_sprite
	
	
	; Display each Digit :
	ld HL,(SCORE)
	ld (SCORE_DIS),HL

	ld DE,1000
	ld a,42
	ld (SPRITE_X),a
	call U_display_digit

	ld DE,100
	ld a,45
	ld (SPRITE_X),a
	call U_display_digit

	ld DE,10
	ld a,48
	ld (SPRITE_X),a 
	call U_display_digit

	ld DE,1
	ld a,51
	ld (SPRITE_X),a 
	call U_display_digit	

	pop IX
	pop DE
	pop BC	
	pop HL
	
ret


U_display_digit:
 
	push HL
	
	ld HL,(SCORE_DIS)
	XOR a
	ld (DIGIT),a	 
	boucle_digit:
		OR A     												; efface la retenue sans modifier le registre A
		SBC HL,DE 												; Le registre HL est modifié par la soustraction avec retenue
		; HL>=DE alors C=0  ; HL<DE alors C=1
	JP C,affiche_digit
	; HL>DE -> increment digit
		ld a,(DIGIT)
		inc a
		ld (DIGIT),a
	JP boucle_digit
	
	affiche_digit: 
		ADD HL,DE												; put back the last substraction, because it was negative
		ld (SCORE_DIS),HL
		ld a,(DIGIT)
		ld E,a
		SLA a													; a Multiply by 2	  
		ADD E													; a Multiply by 3
		add 42
		ld (ORIGINE_X),a	  
		ld a,1
		ld (ORIGINE_Y),a 
		ld (SPRITE_Y),a	
		ld a,3
		ld (SPRITE_W),a
		ld a,5
		ld (SPRITE_H),a	
				
		; display DIGIT n 	
		call U_put_sprite	

	pop HL

ret


U_display_life:
; display all life

	push HL
	push BC
	push DE
	push IX	
	
	ld a,(LIFE)
		OR a
	JP z,fin_life

		ld a,43
		ld (ORIGINE_X),a
		ld a,114
		ld (ORIGINE_Y),a
		ld (SPRITE_Y),a	

		ld a,4
		ld (SPRITE_W),a
		ld a,5
		ld (SPRITE_H),a

		
		; afficher premiere VIE :
		ld a,2
		ld (SPRITE_X),a	
		; display SCORE 	
		call U_put_sprite	
		
		
		ld a,(LIFE)
		dec a
		OR a
	JP z,fin_life
	
		; afficher seconde VIE :
		ld a,8
		ld (SPRITE_X),a	
		; display SCORE 	
		call U_put_sprite	
		
		
		ld a,(LIFE)
		dec a
		dec a
		OR a
	JP z,fin_life
	
		; afficher troisieme VIE :
		ld a,14
		ld (SPRITE_X),a	
		; display SCORE 	
		call U_put_sprite	
		
		
	fin_life:
	
	pop IX
	pop DE
	pop BC	
	pop HL	

ret


U_display_PGUM:
; display all pgum

	ld a,28
	ld (ORIGINE_X),a
	ld a,114
	ld (ORIGINE_Y),a	
	ld a,4
	ld (SPRITE_W),a
	ld a,5
	ld (SPRITE_H),a
		
	ld a,(PGUM1)
	OR a
	JP Z,suite_pgum2

	; display PGUM1 :	

		ld a,2
		ld (SPRITE_X),a	
		ld a,15
		ld (SPRITE_Y),a	
		
		; display PGUM
		call U_put_sprite	
	


	suite_pgum2:
	ld a,(PGUM2)
	OR a
	JP Z,suite_pgum3

	; display PGUM2 :	

		ld a,74
		ld (SPRITE_X),a	
		ld a,15
		ld (SPRITE_Y),a	 
		
		; display PGUM
		call U_put_sprite	
	


	suite_pgum3:	
	ld a,(PGUM3)
	OR a
	JP Z,suite_pgum4

	; display PGUM3 :	

		ld a,2
		ld (SPRITE_X),a	
		ld a,85
		ld (SPRITE_Y),a	 
		
		; display PGUM
		call U_put_sprite	
	


	suite_pgum4:		
	ld a,(PGUM4)
	OR a
	JP Z,fin_pgum

	; display PGUM4 :	

		ld a,74
		ld (SPRITE_X),a	
		ld a,85
		ld (SPRITE_Y),a	 
		
		; display PGUM
		call U_put_sprite		
	

	fin_pgum:
 

ret 



U_display_immortal: ; IMMORTAL

	push HL
	push BC
	push DE
	push IX	
	
	
	ld a, (IMMORTAL)
	OR a	
	JP Z,fin_display_immortal
	
		; diplay the PowerGum :
		
		ld a,28
		ld (ORIGINE_X),a
		ld a,114
		ld (ORIGINE_Y),a	
		ld a,4
		ld (SPRITE_W),a
		ld a,5
		ld (SPRITE_H),a
		ld a,2
		ld (SPRITE_X),a	
		ld a,1
		ld (SPRITE_Y),a	
		
		; display PGUM
		call U_put_sprite	
	
	
	fin_display_immortal:

	pop IX
	pop DE
	pop BC	
	pop HL

ret 


U_display_ghost_R:
; affichage du fantome 

	; diplay the Ghost :
	ld a,(GHOST_RX)	
	SLA a											; a Multiply by 2 
	ld (SPRITE_X),a
	
	; SPRITE_Y = (GHOST_RY) x 5
	ld a,(GHOST_RY)
	ld E,a
	SLA a											; a Multiply by 2
	SLA a											; a Multiply by 4
	add E											; a Multiply by 5
	add 5											; cause Ghost is 5 Pixel height
 	ld (SPRITE_Y),a
	
	ld a,54
	ld (ORIGINE_X),a
	ld a,114
	ld (ORIGINE_Y),a	
	ld a,4
	ld (SPRITE_W),a
	ld a,5
	ld (SPRITE_H),a 
	
	; display Ghost :
	call U_put_sprite	
	
ret


jeu_perdu:

	; load endgame screen :
	; sorry, I'm out of space in ROM 32K for anotother picture...
	; just restart the game then
	
	HALT
	
ret 	



U_collision_RED:
; test si collision avec le fantome rouge

	push DE
	
		ld a,(GHOST_RX)
		ld e,a	
		ld a,(PAC_X)
		CP e													; If A == N, then Z flag is set.
		JP nz, fin_collision_red

		ld a,(GHOST_RY)
		ld e,a	
		ld a,(PAC_Y)
		CP e
		JP nz, fin_collision_red
		
		; il y a eu collision :		
		; So we test if PACMAN is immortal		
		ld a,(IMMORTAL)
		OR a
		JP Z, pac_dead
		
		;###########			
		; IF yes => then red ghost is dead:
		
		; get 200 points
			ld HL,(SCORE)
			ld DE,200
			ADD HL,DE 
			ld (SCORE),HL
	
		; RED Ghost go back to Hive (15,10) and reset TIMER
			ld a,15
			ld (GHOST_RX),a
			ld a,10
			ld (GHOST_RY),a
			ld a,30
			ld (GHOST_SPEED_R),a
	
		JP fin_collision_red		
		
		;###########		
		; IF no => then PacMan lose a life:		
		pac_dead:
		; PAC-MAN clignote 2s

			call U_remove_PacMan
			; AFFICHAGE SUR ECRAN LCD
			call update_VRAM
			call delai_250ms			
			call U_display_ghost_R ; U_display_PacMan
			; AFFICHAGE SUR ECRAN LCD
			call update_VRAM			
			call delai_250ms
			call U_remove_PacMan
			; AFFICHAGE SUR ECRAN LCD
			call update_VRAM			
			call delai_250ms	
			call U_display_ghost_R ; U_display_PacMan			
			; AFFICHAGE SUR ECRAN LCD
			call update_VRAM
			call delai_1s
		
		; pac-man still has a life or end of game?
			ld a,(LIFE)
			dec a			
			OR a
			JP Z,jeu_perdu
			ld (LIFE),a
		
		; if pac-man still alive, it go back to original coordinate
			ld a,19
			ld (PAC_X),a
			ld a,16
			ld (PAC_Y),a	
			ld a,15 									;(RIGHT)
			ld (PAC_DIR),a			
		
	
		JP fin_collision_red	
	
		
		
	fin_collision_red:	

	pop DE

ret


U_display_ghost_B:
; affichage du fantome 

	; diplay the Ghost :
	ld a,(GHOST_BX)	
	SLA a											; a Multiply by 2 
	ld (SPRITE_X),a
	
	; SPRITE_Y = (GHOST_BY) x 5
	ld a,(GHOST_BY)
	ld E,a
	SLA a											; a Multiply by 2
	SLA a											; a Multiply by 4
	add E											; a Multiply by 5
	add 5											; cause Ghost is 5 Pixel height
 	ld (SPRITE_Y),a
	
	ld a,59
	ld (ORIGINE_X),a
	ld a,114
	ld (ORIGINE_Y),a	
	ld a,4
	ld (SPRITE_W),a
	ld a,5
	ld (SPRITE_H),a 
	
	; display Ghost :
	call U_put_sprite	
	
ret


U_collision_BLUE:
; test si collision avec le fantome bleu

	push DE
	
		ld a,(GHOST_BX)
		ld e,a	
		ld a,(PAC_X)
		CP e													; If A == N, then Z flag is set.
		JP nz, fin_collision_blue

		ld a,(GHOST_BY)
		ld e,a	
		ld a,(PAC_Y)
		CP e
		JP nz, fin_collision_blue
		
		; il y a eu collision :		
		; So we test if PACMAN is immortal		
		ld a,(IMMORTAL)
		OR a
		JP Z, pac_dead_b
		
		;###########			
		; IF yes => then blue ghost is dead:
		
		; get 300 points
			ld HL,(SCORE)
			ld DE,300
			ADD HL,DE 
			ld (SCORE),HL
	
		; BLUE Ghost go back to Hive (18,10) and reset TIMER
			ld a,18
			ld (GHOST_BX),a
			ld a,10
			ld (GHOST_BY),a
			ld a,50
			ld (GHOST_SPEED_B),a
	
		JP fin_collision_blue		
		
		;###########		
		; IF no => then PacMan lose a life:		
		pac_dead_b:
		; PAC-MAN clignote 2s

			call U_remove_PacMan
			; AFFICHAGE SUR ECRAN LCD
			call update_VRAM
			call delai_250ms			
			call U_display_ghost_B ; U_display_PacMan
			; AFFICHAGE SUR ECRAN LCD
			call update_VRAM			
			call delai_250ms
			call U_remove_PacMan
			; AFFICHAGE SUR ECRAN LCD
			call update_VRAM			
			call delai_250ms	
			call U_display_ghost_B ; U_display_PacMan			
			; AFFICHAGE SUR ECRAN LCD
			call update_VRAM
			call delai_1s
		
		; pac-man still has a life or end of game?
			ld a,(LIFE)
			dec a			
			OR a
			JP Z,jeu_perdu
			ld (LIFE),a
		
		; if pac-man still alive, it go back to original coordinate
			ld a,19
			ld (PAC_X),a
			ld a,16
			ld (PAC_Y),a	
			ld a,15 									;(RIGHT)
			ld (PAC_DIR),a			

		
	fin_collision_blue:	

	pop DE

ret




U_display_ghost_Y:
; affichage du fantome 

	; diplay the Ghost :
	ld a,(GHOST_YX)	
	SLA a											; a Multiply by 2 
	ld (SPRITE_X),a
	
	; SPRITE_Y = (GHOST_BY) x 5
	ld a,(GHOST_YY)
	ld E,a
	SLA a											; a Multiply by 2
	SLA a											; a Multiply by 4
	add E											; a Multiply by 5
	add 5											; cause Ghost is 5 Pixel height
 	ld (SPRITE_Y),a
	
	ld a,64
	ld (ORIGINE_X),a
	ld a,114
	ld (ORIGINE_Y),a	
	ld a,4
	ld (SPRITE_W),a
	ld a,5
	ld (SPRITE_H),a 
	
	; display Ghost :
	call U_put_sprite	
	
ret


U_collision_YELLOW:
; test si collision avec le fantome jaune

	push DE
	
		ld a,(GHOST_YX)
		ld e,a	
		ld a,(PAC_X)
		CP e													; If A == N, then Z flag is set.
		JP nz, fin_collision_yellow

		ld a,(GHOST_YY)
		ld e,a	
		ld a,(PAC_Y)
		CP e
		JP nz, fin_collision_yellow
		
		; il y a eu collision :		
		; So we test if PACMAN is immortal		
		ld a,(IMMORTAL)
		OR a
		JP Z, pac_dead_y
		
		;###########			
		; IF yes => then yellow ghost is dead:
		
		; get 100 points
			ld HL,(SCORE)
			ld DE,100
			ADD HL,DE 
			ld (SCORE),HL
	
		; YELLOW Ghost go back to Hive (21,10) and reset TIMER
			ld a,21
			ld (GHOST_YX),a
			ld a,10
			ld (GHOST_YY),a
			ld a,70
			ld (GHOST_SPEED_Y),a
	
		JP fin_collision_yellow		
		
		;###########		
		; IF no => then PacMan lose a life:		
		pac_dead_y:
		; PAC-MAN clignote 2s

			call U_remove_PacMan
			; AFFICHAGE SUR ECRAN LCD
			call update_VRAM
			call delai_250ms			
			call U_display_ghost_Y ; U_display_PacMan
			; AFFICHAGE SUR ECRAN LCD
			call update_VRAM			
			call delai_250ms
			call U_remove_PacMan
			; AFFICHAGE SUR ECRAN LCD
			call update_VRAM			
			call delai_250ms	
			call U_display_ghost_Y ; U_display_PacMan			
			; AFFICHAGE SUR ECRAN LCD
			call update_VRAM
			call delai_1s
		
		; pac-man still has a life or end of game?
			ld a,(LIFE)
			dec a			
			OR a
			JP Z,jeu_perdu
			ld (LIFE),a
		
		; if pac-man still alive, it go back to original coordinate
			ld a,19
			ld (PAC_X),a
			ld a,16
			ld (PAC_Y),a	
			ld a,15 									;(RIGHT)
			ld (PAC_DIR),a			

		
	fin_collision_yellow:	

	pop DE

ret





U_display_ghost_P:
; affichage du fantome 

	; diplay the Ghost :
	ld a,(GHOST_PX)	
	SLA a											; a Multiply by 2 
	ld (SPRITE_X),a
	
	; SPRITE_Y = (GHOST_BY) x 5
	ld a,(GHOST_PY)
	ld E,a
	SLA a											; a Multiply by 2
	SLA a											; a Multiply by 4
	add E											; a Multiply by 5
	add 5											; cause Ghost is 5 Pixel height
 	ld (SPRITE_Y),a
	
	ld a,69
	ld (ORIGINE_X),a
	ld a,114
	ld (ORIGINE_Y),a	
	ld a,4
	ld (SPRITE_W),a
	ld a,5
	ld (SPRITE_H),a 
	
	; display Ghost :
	call U_put_sprite	
	
ret


U_collision_pink:
; test si collision avec le fantome rose

	push DE
	
		ld a,(GHOST_PX)
		ld e,a	
		ld a,(PAC_X)
		CP e													; If A == N, then Z flag is set.
		JP nz, fin_collision_pink

		ld a,(GHOST_PY)
		ld e,a	
		ld a,(PAC_Y)
		CP e
		JP nz, fin_collision_pink
		
		; il y a eu collision :		
		; So we test if PACMAN is immortal		
		ld a,(IMMORTAL)
		OR a
		JP Z, pac_dead_p
		
		;###########			
		; IF yes => then pink ghost is dead:
		
		; get 500 points
			ld HL,(SCORE)
			ld DE,500
			ADD HL,DE 
			ld (SCORE),HL
	
		; PINK Ghost go back to Hive (24,10) and reset TIMER
			ld a,24
			ld (GHOST_PX),a
			ld a,10
			ld (GHOST_PY),a
			ld a,20
			ld (GHOST_SPEED_P),a
	
		JP fin_collision_pink	
		
		;###########		
		; IF no => then PacMan lose a life:		
		pac_dead_p:
		; PAC-MAN clignote 2s

			call U_remove_PacMan
			; AFFICHAGE SUR ECRAN LCD
			call update_VRAM
			call delai_250ms			
			call U_display_ghost_P ; U_display_PacMan
			; AFFICHAGE SUR ECRAN LCD
			call update_VRAM			
			call delai_250ms
			call U_remove_PacMan
			; AFFICHAGE SUR ECRAN LCD
			call update_VRAM			
			call delai_250ms	
			call U_display_ghost_P ; U_display_PacMan			
			; AFFICHAGE SUR ECRAN LCD
			call update_VRAM
			call delai_1s
		
		; pac-man still has a life or end of game?
			ld a,(LIFE)
			dec a			
			OR a
			JP Z,jeu_perdu
			ld (LIFE),a
		
		; if pac-man still alive, it go back to original coordinate
			ld a,19
			ld (PAC_X),a
			ld a,16
			ld (PAC_Y),a	
			ld a,15 									;(RIGHT)
			ld (PAC_DIR),a			

		
	fin_collision_pink:	

	pop DE

ret





U_move_ghost:
; generate red ghost move (horizontal first, otherwith vertical, to prevent diagonal move) 
; variables GHOST_X ; GHOST_Y

	push HL
	push BC
	push DE

	;###########
	CMP_GX:
	; comparer GHOST_X avec PAC_X (= delta_X) et trouver X_DIR (+1 , 0 , -1)
	ld a,(GHOST_X)
	ld E,a
	ld a,(PAC_X)
	CP E												; If A == N, then Z flag is set.
	JP Z,X_DIR_0
		;sinon :
		
	ld a,(GHOST_X)
	ld E,a
	ld a,(PAC_X)
	CP E												; If A >= N, then C flag is reset.
	JP NC,X_DIR_1
		; sinon -1
		
		ld  a,$ff
		ld (X_DIR),a	
	JP CMP_GY
	
	X_DIR_0:
		XOR a
		ld (X_DIR),a
	JP CMP_GY
	
	X_DIR_1:
		ld  a,$1
		ld (X_DIR),a	
		
	
	;###########	
	CMP_GY:	
	; comparer GHOST_Y avec PAC_Y (= delta_Y) et trouver Y_DIR (+1 , 0 , -1)
	ld a,(GHOST_Y)
	ld E,a
	ld a,(PAC_Y)
	CP E												; If A == N, then Z flag is set.
	JP Z,Y_DIR_0
		;sinon :
		
	ld a,(GHOST_Y)
	ld E,a
	ld a,(PAC_Y)
	CP E												; If A >= N, then C flag is reset.
	JP NC,Y_DIR_1
		; sinon -1
		
		ld  a,$ff										; ajouter $ff (255) c'est comme soustaire 1 sur une valeur 8bits : ex 25 + 255 = 24
		ld (Y_DIR),a	
	JP CHECK_MUR_H
	
	Y_DIR_0:
		XOR a
		ld (Y_DIR),a
	JP CHECK_MUR_H
	
	Y_DIR_1:
		ld  a,$1
		ld (Y_DIR),a		
		
	
	;###########		
	CHECK_MUR_H:
	; verifier si X_DIR != 0
		ld a,(X_DIR)
		OR a
		JP Z,CHECK_MUR_V
	; verifier si Mur Horizontal : si (GHOST_X + X_DIR ,GHOST_Y) n'est pas un mur
		
		; (GHOST_Y) * 39
		ld a,(GHOST_Y)
		ld E,a
		ld D,0
		ld BC,39
		
		; multiplier par 39 car la MAP fait 39*22 donc 39 colonnes
		call M_MUL_16								; 16 bit unsigned Multiplication  	; INPUT  : DE * BC  	; OUTPUT : DE
	
		; add GHOST_X + X_DIR	
		ld a,(GHOST_X)
		ld C,a
		ld a,(X_DIR) 
		add C
		ld C,a
		ld B,0

		call M_ADD									; 16 bit Signed Addition    		; INPUT  : DE + BC   	; OUTPUT : DE
	
		ld HL,AREA
		add HL,DE									; HL contient la case ou le joueur veut aller
	
		; check if case <> 0 : pas un mur
		ld a,(HL)
		OR a
		JP Z, CHECK_MUR_V							; MUR, alors on tente de deplacer sur les Verticals

		; if ok, move ghost HORIZONTALY :
			; GHOST_X =(GHOST_X + X_DIR)
			ld a,(GHOST_X)
			ld E,a
			ld a,(X_DIR) 
			add E
			ld (GHOST_X),a	
			
		JP fin_move_ghost_r
		
		
	;###########	
	CHECK_MUR_V:
	; verifier si Mur Vertical (GHOST_X,GHOST_Y + Y_DIR) n'est pas un mur
		
		; (GHOST_Y + Y_DIR) * 39
		ld a,(GHOST_Y)
		ld E,a
		ld a,(Y_DIR) 
		add E	
		ld E,a
		ld D,0
		ld BC,39
		
		; multiplier par 39 car la MAP fait 39*22 donc 39 colonnes
		call M_MUL_16								; 16 bit unsigned Multiplication 	; INPUT  : DE * BC  	; OUTPUT : DE
	
		; add GHOST_X	
		ld a,(GHOST_X)
		ld C,a
		ld B,0

		call M_ADD									; 16 bit Signed Addition    		; INPUT  : DE + BC   	; OUTPUT : DE
		
		ld HL,AREA
		add HL,DE									; HL contient la case ou le joueur veut aller
	
		; check if case <> 0 : pas un mur
		ld a,(HL)
		OR a
		JP Z, fin_move_ghost_r							; MUR, alors pour le moment, le fantome rouge ne se deplace pas
		
		; if ok, move  ghost VERTICALLY :
			; GHOST_Y = (GHOST_Y + Y_DIR)
			ld a,(GHOST_Y)
			ld E,a
			ld a,(Y_DIR) 
			add E	
			ld (GHOST_Y),a	
		
		
		

	fin_move_ghost_r:

	pop DE
	pop BC	
	pop HL

ret

U_Load_Ready:
; Display READY!
	
	XOR a
	ld (ORIGINE_X),a 
	ld (ORIGINE_Y),a	
	
	ld a,33
	ld (SPRITE_X),a	
	ld a,65
 	ld (SPRITE_Y),a	
	ld a,14
	ld (SPRITE_W),a
	ld a,5
	ld (SPRITE_H),a 
	
	; display READY! :
	call U_put_sprite	

ret
