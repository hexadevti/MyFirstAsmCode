; Programme n°61 v0.4
; Assembleur Z80
; Pour la carte LCD 128x64 WriteOnly
; Le 02/09/2021

CPU Z80         				; switch to Z80 mode
FNAME "LCD_WO.4.bin"     		; output file name

; ###############################################################
; #										 			 			#
; # GLOBAL MEMORY ORGANIZATION (64Ko)				 			#
; # 												 			#
; # |--------|----------|----------|----------|-----------|		#
; # | EEPROM | RAM FREE | MUSICRAM | VIDEORAM |   STACK   | 	#
; # |--------|----------|----------|----------|-----------|		#
; #										 		 	 			#
; # $0000    $8000	    $E800	   $EC00	  $F000  	  $FFFF #
; #													 			#
; ###############################################################

; ############################
; #							 #
; # LCD ADDRESS COORDINATE : #
; #							 #
; # [$80-$87] => 0,0 -> F,0  #
; # [$90-$97] => 0,1 -> F,1  #
; # [$88-$8F] => 0,2 -> F,2  #
; # [$98-$9F] => 0,3 -> F,3  #
; #							 #
; ############################

; ###########################################
; #								  			#
; #  EN RS			D7 D6 D5 D4 D3 D2 D1 D0 #
; #   1  0       	 7  6  5  4  3  2  1  0	#
; # LCD	PORT 0			LCD	PORT 1 			#
; #											#
; ###########################################

; ######## VARIABLE DEFINITION ########

PORT0:			EQU 0x0
PORT1:			EQU 0x1
PORT2:			EQU 0x2
PORT3:			EQU 0x3
PORT4:			EQU 0x4


STACKTOP: 		EQU 0xffff
BASIC_FONCTION: 	EQU %00110000	; 30
EXTENDED_FONCTION: 	EQU %00110100 	; 34

 
;######## FREE RAM ADDRESS - start at $8000 - MAX $E800 ########
LCD_DATA:		EQU $8001	   
LCD_COOX: 		EQU $8002
LCD_COOY:		EQU $8003
CURX:			EQU	$8004
CURY:			EQU $8005
CHAR:			EQU $8006


;DRAW LINE VALUE
Line_X0:		EQU $8007	; 2 byte -> $8008	: used for drawline_16 bits
Line_Y0:		EQU $8009	; 2 byte -> $800A	: used for drawline_16 bits
Line_X1:		EQU $800B	; 2 byte -> $800C	: used for drawline_16 bits
Line_Y1:		EQU $800D	; 2 byte -> $800E	: used for drawline_16 bits 
L_X:			EQU	$800F	; 2 byte -> $8010	: used for drawline_16 bits 
L_Y:			EQU	$8011	; 2 byte -> $8012	: used for drawline_16 bits 
L_DX:			EQU $8013	; 2 byte -> $8014	: used for drawline_16 bits 
L_DY:			EQU $8015	; 2 byte -> $8016	: used for drawline_16 bits 
L_TEMP:			EQU $8017	; 2 byte -> $8018	: used for drawline_16 bits
L_CPT:			EQU $8019	; 2 byte -> $801A	: used for drawline_16 bits
LCD_X16:		EQU $801B	; 2 byte -> $801C 	: used with function checkNputpixel
LCD_Y16:		EQU $801D	; 2 byte -> $801E 	: used with function checkNputpixel
S1:				EQU $801F	; 2 byte -> $8020 	: 16 bits signed value
S2:				EQU $8021	; 2 byte -> $8022 	: 16 bits signed value
ECH:			EQU $8023
V:				EQU $8024  	; 2 byte -> $8025	: 16 bits signed value
BI:				EQU $8026	; 2 byte -> $8027	: 16 bits signed value


; 3D VALUE
MAT3_RESULT:	EQU	$8030	; 6 byte -> $8035 : utiliser pour stocker le resultat de la multiplication matriciel de données 16 bits ([3] * [3-3-3] = [3])
MAT_RESULT:		EQU $8036	; 2 byte -> $8037 : utiliser pour stocker le resultat de la multiplication matriciel de données 16 bits ([3] * [3] = [1])
MatriceProj:	EQU	$8038	; 18 byte -> $804A : matrice [3][3][3] 8.8 byte pour la projection sur l'ecran
MatriceRota:	EQU	$804B	; 18 byte -> $805D : matrice [3][3][3] 8.8 byte pour generer la rotation 3D
ANGLE:			EQU $805E	; 1 byte  : angle de l'objet pour la rotation (indice dans les tables SIN & COS)
Rotated:		EQU $805F	; 6 byte -> $8064 : Matrice resultat de la rotation
DISTANCE:		EQU	$8065	; 2 byte -> $8066 : pour le calcul du scaling
BOUCLE_PTS:		EQU	$8067	; nb boucle to display mesh
MESH:			EQU $806A	; 500 byte -> $825E : MAX objet à afficher
Line_list:		EQU $825F	; 200 byte -> $8327 : MAX liste des lignes a tracer de l'objet MESH
MESH2:			EQU $8328	; 500 byte -> $851C : copie de l'objet MESH à afficher
PointPlan:		EQU $851D	; 200 byte -> $8711 : liste finale des coordonnées x,y (en 8.8) pour affichage point 2D sur l'ecran. 
slideX:			EQU	$8712	; 1 byte : pour le deplacement des objets


; TRIGONOMETRY VALUE
TABLE_SINUS:	EQU $8720	; 512 byte -> $8920 reservés pour la tables Sinus (256 valeurs)
TABLE_COSINUS:	EQU	$8921	; 512 byte -> $8B21 reservés pour la table Cosinus (256 valeurs)
PI_X:			EQU $8B22	; 2 byte -> $8B23 (8+8 bit signed fixed point)   
MULTEMP:		EQU $8B24	; 2 byte -> $8B25 : utiliser pour le calcul des valeurs de sin/cos
TEMP:			EQU $8B26	; 2 byte -> $8B27 (8+8 bit signed fixed point) 


; ELLIPSE
RAYA:			EQU $8B30	; 1 byte  : rayon A de l'ellipse
RAYB:			EQU $8B31	; 1 byte  : rayon B de l'ellipse
CENTERX:		EQU $8B32	; 1 byte  : Centre X de l'ellipse
CENTERY:		EQU $8B33	; 1 byte  : Centre Y de l'ellipse
INCREMENT_ANGLE:EQU $8B34	; 1 byte  : incrementation de l'angle pour le dessin
NB_LOOP:		EQU $8B35	; 1 byte  
ALPHA:			EQU	$8B36	; 1 byte
BETA:			EQU $8B37	; 1 byte
NB_ELLIPSE:		EQU $8B38	; 1 byte  : nb ellipse à afficher
TAB_ELLIPSE_MOV: EQU $8B39	; 128 byte -> $8BB9 : donnees sur les ellipse 



; GREETING PERSPECTIV
EmptyLine:		EQU $8BC0	; 1 byte 
DamierY:		EQU $8BC1	; 1 byte 
DamierX:		EQU $8BC2	; 1 byte 
StartX:			EQU $8BC3	; 1 byte 
StartY:			EQU $8BC4	; 1 byte 
Pixel:			EQU $8BC5	; 1 byte 
SautPixel:		EQU $8BC6	; 2 byte  -> $8BC7  FP (8.8) value
IndiceSautPixel: EQU $8BC8	; 2 byte  -> $8BC9  FP (8.8) value

;DamierX_ABS:	EQU $8BC8	; 1 byte 
;Rang :			EQU $8BC9	; 1 byte 
 
 

VIDEO_RAM: 		EQU $EC00		; Address use to refresh video on the LCD screen : RAM $EC00 -> $EFFF : 1024 byte reserved (screen 128x64 pixel)



HEXA_VAL:	EQU $8B36


; ###################
; # FUNCTION LIST : #
; ###################

; lcd_write_instruction 			; WRITE INSTRUCTION TO LCD Instruction Register 
; lcd_write_data 					; WRITE DATA TO LCD Data Register
; lcd_init							; INITIALISATION DU MODULE ST7920
; lcd_print_chaine  				; PRINT A CHAR TEXT INTO THE LCD IN TEXT MODE
; cls_txt							; CLEAR DISPLAY IN TEXT MODE -> 1.6 ms require
; lcd_enable_graphic				; ACTIVATE GRAPHIC MODE
; empty_ramvideo					; SET (128*64 = 8K pixel  -> 1024 byte) with value zero at address VIDEO_RAM
; draw_display						; DRAW pixel from VIDEO_RAM to the LCD SCREEN
; cls_graphic						; EMPTY VIDEO_RAM and LCD SCREEN
; load_image						; LOAD 128*64 bits (16*8 Byte) of data into the VIDEO_RAM (@in HL)

; delai_1s
; delai_250ms
; delai_40ms
; delai_100us
; delai_2us

; putpixel							; Put a pixel to "1" at the corresponding address into the VIDEO_RAM address
; hidepixel							; Put a pixel to "0" at the corresponding address into the VIDEO_RAM address
; print_cchar						; Print a custom ASCII CHAR (5X6 pixel) from coordinate (CURX,CURY) 
; retour_chariot 					; Retour chariot (CURX,CURY)
; print_line						; Print a line of char in graphic mode from (CURX,CURY) : should not exceed end of line

; F_ADD								; 16 bit Signed Addition 
; F_SUB								; 16bit Signed Substraction 
; F_MUL								; 16 bit Signed Multiplication 
; F_MUL_16							; 16 bit unsigned Multiplication 
; F_DIV								; 16 bit UNSIGNED  Division
; F_DIV_8bit						; 8/8 unsigned Division 

; MATRIX_MUL_3						; Fonction de multiplication de matrice (3)*(3-3-3) utilisant le format Signed Fixed Point (8.8) 
; MATRIX_MUL						; multiplication de matrice [3][3] -> multiplie IX * IY et place le resultat DE dans MAT_RESULT (2 octets)
; draw_point3D						; affiche un point sur l'ecran / PointPlan contient une liste de points (X,Y)
; GenMatRotX						; Genere une matrice Rotation autour de l'axe des X (input = ANGLE (1 octet) ; output = MatriceRota [3] (6 octets) ) 
; GenMatRotY						; Genere une matrice Rotation autour de l'axe des Y (input = ANGLE (1 octet) ; output = MatriceRota [3] (6 octets) ) 
; GenMatRotZ						; Genere une matrice Rotation autour de l'axe des Y (input = ANGLE (1 octet) ; output = MatriceRota [3] (6 octets) ) 
; copy_rotated						; copy IY[3] into IX[3]
; Rotation_Mesh						; effectue une rotation (selon "MatriceRota") de l'objet présent dans "MESH2" de "Angle" degrés radian
; Projection_Mesh_PointPlan			; projete les points 3D de MESH2 en 2D et les copie dans PointPlan
; draw_3D_line_16					; draw line of the mesh on the screen / PointPlan[1+(2*2)n] contient une liste de n points (X,Y) en 8:8 bits
; checkNputpixel					; Vérifier si le point est bien dans l'ecran LCD et affiche un pixel
; drawline_16						; Draw a line in 16 bits, using 16 bits variable :
; GenMatProj						; Update MatriceProj with Scale Value

; GenSINUS							; Calcul le sinus de 64 valeurs 16 bits et le place dans TABLE_SINUS 
; GenCOSINUS						; Calcul le cosinus de 64 valeurs 16 bits et le place dans TABLE_COSINUS

; ellipse							; Genere une ellipse 
; ellipse_dot						; Affiche les ellipses definies dans la liste TAB_ELLIPSE
; ellipse_moving					; Affiche les ellipses definies dans la liste TAB_ELLIPSE_HIGH 

; Affiche_Perspective:				; Display image from ROM into the LCD with prespectiv
; Read_Pixel:						; lit un pixel depuis IMAGE_PERSPECTIVE  et utilise DamierX(0-127) et DamierY(0-n) pour trouver la valeur du pixel
 
; We start in ROM address @ $0000 :

	ORG 0000h
	;FORG 0000h

  


; ############ USER PROGRAM #############

main:
 
	; Initialisation & clear of the LCD :
	call lcd_init

	; DEMO #2 :
	; Set DDRAM address en 0:1 
	ld a,$90
	ld (LCD_DATA),a
	call lcd_write_instruction 		
	ld hl,Text1_TXT
	call lcd_print_chaine

	; Set DDRAM address en 0:2 
	ld a,$88
	ld (LCD_DATA),a
	call lcd_write_instruction 	
	ld hl,Text2_TXT
	call lcd_print_chaine
	call delai_1s 
 	call delai_1s 
	call delai_1s 
 	call delai_1s 

	call cls_txt
	; Activation graphic mode 
	call lcd_enable_graphic	
	call cls_graphic
 


; #### DEMO PART 1: BOOT TEXT ##### 
; #### Duration = 21s 

; First line :
	XOR a
	ld (CURX),a	  
	ld (CURY),a	
	ld HL,DEMO_P1_T1
	call print_line	

	ld b,9
	call part1_affiche_point

	ld HL,DEMO_P1_T0
	call print_line	

; 2nd line :
	XOR a
	ld (CURX),a	 
	ld a,6
	ld (CURY),a
	ld HL,DEMO_P1_T2
	call print_line	


; 3rd line :
	XOR a
	ld (CURX),a	 
	ld a,12
	ld (CURY),a	 

	ld HL,DEMO_P1_T3
	call print_line	

	ld b,9
	call part1_affiche_point

	ld HL,DEMO_P1_T0
	call print_line	
	
; 4th line :	
	XOR a
	ld (CURX),a	 
	ld a,18
	ld (CURY),a	 

	ld HL,DEMO_P1_T4
	call print_line	

	ld b,9
	call part1_affiche_point

	ld HL,DEMO_P1_T0
	call print_line	

; 5th line:
	XOR a
	ld (CURX),a	 
	ld a,24
	ld (CURY),a	 

	ld HL,DEMO_P1_T5
	call print_line	

	ld b,11
	call part1_affiche_point

	ld HL,DEMO_P1_T0
	call print_line	

; 6th line:
	XOR a
	ld (CURX),a	 
	ld a,30
	ld (CURY),a	 

	ld HL,DEMO_P1_T6
	call print_line	

	ld b,7
	call part1_affiche_point

	ld HL,DEMO_P1_T0
	call print_line	

; 7th line :
	XOR a
	ld (CURX),a	 
	ld a,36
	ld (CURY),a
	ld HL,DEMO_P1_T7
	call print_line	
	
; 8th line:
	XOR a
	ld (CURX),a	 
	ld a,42
	ld (CURY),a	 

	ld HL,DEMO_P1_T8
	call print_line	

	ld b,7
	call part1_affiche_point

	ld HL,DEMO_P1_T0
	call print_line		
	
; 9th line :
	XOR a
	ld (CURX),a	 
	ld a,48
	ld (CURY),a
	ld HL,DEMO_P1_T9
	call print_line	 

; 10th line :
	call delai_250ms
	XOR a
	ld (CURX),a	 
	ld a,54
	ld (CURY),a
	ld HL,DEMO_P1_TA
	call print_line		
	call delai_1s
	
 
; #### DEMO PART 2: 3D LOGO MOVING #####
; #### Duration = 8s
  
; INITIALISATION TABLES SIN / COS :
	call GenSINUS
	call GenCOSINUS
 
	;MAT3_RESULT:		Resultat de la multiplication matriciel de données 16 bits ([3] * [3-3-3] = [3])  
	;MatriceRota:	  	18 octets ->  matrice [3][3][3] 8.8 byte pour la rotation 3D
	;MatriceProj:	    18 octets ->  matrice [3][3][3] 8.8 byte pour la projection sur l'ecran	
 	;PointPlan:	   		6 octets ->  coordonnées x,y pour affichage point sur l'ecran
	;Distance:			Distance par defaut , pour la projection/SCALE : $01.00 = normal , <$00.ff = zoom out , >$01.01 = zoom in
 
; INITIALISATION MATRICE:
 	ld DE,Matrice_project
	ld HL,MatriceProj
	ld b,18
	boucle_init_matrice:
		ld a,(DE)
		ld (HL),a
		inc DE
		inc HL	
	djnz boucle_init_matrice


;	ZOOM + ROTATION LOGO  :

; copy object into MESH : 
	ld BC,500						; LOGO size (500 MAX)
	ld DE,MESH
	ld HL,LOGO
	LDIR  ; LDIR : Cette instruction exécute la copie mémoire ( d'un octet de (HL) vers (DE), puis incrémente HL,DE et décrémente BC) tant que BC est supérieur à zéro
; copy nb_line_in_object into Line_list :
	ld BC,200						; value  (200 MAX)
	ld DE,Line_list
	ld HL,LOGO_line
	LDIR		

	call cls_graphic
	
	call Display_LOGO_3D_RY_IN
	
	call Display_LOGO_3D_RY	


	call delai_250ms
	call delai_250ms
	call delai_250ms	
	
	call cls_graphic	


; #### DEMO PART 3: 3D DOT TUNNEL #####
; #### Duration = 15s

	XOR a
	ld (ALPHA),a
	ld (BETA),a
	ld a,4	 	
	ld (INCREMENT_ANGLE),a
	
	ld b,32								; nb rotations/frames   43 frames = 15s
	boucle_ellipse_rotation:
		push BC	
			call empty_ramvideo
			call ellipse_dot
			
			; increment alpha +2
			ld a,(ALPHA)
			add 8
			ld (ALPHA),a
	
			; increment beta +8
			ld a,(BETA)
			add 32
			ld (BETA),a			
		
			call draw_display 
		pop BC
	djnz boucle_ellipse_rotation


	call delai_250ms
	call delai_250ms 


; #### DEMO PART 4: Ellipses sliding #####
; #### Duration = 15s
  
	ld a,5		 	
	ld (INCREMENT_ANGLE),a
	
	; copie de TAB_ELLIPSE_HIGH vers TAB_ELLIPSE_MOV 
	ld BC,128							; size MAX
	ld HL,TAB_ELLIPSE_HIGH
	ld DE,TAB_ELLIPSE_MOV
	LDIR  ; LDIR : Cette instruction exécute la copie mémoire ( d'un octet de (HL) vers (DE), puis incrémente HL,DE et décrémente BC) tant que BC est supérieur à zéro	
	
	ld b,47								; nb rotations/frames   47 frames = 15s
	boucle_ellipse_cycle_debut:
		push BC	
			call empty_ramvideo
			call ellipse_moving			
			call draw_display 
		pop BC
	djnz boucle_ellipse_cycle_debut
 
 
	call delai_250ms
	call delai_250ms  
	

; #### DEMO PART 5: 3D TORE MOVING / BOUNCING EDGE OF SCREEN #####
; #### Duration = 15s


; display simple TORE 1 :

; INITIALISATION MATRICE:
	ld BC,18	 
	ld HL,Matrice_project	
	ld DE,MatriceProj
	LDIR    	

; copy object into MESH : 
	ld BC,500						; TORE1 size (500 MAX)
	ld HL,TORE1
	ld DE,MESH
	LDIR  ; LDIR : Cette instruction exécute la copie mémoire ( d'un octet de (HL) vers (DE), puis incrémente HL,DE et décrémente BC) tant que BC est supérieur à zéro
; copy nb_line_in_object into Line_list :
	ld BC,200						; value  (200 MAX)
	ld HL,TORE1_line
	ld DE,Line_list
	LDIR		

	call cls_graphic
 	
	; Distance init resized :
	ld a,2
	ld (DISTANCE),a
	XOR a
	ld (DISTANCE+1),a	 

	call GenMatProj	
 
	call Display_TORE_3D_ROTATION
 	


; display simple TORE  2 :

; INITIALISATION MATRICE:
	ld BC,18	 
	ld HL,Matrice_project	
	ld DE,MatriceProj
	LDIR    

; copy object into MESH : 
	ld BC,500						; TORE1 size (500 MAX)
	ld HL,TORE2
	ld DE,MESH
	LDIR  ; LDIR : Cette instruction exécute la copie mémoire ( d'un octet de (HL) vers (DE), puis incrémente HL,DE et décrémente BC) tant que BC est supérieur à zéro
; copy nb_line_in_object into Line_list :
	ld BC,200						; value  (200 MAX)
	ld HL,TORE2_line
	ld DE,Line_list
	LDIR 

	; Distance init resized :
	ld a,2
	ld (DISTANCE),a
	ld a,128
	ld (DISTANCE+1),a	 

	call GenMatProj	
 
	call Display_TORE_3D_ROTATION 	 



; display TORE 3 :

; INITIALISATION MATRICE:
	ld BC,18	 
	ld HL,Matrice_project	
	ld DE,MatriceProj
	LDIR    	
	
; copy object into MESH : 
	ld BC,500						; TORE1 size (500 MAX)
	ld HL,TORE3
	ld DE,MESH
	LDIR  ; LDIR : Cette instruction exécute la copie mémoire ( d'un octet de (HL) vers (DE), puis incrémente HL,DE et décrémente BC) tant que BC est supérieur à zéro
; copy nb_line_in_object into Line_list :
	ld BC,200						; value  (200 MAX)
	ld HL,TORE3_line
	ld DE,Line_list
	LDIR

	; Distance init resized :
	ld a,2
	ld (DISTANCE),a
	ld a,128
	ld (DISTANCE+1),a	 

	call GenMatProj	
 
	call Display_TORE_3D_ROTATION 


	call delai_250ms
	call delai_250ms
	call delai_250ms
	
; 	call transition_animation

; #### DEMO FINAL PART: TEXT SCROOLING #####
; #### Duration = less than 55 sec

 
	call cls_graphic
		XOR a
		ld (EmptyLine),a
		ld a,1
		ld (DamierY),a							; on incrementera de 4 ligne à chaque appel pour l'effet scrolling
		ld c,a
	ld b,63										; nb ligne a afficher. 126
	boucle_scrooling:
		call Affiche_Perspective
		call draw_display  
		inc c
		inc c
		inc c
		inc c
		ld a,c 
		ld (DamierY),a	
	djnz boucle_scrooling


call delai_1s 
call draw_display
	
HALT




;#######################################
;##############  USER DATA  ############
;####################################### 

Text1_TXT:
	db	9,  "      Z80" 
Text2_TXT: 
	db	11, "    DEMO #2" 

DEMO_P1_T0:
	db 4,	"DONE"
DEMO_P1_T1:
	db 12,	"RAM 32K TEST"
DEMO_P1_T2:
	db 21,	"CPU Z80 CORE DETECTED"
DEMO_P1_T3:
	db 12,	"BIOS LOADING"
DEMO_P1_T4:
	db 12,	"MBR STARTING"
DEMO_P1_T5:
	db 10,	"BOOTLOADER"
DEMO_P1_T6:
	db 14,	"KERNEL LOADING"
DEMO_P1_T7:
	db 22,	"SP-DOS V3.07 INSTALLED"
DEMO_P1_T8:
	db 14,	"INITIALIZATION"
DEMO_P1_T9:
	db 23,	"BOOT SEQUENCE COMPLETED"
DEMO_P1_TA:
	db 24,	"STARTING ENCOM INTERFACE"	




LOGO:									; LOGO System Shock : 20 sommets (X,Y,Z)	
	db 45 								; nombre de points  (on a 500 octets -> 83 points max)
										; $FF,$80 == -0.5  ; $FF,$00 == -1 ; 0,75 == $00$C0 ; -0.75 == $FF,$40

 
	db $FD,$00, $05,$00, $00,$00			;-3.0,  5.0,  0.0
	db $03,$00, $05,$00, $00,$00			; 3.0,  5.0,  0.0	
	db $07,$00, $02,$00, $00,$00			; 7.0,  2.0,  0.0
	db $02,$00, $FB,$00, $00,$00			; 2.0, -5.0,  0.0		
	db $FE,$00, $FB,$00, $00,$00			;-2.0, -5.0,  0.0	
	db $F9,$00, $02,$00, $00,$00			;-7.0,  2.0,  0.0	-> 6 	
	
	
	db $FD,$00, $04,$00, $00,$00			;-3.0,  4.0,  0.0	
	db $03,$40, $04,$00, $00,$00			; 3.25,  4.0,  0.0	
	db $02,$C0, $03,$80, $00,$00			; 2.75,  3.5,  0.0	
	db $FD,$80, $03,$80, $00,$00			;-2.5,  3.5,  0.0	-> 10 

	db $FE,$00, $03,$00, $00,$00			;-2.0,  3.0,  0.0	
	db $02,$40, $03,$00, $00,$00			; 2.25,  3.0,  0.0	
	db $01,$C0, $02,$80, $00,$00			; 1.75,  2.5,  0.0	
	db $FE,$80, $02,$80, $00,$00			;-1.5,  2.5,  0.0	-> 14 	

	db $FF,$00, $02,$00, $00,$00			;-1.0,  2.0,  0.0	
	db $01,$40, $02,$00, $00,$00			; 1.25,  2.0,  0.0	
	db $00,$C0, $01,$80, $00,$00			; 0.75,  1.5,  0.0	
	db $FF,$80, $01,$80, $00,$00			;-0.5,  1.5,  0.0	-> 18 	


	db $FA,$00, $01,$C0, $00,$00			; -6.0, 1.75,  0.0	
	db $FB,$00, $01,$80, $00,$00			; -5.0,  1.5,  0.0			
	db $FE,$80, $FC,$80, $00,$00			; -1.5, -3.5,  0.0
	db $FE,$80, $FB,$80, $00,$00			; -1.5, -4.5,  0.0	-> 22 

	db $FB,$C0, $01,$40, $00,$00			;-4.75, 1.25,  0.0	
	db $FC,$C0, $01,$00, $00,$00			;-3.75,  1.0,  0.0			
	db $FF,$00, $FD,$80, $00,$00			; -1.0, -2.5,  0.0
	db $FF,$00, $FC,$80, $00,$00			; -1.0, -3.5,  0.0	-> 26 

	db $FD,$80, $00,$C0, $00,$00			; -2.5, 0.75,  0.0	
	db $FE,$80, $00,$50, $00,$00			; -1.5,  0.5,  0.0			
	db $FF,$80, $FE,$80, $00,$00			; -0.5, -1.5,  0.0
	db $FF,$80, $FD,$80, $00,$00			; -0.5, -2.5,  0.0	-> 30 


	db $06,$00, $01,$C0, $00,$00			; 6.0, 1.75,  0.0	
	db $05,$00, $01,$80, $00,$00			; 5.0,  1.5,  0.0			
	db $01,$80, $FC,$80, $00,$00			; 1.5, -3.5,  0.0
	db $01,$80, $FB,$80, $00,$00			; 1.5, -4.5,  0.0	-> 34

	db $04,$40, $01,$40, $00,$00			; 4.25,  1.25,  0.0	
	db $03,$40, $01,$00, $00,$00			; 3.25,   1.0,  0.0			
	db $01,$00, $FD,$80, $00,$00			; 1.0,  -2.5,  0.0
	db $01,$00, $FC,$80, $00,$00			; 1.0,  -3.5,  0.0	-> 38 

	db $02,$80, $00,$C0, $00,$00			; 2.5, 0.75,  0.0	
	db $01,$80, $00,$50, $00,$00			; 1.5,  0.5,  0.0			
	db $00,$80, $FE,$80, $00,$00			; 0.5, -1.5,  0.0
	db $00,$80, $FD,$80, $00,$00			; 0.5, -2.5,  0.0	-> 42 

 
	db $00,$00, $01,$40, $00,$00			; 0.0,  1.25,  0.0	
	db $00,$C0, $FF,$C0, $00,$00			; 0.75, -0.25,  0.0			
	db $FF,$40, $FF,$C0, $00,$00			;-0.75, -0.25,  0.0 


LOGO_line:								; liste des points à relier entre eux 
	db 45								; nombre de lignes (200 octets = 100 lignes)  Max 255/4 = 64 couples de valeurs
	db 1,2, 2,3, 3,4, 4,5, 5,6, 6,1 
	db 7,8, 8,9, 9,10, 10,7
	db 11,12, 12,13, 13,14, 14,11
	db 15,16, 16,17, 17,18, 18,15
	db 19,20, 20,21, 21,22, 22,19
	db 23,24, 24,25, 25,26, 26,23
	db 27,28, 28,29, 29,30, 30,27
	db 31,32, 32,33, 33,34, 34,31
	db 35,36, 36,37, 37,38, 38,35
	db 39,40, 40,41, 41,42, 42,39
	db 43,44, 44,45, 45,43


TAB_ELLIPSE:							; #NB , Cx , Cy , Ra , Rb
	db 14
	db 63,31,60,30
	db 63,31,56,28
	db 63,31,52,26
	db 63,31,48,24
	db 63,31,44,22
	db 63,31,40,20
	db 63,31,36,18
	db 63,31,32,16
	db 63,31,28,14
	db 63,31,24,12 
	db 63,31,20,10
	db 63,31,16,8
	db 63,31,12,6
	db 63,31,8,4
	

TAB_ELLIPSE_HIGH:							; LISTE #NB ,[ Cx ,  Cy , direction(0 = monte  1=descend ), vitesse(0-10), Ra , Angle , Rb, ]+
											; lorsque Cy=54 ,  direction = 0 (going up)
											; lorsque Cy=12 ,  direction = 1 (going down)
											; Angle : Ra + (sin(Angle))*30 
	db 10
	db 63,54,0,2,8,48,40
	db 63,54,0,3,8,128,40
	db 63,54,0,4,8,16,40
	db 63,52,1,4,8,220,40
	db 63,52,1,3,8,160,40
	db 63,52,1,2,8,240,40
	db 63,54,0,3,8,112,40
	db 63,52,1,3,8,192,40
	db 63,53,1,1,8,0,40
	db 63,52,0,1,8,96,40
	;db 63,52,1,1,8,36,38
	;db 63,50,0,3,8,132,38


TORE1:									; TORE1  : 16 sommets (X,Y,Z)	
	db 16 								; nombre de points  (on a 500 octets -> 83 points max)
										; $FF,$80 == -0.5  ; $FF,$00 == -1 ; 0,75 == $00$C0 ; -0.75 == $FF,$40

 
	db $FC,$00, $04,$00, $04,$00			;-2.0,  2.0,  2.0
	db $04,$00, $04,$00, $04,$00			; 2.0,  2.0,  2.0	
	db $04,$00, $FC,$00, $04,$00			; 2.0, -2.0,  2.0
	db $FC,$00, $FC,$00, $04,$00			;-2.0, -2.0,  2.0	-> 4	
	
	db $FA,$00, $06,$00, $00,$00			;-3.0,  3.0,  0.0
	db $06,$00, $06,$00, $00,$00			; 3.0,  3.0,  0.0	
	db $06,$00, $FA,$00, $00,$00			; 3.0, -3.0,  0.0
	db $FA,$00, $FA,$00, $00,$00			;-3.0, -3.0,  0.0	-> 8
	
	db $FC,$00, $04,$00, $FC,$00			;-2.0,  2.0,  -2.0
	db $04,$00, $04,$00, $FC,$00			; 2.0,  2.0,  -2.0	
	db $04,$00, $FC,$00, $FC,$00			; 2.0, -2.0,  -2.0
	db $FC,$00, $FC,$00, $FC,$00			;-2.0, -2.0,  -2.0	-> 12	

	db $FE,$00, $02,$00, $00,$00			;-1.0,  1.0,  0.0
	db $02,$00, $02,$00, $00,$00			; 1.0,  1.0,  0.0	
	db $02,$00, $FE,$00, $00,$00			; 1.0, -1.0,  0.0
	db $FE,$00, $FE,$00, $00,$00			;-1.0, -1.0,  0.0	-> 16	
	
	
TORE1_line:								; liste des points à relier entre eux 
	db 32								; nombre de lignes (200 octets = 100 lignes)  Max 255/4 = 64 couples de valeurs
	db 1,2, 2,3, 3,4, 4,1
	db 5,6, 6,7, 7,8, 8,5
	db 9,10, 10,11, 11,12, 12,9
	db 13,14, 14,15, 15,16, 16,13
	db 1,5, 5,9, 9,13, 13,1
	db 2,6, 6,10, 10,14, 14,2
	db 3,7, 7,11, 11,15, 15,3
	db 4,8, 8,12, 12,16, 16,4
	
	

TORE2:									; TORE3  : 24 sommets (X,Y,Z)	
	db 24 								; nombre de points  (on a 500 octets -> 83 points max)
										; $FF,$80 == -0.5  ; $FF,$00 == -1 ; 0,75 == $00$C0 ; -0.75 == $FF,$40

 
	db $FE,$00, $04,$00, $02,$00			;-2.0,  4.0,  2.0
	db $02,$00, $04,$00, $02,$00			; 2.0,  4.0,  2.0	
	db $05,$00, $00,$00, $02,$00			; 5.0,  0.0,  2.0
	db $02,$00, $FC,$00, $02,$00			; 2.0, -4.0,  2.0	
	db $FE,$00, $FC,$00, $02,$00			;-2.0, -4.0,  2.0
	db $FB,$00, $00,$00, $02,$00			;-5.0,  0.0,  2.0	-> 6

	db $FD,$00, $06,$00, $00,$00			;-3.0,  6.0,  0.0
	db $03,$00, $06,$00, $00,$00			; 3.0,  6.0,  0.0	
	db $07,$00, $00,$00, $00,$00			; 7.0,  0.0,  0.0
	db $03,$00, $FA,$00, $00,$00			; 3.0, -6.0,  0.0	
	db $FD,$00, $FA,$00, $00,$00			;-3.0, -6.0,  0.0
	db $F9,$00, $00,$00, $00,$00			;-7.0,  0.0,  0.0	-> 12

	db $FE,$00, $04,$00, $FE,$00			;-2.0,  4.0,  -2.0
	db $02,$00, $04,$00, $FE,$00			; 2.0,  4.0,  -2.0	
	db $05,$00, $00,$00, $FE,$00			; 5.0,  0.0,  -2.0
	db $02,$00, $FC,$00, $FE,$00			; 2.0, -4.0,  -2.0	
	db $FE,$00, $FC,$00, $FE,$00			;-2.0, -4.0,  -2.0
	db $FB,$00, $00,$00, $FE,$00			;-5.0,  0.0,  -2.0	-> 18	 

	db $FF,$00, $02,$00, $00,$00			;-1.0,  2.0,  0.0
	db $01,$00, $02,$00, $00,$00			; 1.0,  2.0,  0.0	
	db $03,$00, $00,$00, $00,$00			; 3.0,  0.0,  0.0
	db $01,$00, $FE,$00, $00,$00			; 1.0, -2.0,  0.0	
	db $FF,$00, $FE,$00, $00,$00			;-1.0, -2.0,  0.0
	db $FD,$00, $00,$00, $00,$00			;-3.0,  0.0,  0.0	-> 24	 
	
	
TORE2_line:								; liste des points à relier entre eux 
	db 48								; nombre de lignes (200 octets = 100 lignes)  Max 255/4 = 64 couples de valeurs
	db 1,2, 2,3, 3,4, 4,5, 5,6, 6,1 
	db 7,8, 8,9, 9,10, 10,11, 11,12, 12,7
	db 13,14, 14,15, 15,16, 16,17, 17,18, 18,13
	db 19,20, 20,21, 21,22, 22,23, 23,24, 24,19
	db 1,7, 7,13, 13,19, 19,1
	db 2,8, 8,14, 14,20, 20,2
	db 3,9, 9,15, 15,21, 21,3
	db 4,10, 10,16, 16,22, 22,4
	db 5,11, 11,17, 17,23, 23,5
	db 6,12, 12,18, 18,24, 24,6
	

TORE3:									; TORE3  : 32 sommets (X,Y,Z)	
	db 32 								; nombre de points  (on a 500 octets -> 83 points max)
										; $FF,$80 == -0.5  ; $FF,$00 == -1 ; 0,75 == $00$C0 ; -0.75 == $FF,$40

 
	db $00,$00, $05,$00, $02,$00			; 0.0,  5.0,  2.0
	db $03,$80, $03,$80, $02,$00			; 3.5,  3.5,  2.0	
	db $05,$00, $00,$00, $02,$00			; 5.0,  0.0,  2.0
	db $03,$80, $FC,$80, $02,$00			; 3.5, -3.5,  2.0	
	db $00,$00, $FB,$00, $02,$00			; 0.0, -5.0,  2.0
	db $FC,$80, $FC,$80, $02,$00			;-3.5, -3.5,  2.0 
 	db $FB,$00, $00,$00, $02,$00			;-5.0,  0.0,  2.0
	db $FC,$80, $03,$80, $02,$00			;-3.5,  3.5,  2.0	-> 8

	db $00,$00, $07,$00, $00,$00			; 0.0,  7.0,  0.0
	db $05,$00, $05,$00, $00,$00			; 5.0,  5.0,  0.0	
	db $07,$00, $00,$00, $00,$00			; 7.0,  0.0,  0.0
	db $05,$00, $FB,$00, $00,$00			; 5.0, -5.0,  0.0	
	db $00,$00, $F9,$00, $00,$00			; 0.0, -7.0,  0.0
	db $FB,$00, $FB,$00, $00,$00			;-5.0, -5.0,  0.0 
 	db $F9,$00, $00,$00, $00,$00			;-7.0,  0.0,  0.0
	db $FB,$00, $05,$00, $00,$00			;-5.0,  5.0,  0.0	-> 16

	db $00,$00, $05,$00, $FE,$00			; 0.0,  5.0,  -2.0
	db $03,$80, $03,$80, $FE,$00			; 3.5,  3.5,  -2.0	
	db $05,$00, $00,$00, $FE,$00			; 5.0,  0.0,  -2.0
	db $03,$80, $FC,$80, $FE,$00			; 3.5, -3.5,  -2.0	
	db $00,$00, $FB,$00, $FE,$00			; 0.0, -5.0,  -2.0
	db $FC,$80, $FC,$80, $FE,$00			;-3.5, -3.5,  -2.0 
 	db $FB,$00, $00,$00, $FE,$00			;-5.0,  0.0,  -2.0
	db $FC,$80, $03,$80, $FE,$00			;-3.5,  3.5,  -2.0	-> 24	

	db $00,$00, $02,$00, $00,$00			; 0.0,  2.0,  0.0
	db $02,$00, $02,$00, $00,$00			; 2.0,  2.0,  0.0	
	db $03,$00, $00,$00, $00,$00			; 3.0,  0.0,  0.0
	db $02,$00, $FE,$00, $00,$00			; 2.0, -2.0,  0.0	
	db $00,$00, $FD,$00, $00,$00			; 0.0, -3.0,  0.0
	db $FE,$00, $FE,$00, $00,$00			;-2.0, -2.0,  0.0 
 	db $FD,$00, $00,$00, $00,$00			;-3.0,  0.0,  0.0
	db $FE,$00, $02,$00, $00,$00			;-2.0,  2.0,  0.0	-> 32	
	
	
TORE3_line:								; liste des points à relier entre eux 
	db 64								; nombre de lignes (200 octets = 100 lignes)  Max 255/4 = 64 couples de valeurs
	db 1,2, 2,3, 3,4, 4,5, 5,6, 6,7, 7,8, 8,1
	db 9,10, 10,11, 11,12, 12,13, 13,14, 14,15, 15,16, 16,9
	db 17,18, 18,19, 19,20, 20,21, 21,22, 22,23, 23,24, 24,17
	db 25,26, 26,27, 27,28, 28,29, 29,30, 30,31, 31,32, 32,25 
	db 1,9, 9,17, 17,25, 25,1
	db 2,10, 10,18, 18,26, 26,2
	db 3,11, 11,19, 19,27, 27,3
	db 4,12, 12,20, 20,28, 28,4
	db 5,13, 13,21, 21,29, 29,5
	db 6,14, 14,22, 22,30, 30,6
	db 7,15, 15,23, 23,31, 31,7
	db 8,16, 16,24, 24,32, 32,8
	
	

IMAGE_PERSPECTIVE:	
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x01, 0xFF, 0xE0, 0x3C, 0x01, 0xE0, 0x00, 0x30, 0x00, 0xFF, 0xC0, 0xC0, 0x80, 0x07, 0xE0, 0x00
db 0x03, 0xFF, 0xF0, 0xFE, 0x07, 0xF0, 0x00, 0x7C, 0x00, 0xFF, 0xE1, 0xC1, 0xC0, 0x0F, 0xF8, 0x00,0x01, 0xFF, 0xE1, 0xFF, 0x0F, 0xF8, 0x00, 0x7F, 0x80, 0xFF, 0xC1, 0xE1, 0xC0, 0x1F, 0xFC, 0x00
db 0x00, 0x07, 0xC1, 0xC7, 0x0E, 0x38, 0x00, 0x77, 0xC0, 0xE0, 0x01, 0xE1, 0xC0, 0x3C, 0x1C, 0x00,0x00, 0x0F, 0x81, 0xC7, 0x0E, 0x1C, 0x00, 0x71, 0xE0, 0xE0, 0x03, 0xE3, 0xE0, 0x78, 0x0E, 0x00
db 0x00, 0x0F, 0x01, 0xC7, 0x1C, 0x1C, 0x00, 0x70, 0x70, 0xE0, 0x03, 0xE3, 0xE0, 0x70, 0x0E, 0x00,0x00, 0x1E, 0x01, 0xFE, 0x1C, 0x1C, 0x00, 0x70, 0x38, 0xE0, 0x03, 0xE3, 0xE0, 0x70, 0x0E, 0x00
db 0x00, 0x1C, 0x00, 0xFC, 0x1C, 0x1C, 0x00, 0x70, 0x1C, 0xFF, 0xC3, 0xF3, 0xE0, 0xE0, 0x0E, 0x00,0x00, 0x3C, 0x01, 0xFF, 0x1C, 0x1C, 0x00, 0x70, 0x1C, 0xFF, 0xE3, 0x77, 0xE0, 0xE0, 0x0E, 0x00
db 0x00, 0x78, 0x01, 0xC7, 0x1C, 0x1C, 0x00, 0x70, 0x1C, 0xFF, 0xC7, 0x77, 0x60, 0xE0, 0x0E, 0x00,0x00, 0x70, 0x03, 0x83, 0x9C, 0x1C, 0x00, 0x70, 0x1C, 0xE0, 0x07, 0x7F, 0x70, 0xE0, 0x1C, 0x00
db 0x00, 0xF0, 0x03, 0x83, 0x9C, 0x1C, 0x00, 0x70, 0x1C, 0xE0, 0x07, 0x3E, 0x70, 0xE0, 0x1C, 0x00,0x00, 0xE0, 0x03, 0x83, 0x8E, 0x38, 0x00, 0x70, 0x38, 0xE0, 0x0F, 0x3E, 0x70, 0xF0, 0x3C, 0x00
db 0x01, 0xC0, 0x03, 0xC7, 0x8E, 0x38, 0x00, 0x70, 0x78, 0xE0, 0x0E, 0x3E, 0x30, 0x78, 0x78, 0x00,0x01, 0xFF, 0xE3, 0xFF, 0x0F, 0xF8, 0x00, 0x7F, 0xF0, 0xFF, 0xCE, 0x1E, 0x38, 0x3F, 0xF0, 0x00
db 0x03, 0xFF, 0xF1, 0xFF, 0x07, 0xF0, 0x00, 0x7F, 0xE0, 0x7F, 0xEE, 0x1C, 0x38, 0x1F, 0xE0, 0x00,0x01, 0xFF, 0xE0, 0x7C, 0x03, 0xE0, 0x00, 0x1F, 0x80, 0x3F, 0xCE, 0x1C, 0x18, 0x0F, 0xC0, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x03, 0xE0, 0x1E, 0x00, 0xF8, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x07, 0xF0, 0x7F, 0x01, 0xFC, 0x0F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x0F, 0xF8, 0xFF, 0x83, 0xFE, 0x1F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x1E, 0x38, 0xE3, 0x87, 0x8E, 0x3F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x18, 0x38, 0xE1, 0xC6, 0x0E, 0x3F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x39, 0xC1, 0xC0, 0x0E, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x71, 0xC1, 0xC0, 0x1C, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x01, 0xF1, 0xC1, 0xC0, 0x7C, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x03, 0xE1, 0xC1, 0xC0, 0xF8, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x07, 0x81, 0xC1, 0xC1, 0xE0, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x0F, 0x01, 0xC1, 0xC3, 0xC0, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x1E, 0x01, 0xC1, 0xC7, 0x80, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x1C, 0x00, 0xE3, 0x87, 0x00, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x1F, 0xF0, 0xE3, 0x87, 0xFC, 0x3F, 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x1F, 0xF8, 0xFF, 0x87, 0xFE, 0x3F, 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x1F, 0xF8, 0x7F, 0x07, 0xFE, 0x3F, 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x01, 0xFF, 0xDC, 0x38, 0x0E, 0x07, 0x03, 0x1C, 0x38, 0xF8, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x01, 0xFF, 0xDC, 0x38, 0x1F, 0x07, 0x83, 0x1C, 0x71, 0xFC, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x1C, 0x1C, 0x38, 0x1B, 0x07, 0xC3, 0x1C, 0xF3, 0x84, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x1C, 0x1C, 0x38, 0x1B, 0x86, 0xC3, 0x1C, 0xE3, 0x80, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x1C, 0x1C, 0x38, 0x3B, 0x86, 0xE3, 0x1D, 0xC3, 0xC0, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x1C, 0x1F, 0xF8, 0x31, 0x86, 0x63, 0x1F, 0x81, 0xF0, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x1C, 0x1F, 0xF8, 0x31, 0xC6, 0x73, 0x1F, 0x80, 0xFC, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x1C, 0x1C, 0x38, 0x71, 0xC6, 0x33, 0x1D, 0xC0, 0x3E, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x1C, 0x1C, 0x38, 0x7F, 0xC6, 0x1B, 0x1D, 0xE0, 0x0E, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x1C, 0x1C, 0x38, 0x7F, 0xE6, 0x1B, 0x1C, 0xE0, 0x0E, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x1C, 0x1C, 0x38, 0xE0, 0xE6, 0x0F, 0x1C, 0x73, 0x1E, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x1C, 0x1C, 0x38, 0xC0, 0xE6, 0x0F, 0x1C, 0x7B, 0xFC, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x1C, 0x1C, 0x39, 0xC0, 0x76, 0x07, 0x1C, 0x39, 0xF8, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0xFE, 0x03, 0xF0, 0xFE, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0xFE, 0x0F, 0xF8, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0xE0, 0x1E, 0x1C, 0xE3, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0xE0, 0x1C, 0x1E, 0xE3, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0xE0, 0x38, 0x0E, 0xE3, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0xE0, 0x38, 0x0E, 0xE7, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0xFE, 0x38, 0x0E, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0xFE, 0x38, 0x0E, 0xFE, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0xE0, 0x38, 0x0E, 0xE7, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0xE0, 0x3C, 0x1C, 0xE3, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0xE0, 0x1C, 0x3C, 0xE3, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0xE0, 0x0F, 0xF8, 0xE1, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0xE0, 0x07, 0xE0, 0xE1, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x03, 0x83, 0x83, 0x83, 0x83, 0xFF, 0x87, 0xCE, 0x1C, 0x71, 0xC0, 0xC0, 0x7E, 0x00, 0x00,0x00, 0x01, 0xC3, 0x87, 0x07, 0xC3, 0xFF, 0x9F, 0xEE, 0x1C, 0x71, 0xE0, 0xC1, 0xFF, 0x00, 0x00
db 0x00, 0x01, 0xC3, 0xC7, 0x06, 0xC0, 0x38, 0x3C, 0x2E, 0x1C, 0x71, 0xF0, 0xC3, 0xC1, 0x00, 0x00,0x00, 0x01, 0xC7, 0xC7, 0x06, 0xE0, 0x38, 0x38, 0x0E, 0x1C, 0x71, 0xB0, 0xC3, 0x80, 0x00, 0x00
db 0x00, 0x01, 0xC6, 0xC7, 0x0E, 0xE0, 0x38, 0x70, 0x0E, 0x1C, 0x71, 0xB8, 0xC7, 0x00, 0x00, 0x00,0x00, 0x00, 0xE6, 0xC6, 0x0C, 0x60, 0x38, 0x70, 0x0F, 0xFC, 0x71, 0x98, 0xC7, 0x00, 0x00, 0x00
db 0x00, 0x00, 0xE6, 0xEE, 0x0C, 0x70, 0x38, 0x70, 0x0F, 0xFC, 0x71, 0x9C, 0xC7, 0x1F, 0x00, 0x00,0x00, 0x00, 0xEE, 0xEE, 0x1C, 0x70, 0x38, 0x70, 0x0E, 0x1C, 0x71, 0x8C, 0xC7, 0x1F, 0x00, 0x00
db 0x00, 0x00, 0xEC, 0x6C, 0x1F, 0xF0, 0x38, 0x70, 0x0E, 0x1C, 0x71, 0x86, 0xC7, 0x07, 0x00, 0x00,0x00, 0x00, 0x6C, 0x6C, 0x1F, 0xF8, 0x38, 0x78, 0x0E, 0x1C, 0x71, 0x86, 0xC3, 0x87, 0x00, 0x00
db 0x00, 0x00, 0x7C, 0x7C, 0x38, 0x38, 0x38, 0x3C, 0x2E, 0x1C, 0x71, 0x83, 0xC3, 0xC7, 0x00, 0x00,0x00, 0x00, 0x7C, 0x7C, 0x30, 0x38, 0x38, 0x1F, 0xEE, 0x1C, 0x71, 0x83, 0xC1, 0xFF, 0x00, 0x00
db 0x00, 0x00, 0x38, 0x38, 0x70, 0x1C, 0x38, 0x0F, 0xCE, 0x1C, 0x71, 0x81, 0xC0, 0x7E, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x03, 0x3F, 0x06, 0x18, 0xF0, 0xC6, 0x06, 0x06, 0x63, 0x3F, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x03, 0x30, 0x06, 0x19, 0x98, 0xC6, 0x06, 0x06, 0x66, 0x30, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x03, 0x30, 0x03, 0x33, 0x0C, 0xC6, 0x06, 0x06, 0x6C, 0x30, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x03, 0x30, 0x01, 0xE3, 0x0C, 0xC6, 0x06, 0x06, 0x6C, 0x30, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x03, 0x30, 0x01, 0xE3, 0x0C, 0xC6, 0x06, 0x06, 0x7C, 0x3F, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x03, 0x3F, 0x00, 0xC3, 0x0C, 0xC6, 0x06, 0x06, 0x76, 0x30, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x03, 0x30, 0x00, 0xC3, 0x0C, 0xC6, 0x06, 0x06, 0x66, 0x30, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x03, 0x30, 0x00, 0xC3, 0x0C, 0xC6, 0x06, 0x06, 0x66, 0x30, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x03, 0x30, 0x00, 0xC1, 0x98, 0xC6, 0x06, 0x06, 0x63, 0x30, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x03, 0x30, 0x00, 0xC0, 0xF0, 0x7C, 0x07, 0xE6, 0x63, 0x3F, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x3F, 0x18, 0x1F, 0x87, 0x07, 0xC7, 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x31, 0x98, 0x18, 0x07, 0x0C, 0x66, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x31, 0x98, 0x18, 0x0D, 0x8C, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x31, 0x98, 0x18, 0x0D, 0x8E, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x31, 0x98, 0x1F, 0x8D, 0x87, 0x87, 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x3F, 0x18, 0x18, 0x18, 0xC3, 0xC6, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x30, 0x18, 0x18, 0x18, 0xC0, 0xE6, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x30, 0x18, 0x18, 0x1F, 0xC0, 0x66, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x30, 0x18, 0x18, 0x30, 0x6C, 0x66, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x30, 0x1F, 0x9F, 0xB0, 0x67, 0xC7, 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x01, 0xF1, 0x8C, 0xFC, 0x3E, 0x0F, 0x9F, 0x8C, 0xFC, 0x7E, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x03, 0x19, 0x8C, 0xC6, 0x63, 0x18, 0xD8, 0xCC, 0xC6, 0x60, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x03, 0x01, 0x8C, 0xC6, 0x60, 0x30, 0x18, 0xCC, 0xC6, 0x60, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x03, 0x81, 0x8C, 0xC6, 0x70, 0x30, 0x18, 0xCC, 0xC6, 0x60, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x01, 0xE1, 0x8C, 0xFC, 0x3C, 0x30, 0x18, 0xCC, 0xFC, 0x7E, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0xF1, 0x8C, 0xC6, 0x1E, 0x30, 0x1F, 0x8C, 0xC6, 0x60, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x39, 0x8C, 0xC6, 0x07, 0x30, 0x19, 0x8C, 0xC6, 0x60, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x19, 0x8C, 0xC6, 0x03, 0x30, 0x18, 0xCC, 0xC6, 0x60, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x03, 0x19, 0x8C, 0xC6, 0x63, 0x18, 0xD8, 0xCC, 0xC6, 0x60, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x01, 0xF0, 0xF8, 0xFC, 0x3E, 0x0F, 0x98, 0x6C, 0xFC, 0x7E, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x0D, 0xFE, 0xCF, 0x80, 0xFC, 0xFC, 0x7E, 0x7E, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x0C, 0x30, 0xD8, 0xC0, 0xC0, 0xC6, 0x60, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x0C, 0x30, 0xD8, 0x00, 0xC0, 0xC6, 0x60, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x0C, 0x30, 0x1C, 0x00, 0xC0, 0xC6, 0x60, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x0C, 0x30, 0x0F, 0x00, 0xC0, 0xC6, 0x7E, 0x7E, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x0C, 0x30, 0x07, 0x80, 0xFC, 0xFC, 0x60, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x0C, 0x30, 0x01, 0xC0, 0xC0, 0xCC, 0x60, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x0C, 0x30, 0x00, 0xC0, 0xC0, 0xC6, 0x60, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x0C, 0x30, 0x18, 0xC0, 0xC0, 0xC6, 0x60, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x0C, 0x30, 0x0F, 0x80, 0xC0, 0xC3, 0x7E, 0x7E, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

	
;#######################################
;############  FUNCTIONS  ##############
;#######################################

;####################################################################################
;############ DELAI FUNCTIONS #######################################################
;####################################################################################

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
	
	

;####################################################################################
;############ LCD FUNCTIONS #########################################################
;####################################################################################

lcd_write_instruction: 	; WRITE INSTRUCTION TO LCD Instruction Register

; LCD_DATA	: INSTRUCTION	(PORT1)
; 0 - RS	: LOW			(PORT0)
; 1 - EN	: HIGH / LOW	(PORT0)

; OUTPUT INSTRUCTION into PORT1
	ld a,(LCD_DATA)
	out (PORT1), a
; EN -> HIGH
	ld a,%00000110
	out (PORT0),a
	call delai_2us	
; EN -> LOW
	ld a,%00000100
	out (PORT0),a
	call delai_2us	
ret


	
lcd_write_data: 		; WRITE DATA TO LCD Data Register

; LCD_DATA	: INSTRUCTION 	(PORT1)
; RS		: HIGH 			(PORT0)
; EN		: HIGH / LOW 	(PORT0)

; OUTPUT DATA
	ld a,(LCD_DATA)
	out (PORT1),a
; EN -> HIGH
	ld a,%00000111
	out (PORT0),a
	call delai_2us	
; EN -> LOW
	ld a,%00000101
	out (PORT0),a
	call delai_2us	
ret	 
	


lcd_init:							; INITIALISATION DU MODULE ST7920
	
	ld a,BASIC_FONCTION				; FUNCTION SET -> 	" $30 "
	ld (LCD_DATA),a
	call lcd_write_instruction	
	call delai_100us				; Wait time >100uS 
	
	ld a,BASIC_FONCTION				; FUNCTION SET -> 	" $30 " 
	ld (LCD_DATA),a
	call lcd_write_instruction	
	call delai_100us				; Wait time >37uS 
	
	ld a,%00001100 					; DISPLAY ON/OFF -> " $0C " 
	ld (LCD_DATA),a
	call lcd_write_instruction	
	call delai_100us				; Wait time >100uS 
	
	ld a,%00000001 					; CLEAR DISPLAY -> " $01 "
	ld (LCD_DATA),a
	call lcd_write_instruction	
	call delai_40ms					; Wait time >10mS
	
	ld a,%00000110 					; ENTRY MODE : increment cursor + no display shifting -> " $06 "
	ld (LCD_DATA),a
	call lcd_write_instruction
	call delai_100us				; Wait time >100uS 
ret



lcd_print_chaine:  					; PRINT A CHAR TEXT INTO THE LCD IN TEXT MODE

	push BC
	ld a,(hl)						; Load the byte from memory at address indicated by HL into A.	
	ld b,a							; nb char to display
	inc hl
	print_string_loop:
		ld a,(hl)					; Load the byte from memory at address indicated by HL into A.	
		ld (LCD_DATA),a
		call lcd_write_data 		; Call the routine to display a character.
		inc	hl						; Increment the HL value.	
	djnz print_string_loop  		; dec b and Jumps back if b is not zero	
	pop BC
ret				 
	


cls_txt:							;  CLEAR DISPLAY IN TEXT MODE -> 1.6 ms require

	ld a,%00000001 					; CLEAR DISPLAY -> " $01 "
	ld (LCD_DATA),a
	call lcd_write_instruction		; CLEAR DISPLAY	
	call delai_40ms					; Wait time >1.6 ms
ret



lcd_enable_graphic:					; Activate Graphic MODE

	ld a,%00110000 					; FUNCTION SET -> 	" $30 "
	ld (LCD_DATA),a
	call lcd_write_instruction 
	call delai_100us				; Wait time >100uS 
	
	ld a,EXTENDED_FONCTION			; FUNCTION SET -> 	" $34 " Extended instruction set
	ld (LCD_DATA),a
	call lcd_write_instruction
	call delai_100us				; Wait time >100uS 
	
	ld a,%00110110 					; Display ON/OFF -> " $36 "  graphic display ON
	ld (LCD_DATA),a
	call lcd_write_instruction
	call delai_100us				; Wait time >100uS 	
ret


;####################################################################################
;############ GRAPHICAL FUNCTIONS ###################################################
;####################################################################################

empty_ramvideo:						; set (128*64 = 8K pixel  -> 1024 byte) with value zero at address VIDEO_RAM

	push HL
	push BC
	
	ld HL,VIDEO_RAM
	ld B,$04
	ld C,$00						; BC contient 1024 (= $400)
	XOR a
	boucle_cls_graphic:
		ld (HL),a
		inc HL
		dec C
	jp nz,boucle_cls_graphic
	djnz boucle_cls_graphic	 

	pop BC
	pop HL
ret


draw_display:						; DRAW pixel from VIDEO_RAM to the LCD screen
									; draw 128*64 pixels => en 2 temps : X = 0à15 : 32 lignes, X=16à31 : 32 lignes suivantes
	push BC
	push DE
	push HL
	
	; affichage des lignes Y = [0 à 31] pour X = [0-15]
	ld HL,VIDEO_RAM
	ld e,$20						; e = 32 ; nb lines
	ld d,$0							; d = 0	 ; Y position [0->31]
	Boucle32Y:	
		ld a,d
		OR $80						; Set vertical address （Y） for GDRAM = 0 ($80) + D
		ld (LCD_DATA),a
		call lcd_write_instruction
		
		ld a,$80					; Set horizontal address （X） for GDRAM = 0 ($80)
		ld (LCD_DATA),a
		call lcd_write_instruction		

		ld b,$10					; b = 16		
		Boucle16X:					; write 16*8 = 128 bit of data.		
			ld a,(HL)		
			ld (LCD_DATA),a	
			call lcd_write_data 	; Address counter will automatically increase by one for the next two-byte data		
			inc HL												
		djnz Boucle16X				; b = b -1 ; jump to label if b not 0
		
		inc d
		dec e 
	jp nz,Boucle32Y	

; affichage des lignes Y = [32 à 63] pour X = [0-15]
	ld e,$20						; e = 32 ; nb lines
	ld d,$0							; d = 0	 ; Y position [32->63]
	Boucle32Y_2:		
		ld a,d
		OR $80						; Set vertical address （Y） for GDRAM = 0 ($80) + D
		ld (LCD_DATA),a
		call lcd_write_instruction
		
		ld a,$88					; Set horizontal address （X） for GDRAM = 0 ($80 + $08)
		ld (LCD_DATA),a
		call lcd_write_instruction		

		ld b,$10					; b = 16		
		Boucle16X_2:				; write 16*8 = 128 bit of data.
			ld a,(HL)			
			ld (LCD_DATA),a	
			call lcd_write_data 	; Address counter will automatically increase by one for the next two-byte data		
			inc HL	
		djnz Boucle16X_2			; b = b -1 ; jump to label if b not 0
		
		inc d
		dec e 
	jp nz,Boucle32Y_2	

	pop HL
	pop DE
	pop BC
ret



cls_graphic:						; empty ramvideo and display it
	
	call empty_ramvideo	
	call draw_display 
ret



load_image:							; LOAD 128*64 bits (16*8 Byte) of data into the VIDEO_RAM
									; HL = IMAGE address ; DE = VIDEO_RAM address
	push BC
	push DE
	
	; LDIR : Cette instruction exécute la copie mémoire ( d'un octet de (HL) vers (DE), puis incrémente HL,DE et décrémente BC) tant que BC est supérieur à zéro
	; HL contient l'adresse en memoire de l'image
	ld DE,VIDEO_RAM
	ld BC,$0400						; 1024 octets
	LDIR 							; copie BC octets depuis HL vers DE 

	call draw_display
	
	pop DE
	pop BC	
ret	


putpixel:							; put a pixel to "1" at the corresponding address into the VIDEO_RAM address
									; (LCD_COOX doit contenir X [0->127] ,LCD_COOY doit contenir Y [0->63] )
	push DE
	push HL

	; find the corresponding byte in VIDEO_RAM
	; HL = VIDEO_RAM + (Y*16) + X :
		ld a,(LCD_COOY)			
		ld h,0
		ld l,a
	; Y*16 (16 = 2^4)
		add HL,HL
		add HL,HL
		add HL,HL
		add HL,HL
		ld d,h
		ld e,l
		ld HL,VIDEO_RAM
		add HL,DE
		ld d,0
		ld a,(LCD_COOX)				; find the byte, of our pixel (between the [0-15] byte of the X line (128 pixel) ) : 
		srl	 a						; a divisé par 2
		srl  a						; a divisé par 4
		srl  a						; a divisé par 8	
		ld e,a
		add HL,DE					; HL contient l'adresse en RAM de l'octet video à modifier. 
		
	; reste a trouver quel est le bit à modifier dans cet octet : 	
	; au niveau de la valeur X [0->127], il faut la diviser par 8 (1 octet) et garder la position du pixel dans l'octet (le pixel à modifier)
		ld a,(LCD_COOX)				; find the byte, of our pixel (between the [0-15] byte of the X line) :
		ld d,a						; save X in d
		srl	 a						; a divisé par 2
		srl  a						; a divisé par 4
		srl  a						; a divisé par 8 

		sla  a						; a multiplié par 2
		sla  a						; a multiplié par 4
		sla  a						; a multiplié par 8 

		ld e,a		
		ld a,d
		sub e						; get the modulo remain in ACC : that's our pixel's position in the byte [0-7]	in HL
		ld e,a
	
	; forcer le bit qui est en position E à la valeur 1 dans l'octet present a l'adresse HL
	ld d,$80  						; d=$80 = %1000 0000		
	shift_e:
		xor a
		or e
	jp z,suite_putpixel
		dec e
		srl d						; on decal le bit de d, à droite, de 1 position
	jp shift_e
	
	suite_putpixel:
	; le registre d contient la position du bit à activer (1)	
		ld a,(HL)
		OR d
		ld (HL),a		

	pop HL
	pop DE

ret


hidepixel:							; put a pixel to "0" at the corresponding address into the VIDEO_RAM address
									; (LCD_COOX doit contenir X [0->127] ,LCD_COOY doit contenir Y [0->63] )

	push DE
	push HL

	; find the corresponding byte in VIDEO_RAM
	; HL = VIDEO_RAM + (Y*16) + X :
		ld a,(LCD_COOY)			
		ld h,0
		ld l,a
	; Y*16 (= 2^4)
		add HL,HL
		add HL,HL
		add HL,HL
		add HL,HL
		ld d,h
		ld e,l
		ld HL,VIDEO_RAM
		add HL,DE
		ld d,0
		ld a,(LCD_COOX)				; find the byte, of our pixel (between the [0-15] byte of the X line (128 pixel) ) : 
		srl	 a						; a divisé par 2
		srl  a						; a divisé par 4
		srl  a						; a divisé par 8	
		ld e,a
		add HL,DE					; HL contient l'adresse en RAM de l'octet video à modifier. 
		
	; reste a trouver quel est le bit à modifier dans cet octet : 	
	; au niveau de la valeur X [0->127], il faut la diviser par 8 (1 octet) et garder la position du pixel dans l'octet (le pixel à modifier)
		ld a,(LCD_COOX)				; find the byte, of our pixel (between the [0-15] byte of the X line) :
		ld d,a						; save X in d
		srl	 a						; a divisé par 2
		srl  a						; a divisé par 4
		srl  a						; a divisé par 8 

		sla  a						; a multiplié par 2
		sla  a						; a multiplié par 4
		sla  a						; a multiplié par 8 

		ld e,a		
		ld a,d
		sub e						; get the modulo remain in ACC : that's our pixel's position in the byte [0-7]	in HL
		ld e,a
	
	; forcer le bit qui est en position E à la valeur 1 dans l'octet present a l'adresse HL
	ld d,$7F  						; d=$7f = %0111 1111		
	shift_e2:
		xor a
		or e
	jp z,suite_hidepixel
		dec e
		rrc d						; on decal le bit de d, à droite, de 1 position 
	jp shift_e2
	 
	suite_hidepixel:		
		ld a,(HL)
		AND d						; le registre d contient la position du bit à desactiver (0)
		ld (HL),a

	pop HL
	pop DE
ret



print_cchar:						; print a custom ASCII CHAR (5X6 pixel) from coordinate (CURX,CURY) 
									; Char pixel value start @HL = ASCII_TABLE + n*5
	push DE
	push BC
	push HL

	;recherche_ASCII_position: 		; utiliser  ASCII_TABLE + ((CHAR-32) * 6 lines) -> value [0-378]

	ld H,0
	ld a,(CHAR)
	sub 32
	ld L,a
	; multiplier HL par 6=(2+1)*2 :
	push HL
	pop DE
	add HL,HL						; *2
	add HL,DE						; +1
	add HL,HL						; *2
	push HL
	pop DE
	
	
	ld HL,ASCII_TABLE	
	add HL,DE						; Add register pair DE to HL.


	
	ld D,6							; nombre de ligne à afficher sur un CHAR = 6	
	
	; boucle sur les 6 lignes "d" (0-5):
	boucle_ligne_cc:			
		ld E,5						; nombre de pixel a afficher sur une ligne = 5			
		ld C,(HL)	; valeur ligne
		
		; boucle sur les 5 pixels "E" de la ligne en cours (0-4) :
		boucle_pixel_cc:
		
			; affichage pixel
				ld a,%00010000
				AND C				; verifier si on a un pixel a 1 ou 0 en bit 4 de C
			jp z,boucle_pixel_cc_suite	;;hidepixel_cc
				
				; showpixel_cc1:
				ld a,(CURX)			; a = position en X à l'ecran	
				ld (LCD_COOX),a
				ld a,(CURY)			; a = position en Y à l'ecran
				ld (LCD_COOY),a	
				call putpixel									
			jp boucle_pixel_cc_suite
				
				; hidepixel_cc:
				; ld a,(CURX)			; a = position en X à l'ecran	
				; ld (LCD_COOX),a
				; ld a,(CURY)			; a = position en Y à l'ecran
				; ld (LCD_COOY),a	 
				; call  hidepixel				
				
			boucle_pixel_cc_suite:				
				SLA C 				; decalage sur la ligne vers la gauche d'un bit, et rentre 0 en bit 0
			
				ld a,(CURX)			; a = position en X à l'ecran
				inc a
				ld (CURX),a			; curseur en X incrementé de 1 pixel

				dec E				; on decremente d'un pixel		
		jp nz,boucle_pixel_cc
	
	
		boucle_fin_ligne_cc:
			ld a,(CURX)			; a = position en X à l'ecran
			sub 5
			ld (CURX),a			; curseur en X remis au debut	

			ld a,(CURY)			; a = position en Y à l'ecran
			inc a
			ld (CURY),a			; curseur en Y incrementé de 1 pixel

			inc HL				; on incremente la valeur @ en table ASCII_TABLE pour ce char
			ld E,5				; nombre de pixel a afficher sur une ligne reinitialisé à  5
			dec D				; on decremente d'une ligne	
		
	jp nz,boucle_ligne_cc
		
		
	fin_print_affiche_ccK:	

		ld a,(CURY)					; remise en position du Y à l'ecran
		sub 6
		ld (CURY),a		
		
	pop HL
	pop BC
	pop DE	
ret



retour_chariot: 					; retour chariot (CURX,CURY)
 
		XOR a
		ld (CURX),a					; CURX = 0			
		ld a,(CURY)
		add 6						; On descend CURY de 6 pixel
		ld (CURY),a	

		; /!\ on ne check pas la fin de page..	
ret



print_line:							; Print a line of char in graphical mode from (CURX,CURY) /!\ should not exceed end of line
									; HL contient l'adresse du text à afficher : le premier octet lu est la longueur du texte
									; ensuite vient les codes ASCII
	push BC
	
	ld a,(HL)
	ld b,a							; b contient le nombre de caracteres à imprimer à l'ecran
	inc HL
	
	boucle_print_line:
		ld a,(HL)
		ld (CHAR),a
		call print_cchar
		ld a,(CURX)					; a = position en X à l'ecran
		add 5						; on avance CURX de 5
		ld (CURX),a	
		inc HL	
	djnz boucle_print_line			; b = b -1 ; jump to label if b not 0

	call draw_display
	
	pop BC
ret 




;####################################################################################
;############ SIGNED FIXED POINT FUNCTION ###########################################
;####################################################################################


F_ADD:						; 16 bit Signed Addition 
							; INPUT  : DE + BC 
							; OUTPUT : DE

	ld a,e 
	add c					; "add" ajoute les deux valeurs "fractionnelles" et garde la retenue (Carry)
	ld e,a

	ld a,d 
	adc b					; "adc" ajoute les deux valeurs "entiere" et ajoute la precedente retenue si necessaire
	ld d,a
ret



F_SUB:						; 16bit Signed Substraction 
							; INPUT  : DE - BC 
							; OUTPUT : DE

	ld a,e
	sub c					; e = e - c 	et garde la retenue
	ld e,a
	
	ld a,d
	sbc b					; d = d - b - carry
	ld d,a
ret 



F_MUL:						; 16 bit Signed Multiplication 
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




F_MUL_16:					; 16 bit unsigned Multiplication 
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




F_DIV:						; 16 bit UNSIGNED  Division
							; INPUT  : BC / DE   /!\ here BC and DE are not same as above math function. DE divide BC !!
							; OUTPUT : DE 
							
	; /!\ the code below is not from me, I find it on the WEB here : http://z80-heaven.wikidot.com/advanced-math#toc0		

		push HL

; ld (INPUT2),DE
; ld (INPUT1),BC
; ld HL,INPUT1	
	; call DISPLAY_FIXED_POINT
	; call update_cursor
; ld a,"/"
	; ld (CHAR),a
	; call print_cchar
	; call update_cursor	
	; call update_cursor	
; ld HL,INPUT2	
	; call DISPLAY_FIXED_POINT
	; call update_cursor	 	
; ld a,"="
	; ld (CHAR),a
	; call print_cchar
	; call update_cursor	
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

	; ld (OUTPUT),DE
	; ld HL,OUTPUT	
	; call DISPLAY_FIXED_POINT 
 
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
	
	
	

F_DIV_8bit:					; 8/8 unsigned Division 
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





;####################################################################################
;############ 3D FUNCTIONS ##########################################################
;####################################################################################


MATRIX_MUL_3:						; Fonction de multiplication de matrice (3)*(3-3-3) utilisant le format Signed Fixed Point (8.8) 
									; INPUT : IX = adresse de la matrice [3] (6 octets) et IY = adresse de la matrice [3-3-3] (18 octets)
									; OUTPUT: MAT3_RESULT = adresse de la matrice resultat [3] (6 octets)

	push BC
	push DE
	push HL 
	
	
	; boucle b  sur les 3 elements de IY
	ld b,3
	ld c,0
	ld HL,MAT3_RESULT
	boucle_mat_mul_3:		 
	

		push IX									; on sauvegarde l'adresse de IX pour les calculs suivants
		call MATRIX_MUL							; multiplie IX[3] * IY[3] et mets le resultat dans MAT3_RESULT (6 octets)
		pop IX
				
		; placer le resultat de MAT_RESULT[1]  dans MAT3_RESULT[3]
		ld a,(MAT_RESULT)
		ld (HL),a
		inc HL
		ld a,(MAT_RESULT+1)
		ld (HL),a	
		inc HL
		 
		inc c
	djnz boucle_mat_mul_3
 
	pop HL
	pop DE
	pop BC
ret



MATRIX_MUL:							; multiplication de matrice [3][3] -> multiplie IX * IY et place le resultat DE dans MAT_RESULT (2 octets)
									; INPUT : IX = adresse de la matrice [3] (6 octets) et IY = adresse de la matrice [3] (6 octets)
									; OUTPUT: MAT_RESULT = adresse de la matrice resultat [1] (2 octets)
	push BC
	push DE
	push HL 	
	
	ld b,3
	ld HL,0
	boucle_mat_mul:

		push BC
		ld b,(IX)
		ld c,(IX+1)
		ld d,(IY)
		ld e,(IY+1)
		
		call F_MUL
		
	; ajoute le resultat DE au resultat precedent
		ld b,h
		ld c,l
		
		call F_ADD
		
		ld h,d
		ld l,e 
		pop BC	
		
	; passer à l'element suivant :
		ld DE,2
		ADD IX,DE	
		ADD IY,DE
		
	djnz boucle_mat_mul	
	
	; placer le resultat dans MAT_RESULT	
	ld a,h
	ld (MAT_RESULT),a
	ld a,l
	ld (MAT_RESULT+1),a		
	
	pop HL
	pop DE
	pop BC
ret



draw_point3D:						; affiche un point sur l'ecran / PointPlan contient une liste de points (X,Y)

	push BC
	push DE
	push HL
	
	ld b,3
	ld c,0
	boucle_draw_point3D:
	
		ld HL,PointPlan
		ld d,0
		; multiplier c par 2
		ld a,c
		sla a						; X2
		ld e,a
		add HL,DE
		
		ld a,(HL)
		ld e,a
		ld a,63
		add e
		ld (LCD_COOX),a				; -> Coord X ecran du point à afficher
		
		inc HL
		ld a,(HL)
		ld e,a
		ld a,31
		sub e
		ld (LCD_COOY),a				; -> Coord Y ecran du point à afficher	 (Y de bas en haut de l'ecran donc on part et 63 et on remonte vers 0)

		call putpixel 				; (LCD_COOX,LCD_COOY)
		
		inc c

	djnz boucle_draw_point3D
	
	pop HL
	pop DE	
	pop BC
ret 



GenMatRotX:				; Genere une matrice Rotation autour de l'axe des X (input = ANGLE (1 octet) ; output = MatriceRota [3] (6 octets) ) 
						; MATRICE ROTATION X : MatriceRota
						; 	1	0		0
						;	0	cos(A)	-sin(A)						-sin(A) = (-1)*(sin(A))
						;	0	sin(A)	cos(A)
	push BC					
	push DE		
	push HL 
	  
	; valeur par defaut : 
	; LDIR : Cette instruction exécute la copie mémoire ( d'un octet de (HL) vers (DE), puis incrémente HL,DE et décrémente BC) tant que BC est supérieure à zéro
	ld HL,MAT_ROT_X
	ld DE,MatriceRota
	ld BC,$0012					; 18 octets
	LDIR 	
 

	; calculer les cos/sin:	
	
	; Maj Colonne n°1 :
	; RAS
	
	; Maj Colonne n°2 :		
	;cos(A)

	ld a,(ANGLE)	
	ld h,0
	ld l,a
	add HL,HL				; *2
	ld d,h
	ld e,l	
	ld HL,TABLE_COSINUS 
	add HL,DE
	ld a,(HL)
	ld (MatriceRota+8),a
	ld (MatriceRota+16),a
	inc HL
	ld a,(HL)
	ld (MatriceRota+9),a 
	ld (MatriceRota+17),a	
	
	;sin(A)
	ld a,(ANGLE)	
	ld h,0
	ld l,a
	add HL,HL
	ld d,h
	ld e,l	
	ld HL,TABLE_SINUS 
	add HL,DE
	ld a,(HL)	
	ld (MatriceRota+10),a
	inc HL
	ld a,(HL)
	ld (MatriceRota+11),a 

	; Maj Colonne n°3 : 	
	;-sin(A)	
	ld a,(ANGLE)	
	ld h,0
	ld l,a
	add HL,HL
	ld d,h
	ld e,l	
	ld HL,TABLE_SINUS 
	add HL,DE
	ld d,(HL)
	inc HL
	ld e,(HL)
	ld BC,$ff00				;  -01.00
	call F_MUL
	ld a,d
	ld (MatriceRota+14),a
	ld a,e
	ld (MatriceRota+15),a 
 
	pop HL
	pop DE
	pop BC
ret


GenMatRotY:				; Genere une matrice Rotation autour de l'axe des Y (input = ANGLE (1 octet) ; output = MatriceRota [3] (6 octets) ) 
						; MATRICE ROTATION Y : MatriceRota
						; 	cos(A)	0	sin(A)
						;	0		1	0
						;	-sin(A)	0	cos(A)
	push BC					
	push DE		
	push HL 
	  
	; valeur par defaut : 
	; LDIR : Cette instruction exécute la copie mémoire ( d'un octet de (HL) vers (DE), puis incrémente HL,DE et décrémente BC) tant que BC est supérieure à zéro
	ld HL,MAT_ROT_Y
	ld DE,MatriceRota
	ld BC,$0012					; 18 octets
	LDIR 	
 

	; calculer les cos/sin:	
	
	; Maj Colonne n°1 et 3:
	;cos(A)
	ld a,(ANGLE)	
	ld h,0
	ld l,a
	add HL,HL				; *2
	ld d,h
	ld e,l	
	ld HL,TABLE_COSINUS 	;TableCOS
	add HL,DE
	ld a,(HL)
	ld (MatriceRota),a 
		ld (MatriceRota+16),a
	inc HL
	ld a,(HL)
	ld (MatriceRota+1),a  
		ld (MatriceRota+17),a	

	;-sin(A)	
	ld a,(ANGLE)	
	ld h,0
	ld l,a
	add HL,HL
	ld d,h
	ld e,l	
	ld HL,TABLE_SINUS 
	add HL,DE
	ld d,(HL)
	inc HL
	ld e,(HL)
	ld BC,$ff00				;  -01.00
	call F_MUL
	ld a,d
	ld (MatriceRota+4),a
	ld a,e
	ld (MatriceRota+5),a 
	
	
	; Maj Colonne n°2 :	
	; RAS
	

	; Maj Colonne n°3 : 	
	;sin(A)
	ld a,(ANGLE)	
	ld h,0
	ld l,a
	add HL,HL
	ld d,h
	ld e,l	
	ld HL,TABLE_SINUS 
	add HL,DE
	ld a,(HL)	
	ld (MatriceRota+12),a
	inc HL
	ld a,(HL)
	ld (MatriceRota+13),a 
 
	pop HL
	pop DE
	pop BC	
ret


GenMatRotZ:				; Genere une matrice Rotation autour de l'axe des Y (input = ANGLE (1 octet) ; output = MatriceRota [3] (6 octets) ) 
						; MATRICE ROTATION Y : MatriceRota
						; 	cos(A)	-sin(A)	0
						;	sin(A)	cos(A)	0
						;	0		0		1	
	push BC					
	push DE		
	push HL 
	  
	; valeur par defaut : 
	; LDIR : Cette instruction exécute la copie mémoire ( d'un octet de (HL) vers (DE), puis incrémente HL,DE et décrémente BC) tant que BC est supérieure à zéro
	ld HL,MAT_ROT_Z
	ld DE,MatriceRota
	ld BC,$0012					; 18 octets
	LDIR 	

	; calculer les cos/sin:	
	
	; Maj Colonne n°1 :
	;cos(A)
	ld a,(ANGLE)	
	ld h,0
	ld l,a
	add HL,HL				; *2
	ld d,h
	ld e,l	
	ld HL,TABLE_COSINUS 	;TableCOS
	add HL,DE
	ld a,(HL)	
	ld (MatriceRota),a 
	ld (MatriceRota+8),a
	inc HL
	ld a,(HL)
	ld (MatriceRota+1),a  
	ld (MatriceRota+9),a

	;sin(A)
	ld a,(ANGLE)	
	ld h,0
	ld l,a
	add HL,HL
	ld d,h
	ld e,l	
	ld HL,TABLE_SINUS 
	add HL,DE
	ld a,(HL)	
	ld (MatriceRota+2),a
	inc HL
	ld a,(HL)
	ld (MatriceRota+3),a 

		
	; Maj Colonne n°2 :	
	;-sin(A)	
	ld a,(ANGLE)	
	ld h,0
	ld l,a
	add HL,HL
	ld d,h
	ld e,l	
	ld HL,TABLE_SINUS 
	add HL,DE
	ld d,(HL)
	inc HL
	ld e,(HL)
	ld BC,$ff00				;  -01.00
	call F_MUL
	ld a,d
	ld (MatriceRota+6),a
	ld a,e
	ld (MatriceRota+7),a 

 
	; Maj Colonne n°3 : 	
	; RAS

	pop HL
	pop DE
	pop BC
ret





copy_rotated:									; copy IY[3] into IX[3]

	push BC
	push DE
	push HL

	push IY
	pop DE										; ld DE,IY
	
	push IX
	pop HL										; ld HL,IX
 
	ld b,6
	boucle_rotated:
		ld a,(DE)
		ld (HL),a
		inc DE
		inc HL	
	djnz boucle_rotated
		
	pop HL	
	pop DE	
	pop BC	
ret		


Rotation_Mesh:									; effectue une rotation (selon "MatriceRota") de l'objet présent dans "MESH2" de "Angle" degrés radian
												; MESH2 = n,{x1:x1,y1:y1,z1:z1,...,xn:xn,yn:yn,zn:zn}          (8:8 bit)
	push BC
	push DE
	push IX
	push IY
	push HL

	ld a,(MESH2)									; MESH2 nb of point		
	ld b,a							 
	ld c,0
	
	boucle_rotation_mesh:

		; multiplier c par 6 dans e = multiplier par 2 ajouter 1 fois C et remultiplier par 2
		ld h,0
		ld l,c
		add HL,HL								; X2
		ld d,0
		ld e,c
		add HL,DE								; X3
		add HL,HL								; X6
		ld d,h
		ld e,l		
		
		ld HL,MESH2+1							; le premier element est le nombre de points	
 
		add HL,DE
		push HL
		pop IX									; ld IX,HL [3]
		ld IY,MatriceRota						; IY [3,3,3]		
		call MATRIX_MUL_3	 					; resultat dans MAT3_RESULT[3]
		
		; recopier les points modifiés dans MESH2:		
		push HL
		pop IX
		ld IY,MAT3_RESULT
		call copy_rotated
		
		inc c
	djnz boucle_rotation_mesh
		
	pop HL
	pop IY
	pop IX
	pop DE
	pop BC			
ret


Projection_Mesh_PointPlan:						; projete les points 3D de MESH2 en 2D et les copie dans PointPlan

	push BC
	push DE
	push IX
	push IY
	push HL

 
; NOMBRE DE POINTS 3D / 2D :
	ld a,(MESH2)								; MESH2 nb of point		
	ld b,a							
	ld (PointPlan),a							; nb of points 2D to display
	ld c,0	
	
; CALCUL PROJECTION : 
	boucle_calcul_pts:
	
	; multiplier c par 6 dans e = multiplier par 2 ajouter 1 fois C et re-multiplier par 2 le resultat
		ld h,0
		ld l,c
		add HL,HL
		ld d,0
		ld e,c
		add HL,DE
		add HL,HL
		ld d,h
		ld e,l		
		
		ld HL,MESH2+1							; le premier element est le nombre de points	
 
		add HL,DE
		push HL
		pop IX									; ld IX,HL [3] 		
		ld IY,MatriceProj						; IY [3,3,3]			
		call MATRIX_MUL_3	 					; resultat dans MAT3_RESULT[3]



	; COPY NOUVEAUX POINTS DANS LISTE DES POINTS 2D (8.8), X et Y uniquement, pour l'affichage :
		ld h,0
		;Ajouter 4*c dans HL
		ld l,c 
		add HL,HL								; X2
		add HL,HL								; X4
		ld d,h
		ld e,l
		ld HL,PointPlan		
		inc HL									; first value is nb of 2D points.
		add HL,DE
		; on ne garde que les valeurs de X et Y :
		ld a,(MAT3_RESULT)						; X
		ld (HL),a	 	
		inc HL
		ld a,(MAT3_RESULT+1) 					; X
		ld (HL),a	
		inc HL		
		ld a,(MAT3_RESULT+2)					; Y
		ld (HL),a	
		inc HL
		ld a,(MAT3_RESULT+3)					; Y
		ld (HL),a	

 
	; NEXT POINT:	
		inc c
	djnz boucle_calcul_pts					; b = b - 1 + jp nz,boucle	
	
	pop HL
	pop IY
	pop IX
	pop DE
	pop BC	
ret




draw_3D_line_16:					; draw line of the mesh on the screen / PointPlan[1+(2*2)n] contient une liste de n points (X,Y) en 8:8 bits
									; convertir les coordonnées en 16 bits 6+2.6+2 (6bits perdus)

	push BC
	push DE
	push HL
	push IX
	push IY
 

	; conversion en 16 bits au lieu de 8:8 et recentrage sur ECRAN 128*64 :
	
	; pour X : convertir en 16 bits puis ajouter 63 pixels (centre X de l'ecran LCD) 
	ld IX,PointPlan
	ld a,(IX)
	ld b,a
	inc IX 									; nb points
	boucleX_convert_add_63:
		push BC
		
		; convertir 8:8 en 16 bits value (7+1:7+1) on perds les 7 derniers bits apres la virgule mais on obtient range [-256;+256] pixels
		
		; tester si la coordonnée X est positive ou negative:				
			ld h,(IX)
			ld l,(IX+1)						; valeur X en 8:8 dans HL
			bit 7,H							; Si le bit testé est à un, alors le flag Z=0
		jp nz,convertionX_negatif
		
		; X est positif :
			ld d,$00
			add HL,HL						; decalage à gauche de 1 bit
			ld e,h							; on garde que les 8 bits
		jp addX_63		
		
		convertionX_negatif:
		; X est negatif :
			ld d,$ff
			add HL,HL
			ld e,h			
		
		addX_63:  
			ld BC,$003F
			call F_ADD						; DE = DE + 63

		; mise à jour des données dans PointPlan :
			ld (IX),d
			ld (IX+1),e	
 
			inc IX
			inc IX	
			inc IX
			inc IX							; on avance de 4*8bits
		pop BC
	djnz boucleX_convert_add_63

	
	; pour Y, convertir en 16 bits puis inverser la valeur et ajouter 31 pixels :
	ld IX,PointPlan	
	ld a,(IX)
	ld b,a
	inc IX									; nb points
	inc IX					
	inc IX									; valeur de X
	boucleY_convert_inv_add_31:
		push BC
		
		; conversion en 16 bits :
		
		; tester si la coordonnée Y est positive ou negative:			
			
			ld h,(IX)
			ld l,(IX+1)						; valeur X en 8:8 dans HL
			bit 7,H							; Si le bit testé est à un, alors le flag Z=0
		jp nz,convertionY_negatif
		
		; X est positif :
			ld d,$00
			add HL,HL						; decalage à gauche de  bit
			ld e,h							; on garde que les 8 bits	
; ajouter 1 :
			ld BC,$0001	
			call F_ADD
		jp invert_Y
		
		convertionY_negatif:
		; X est negatif :
			ld d,$ff
			add HL,HL
			ld e,h 		 
		
		invert_Y:
		; inverser Y :
			ld b,d
			ld c,e
			ld de,$0000
			call F_SUB						; DE = DE - BC = $0000 - BC
				
		; ajouter 31 :
			ld BC,$001f
			call F_ADD						; DE = DE + 31
			
		; mise à jour des données dans PointPlan :
			ld (IX),d
			ld (IX+1),e	
 
			inc IX
			inc IX	 
			inc IX
			inc IX							; on avance de 4*8bits
		pop BC
	djnz boucleY_convert_inv_add_31	

 

	; Copier les points de la ligne à tracer (Line_X0,Line_Y0) -> (Line_X1,Line_Y1) : 16 bits value each
 
	ld a,(Line_list)						; "Line_list" Contient la liste des lignes à tracer
	ld b,a									; nb of line to draw (iteration)
	ld c,0
	boucle_draw_line3D_16:
	
		; Line_X0,Line_Y0 :
		ld HL,PointPlan+1					; "PointPlan" Contient la liste des points
		ld IX,Line_list+1					;  1st value is nb points
		ld d,0
		ld e,c
		add IX,DE
		ld a,(IX)							; numero du point_1		
		dec a 
		; add a	
		; add a
	push HL
		ld h,0
		ld l,a
		add HL,HL
		add HL,HL							; multiplier par 4
		ld d,h
		ld e,l								; DE = HL
	pop HL
		add HL,DE							; valeur X0/Y0 du point_1	:
		ld a,(HL)
		ld (Line_X0),a 
		inc HL
		ld a,(HL)  
		ld (Line_X0+1),a 
		inc HL
		ld a,(HL)		
		ld (Line_Y0),a 
		inc HL
		ld a,(HL)		
		ld (Line_Y0+1),a

		
		; Line_X1,Line_Y1 :	
		inc c
		ld IX,Line_list+1
		ld HL,PointPlan+1
		ld d,0
		ld e,c
		add IX,DE
		ld a,(IX)							; numero du point_2		
		dec a		
		;add a	
		;add a
push HL
		ld h,0
		ld l,a
		add HL,HL
		add HL,HL							; multiplier par 4
		ld d,h
		ld e,l								; DE = HL
pop HL	
		add HL,DE							; valeur X1/Y1 du point_2	
		ld a,(HL)  
		ld (Line_X1),a
		inc HL
		ld a,(HL)  
		ld (Line_X1+1),a		
		inc HL
		ld a,(HL)		
		ld (Line_Y1),a
		inc HL
		ld a,(HL)		
		ld (Line_Y1+1),a		 

		
		
		call drawline_16	
	
		inc c	 	
	 djnz boucle_draw_line3D_16				; /!\ can't use djnz if loop code size is to long...
	
	pop IY
	pop IX
	pop HL
	pop DE
	pop BC
ret



checkNputpixel:								; Vérifier si le point est bien dans l'ecran LCD et affiche un pixel
											; LCD_X16:	16 bits value 
											; LCD_Y16:	16 bits value 

	push DE
	push BC
	push HL

	; Vérifier si 0<= LCD_X16 <=127 :
		
		ld a,(LCD_X16)
		OR a								; Si non nul alors X>256 ou  X<0
		jp nz,fin_checkNputpixel			; On affiche pas le pixel
		
		ld a,(LCD_X16+1)
		BIT 7,a								; Si le bit testé est à 1 (X>127), alors le flag Z=0 
		jp nz,fin_checkNputpixel			; JP NZ,label ; saute si non zéro (Z flag = 0)
	
	; Vérifier si 0<= LCD_Y16 <=63 :

		ld a,(LCD_Y16)
		OR a								; Si non nul alors Y>256 ou  X<0
		jp nz,fin_checkNputpixel			; On affiche pas le pixel
		
		ld a,(LCD_Y16+1)
		BIT 7,a								; Si le bit testé est à 1 (X>127), alors le flag Z=0 
		jp nz,fin_checkNputpixel			; JP NZ,label ; saute si non zéro (Z flag = 0)

		ld a,(LCD_Y16+1)
		BIT 6,a								; Si le bit testé est à 1 (X>63), alors le flag Z=0 
		jp nz,fin_checkNputpixel			; JP NZ,label ; saute si non zéro (Z flag = 0)	
		
	; Alors afficher le pixel :
	
		ld a,(LCD_X16+1)
		ld (LCD_COOX),a
		ld a,(LCD_Y16+1)
		ld (LCD_COOY),a		
		call putpixel	
		
	fin_checkNputpixel:

	pop HL
	pop BC
	pop DE
ret





drawline_16:								; Draw a line in 16 bits, using 16 bits variable :
											; Line_X0:	 2 octets 
											; Line_Y0:	 2 octets 	
											; Line_X1:	 2 octets 
											; Line_Y1:	 2 octets 
											; L_X:	 	 2 octets 	
											; L_Y:	 	 2 octets 
											; L_DX:		 2 octets 
											; L_DY:		 2 octets 
											; L_TEMP:	 2 octets
											; L_CPT:	 2 octets

	push DE
	push BC
	push HL
 
	; Vérifier si les deux points sont distincts :
	; Si on a bien (Line_X0,Line_Y0) <> (Line_X1,Line_Y1) : (16 bit value each)
	; C'est à dire que si (Line_X0-Line_X1 =0) et (Line_Y0-Line_Y1 =0) : alors ne pas afficher la ligne (juste un point).
	
	;(Line_X0-Line_X1 =0)?
	; /!\ ne pas utiliser  "ld DE,(LCD_X0)" car ddh ← (nn + 1) ddl ← (nn) -> inverserait les valeurs
	; mais ici on test si on a 0.0 donc pas d'importance.
		ld DE,(Line_X0) 
		ld BC,(Line_X1) 
		call F_SUB								; DE = DE - BC		
		ld a,d
		or e
	jp nz,pixels_extremity
	
	;(Line_Y0-Line_Y1=0) also ?
		ld DE,(Line_Y0)  	
		ld BC,(Line_Y1) 
		call F_SUB								; DE = DE - BC		
		ld a,d
		or e
	jp nz, pixels_extremity
	
	; sinon on place juste un point et on quitte
	
	; copie Line_X0 dans LCD_X16
		ld HL,(Line_X0)
		ld (LCD_X16),HL
	; copie Line_Y0 dans LCD_Y16	
		ld HL,(Line_Y0)
		ld (LCD_Y16),HL	
		call checkNputpixel
	jp FinDrawLine_16

	

	pixels_extremity:
	; on place un pixel aux 2 points des l'extremités Si ils sont dans le LCD:
	; utiliser la fonction "checkNputpixel" : qui verifier si le point est bien dans l'ecran LCD et affiche un pixel
	; LCD_X16:	16 bits value : used with function checkNputpixel
	; LCD_Y16:	16 bits value : used with function checkNputpixel
	
	; copie Line_X0 dans LCD_X16
	ld HL,(Line_X0)
	ld (LCD_X16),HL
	; copie Line_Y0 dans LCD_Y16	
	ld HL,(Line_Y0)
	ld (LCD_Y16),HL	
	call checkNputpixel
	
	
	; copie Line_X1 dans LCD_X16
	ld HL,(Line_X1)
	ld (LCD_X16),HL
	; copie Line_Y1 dans LCD_Y16	
	ld HL,(Line_Y1)
	ld (LCD_Y16),HL	
	call checkNputpixel
	
 
			
	; #############################
	; INITIALISATION DES VARIABLES: 
	; #############################
	; 16 bits : Line_X0 ; Line_Y0 ; Line_X1 ; Line_Y1 ; L_X ; L_Y ; L_DX ; L_DY ; V ; BI ; L_TEMP ; L_CPT ;  S1  ; S2
	; 8bits   :  ECH 
	
	; line_start_16:

	;L_X=Line_X0 
		ld HL,(Line_X0)
		ld (L_X),HL
	
	;L_Y=Line_Y0
		ld HL,(Line_Y0)
		ld (L_Y),HL
		
	; L_DX=ABS(Line_X1-Line_X0) :
	; /!\ ne pas utiliser  "ld DE,(LCD_X0)" car ddh ← (nn + 1) ddl ← (nn) -> inverserait les valeurs
		ld a,(Line_X1)
		ld d,a
		ld a,(Line_X1+1)
		ld e,a
		ld a,(Line_X0)
		ld b,a
		ld a,(Line_X0+1)
		ld c,a	
		
	call F_SUB									; DE = DE - BC	

	; check negative value	 
		bit 7,d										; test du bit 7 (poids fort) est  à 0 (positif ou nul)
	JP z,absolue_x_16 								; si bit7 est à 0  alors D est un nombre positif (flag Z=1).
	; sinon on inverse DE
		ld b,d
		ld c,e
		ld DE,$0000
		call F_SUB									; DE = DE - BC
	
	absolue_x_16:
		ld a,d
		ld (L_DX),a
		ld a,e
		ld (L_DX+1),a 								; L_DX=ABS(Line_X1-Line_X0)		
		
		
	; L_DY=ABS(Line_Y1-Line_Y0) :
		ld a,(Line_Y1)
		ld d,a
		ld a,(Line_Y1+1)
		ld e,a
		ld a,(Line_Y0)
		ld b,a
		ld a,(Line_Y0+1)
		ld c,a	
		call F_SUB									; DE = DE - BC	
		 
		; check negative value	
		bit 7,d										; test du bit 7 (poids fort) est  à 0 (positif ou nul)
	JP z,absolue_y_16								; si bit7 est à 0 alors D est un nombre positif (flag Z=1).
		; sinon on inverse DE	
		
		ld b,d
		ld c,e
		ld DE,$0000
		call F_SUB									; DE = DE - BC		 
		
	absolue_y_16:
		ld a,d
		ld (L_DY),a
		ld a,e
		ld (L_DY+1),a 								; L_DY=ABS(Line_Y1-Line_Y0)

	
	; S1 = signe(Line_X0,Line_X1) : 
	; if Line_X1-Line_X0 > 0 signe = +1 
	; if Line_X1-Line_X0<0   signe = -1 
	; if Line_X1=Line_X0     signe = 0
	; S1, Line_X0, Line_X1 sur 16 bit
		ld DE,(Line_X1)
		ld BC,(Line_X0)	
		
		call F_SUB									; DE = DE - BC		
		
		BIT 7,d										; test if bit 7 (poids fort) is 1 (negativ) then zeroFlag = 0
	JP nz,X1_inf_X0_16		
		ld a,e
		OR d
	JP z,X1_egal_X0_16
	; X1 sup X0      ->  +1 = $0001
		XOR a
		ld (S1),a
		ld a,$01
		ld (S1+1),a
	JP SigneY_16	
	
	X1_egal_X0_16: ; -> 0
		XOR a
		ld (S1),a
		ld (S1+1),a
	JP SigneY_16		
	
	X1_inf_X0_16:  ; ->  -1 = $ffff
		ld a,$ff 									; stocker -1
		ld (S1),a
		ld (S1+1),a	

	;S2 = signe(Line_Y0,Line_Y1) : 
	; if Line_Y1-Line_Y0 > 0 signe = +1 
	; if Line_Y1-Line_Y0<0   signe = -1 
	; if Line_Y1=Line_Y0     signe = 0
	; S2, Line_Y0, Line_Y1 sur 16 bit
	SigneY_16:	
	
		ld DE,(Line_Y1)
		ld BC,(Line_Y0)
		call F_SUB									; DE = DE - BC
		BIT 7,d										; test if bit 7 (poids fort) is 1 (negativ) then zeroFlag = 0 
	JP nz,Y1_inf_Y0_16	
		ld a,e
		OR d
	JP z,Y1_egal_Y0_16
		; Y1 sup Y0 	->  +1
		XOR a
		ld (S2),a
		ld a,$01
		ld (S2+1),a
	JP test_Dy_Dx_16	
	
	Y1_egal_Y0_16: ;    ->  0
		XOR a
		ld (S2),a
		ld (S2+1),a
		JP test_Dy_Dx_16		
	
	Y1_inf_Y0_16:  ;    ->  -1 = $ffff
		ld a,$ff									; stocker -1
		ld (S2),a
		ld (S2+1),a 	
	
	
	; IF  (L_DY > L_DX) =>  inverser les valeurs
	; IF  (L_DY - L_DX> 0) => invert value
	test_Dy_Dx_16:
	
		ld a,(L_DY)
		ld d,a
		ld a,(L_DY+1)
		ld e,a
		ld a,(L_DX)
		ld b,a
		ld a,(L_DX+1)
		ld c,a
		call F_SUB									; DE = DE - BC
		
	; Test if DE < 0 : do not invert
		BIT 7,d										; test if bit 7 (poids fort) is 1 (negativ) then zeroFlag = 0 
	jp nz,DX_sup_DY_16								; L_DY < L_DX  so L_DY-L_DX negativ
	 
	; L_DY sup L_DX : inverser les valeurs & ECH=1
		ld HL,(L_DX)
		ld DE,(L_DY)
		ld (L_DX),DE
		ld (L_DY),HL

		ld a,1
		ld (ECH),a
	JP Calcul_V_16
	
	DX_sup_DY_16: ; ECH=0
		XOR a
		ld (ECH),a		

	; Calcul sur 16 bits : V = 2*L_DY - L_DX
	Calcul_V_16: 
	
		ld a,(L_DY)
		ld h,a
		ld a,(L_DY+1)
		ld l,a
		add HL,HL									; 2*L_DY
		ld d,h
		ld e,l
		ld a,(L_DX)
		ld b,a
		ld a,(L_DX+1)
		ld c,a		
		call F_SUB									; DE = DE - BC
					
		ld BC,$0002									; 02 sur 16 bit
		call F_MUL_16								; 16 bit unsigned Multiplication  DE = DE * BC
				
		; on stock le resultat DE  dans V (16 bits)
		ld a,d
		ld (V),a
		ld a,e
		ld (V+1),a
	
	; #########################
	; Boucle principale 16 bit: 
	; #########################
	
	; FOR (BI=1; BI<L_DX ; BI++) : de (1 à L_DX) <=> de (L_DX-1 à 0)
	; BI , L_DX  sur 16 bits
		
		ld a,(L_DX)
		ld h,a
		ld a,(L_DX+1)
		ld l,a
		dec HL
		ld a,h
		ld (BI),a
		ld a,l
		ld (BI+1),a		 
		
	Boucle_FOR_16:
		ld a,(BI)
		ld e,a
		ld a,(BI+1)
		OR e 
	JP z,FinDrawLine_16 							; fin du FOR si BI = $0000

			
		; Pour les nombres de 16 bits, il suffit de tester le bit 7 de l’octet de poids fort.
		Boucle_While_16:  
		; ##########################
		; tant que  V >= 0 (positif)
		; ##########################
		; V is a 16 bits value
			
			ld a,(V)								; ne pas utiliser  "ld HL,(V)" car ddh ← (nn + 1) ddl ← (nn) -> inverserait les valeurs
		; test bit 7:
			bit 7,a									; test si bit 7 (poids fort) est à 1 (negatif) ; ie bit 15 of V (16 bit)
		JP nz,V_negatif_16 							; si bit7 est à 1, alors A est un nombre negatif (flag Z=0) : on sort du While
	
		; ici V positif :
		; TEST ECH >0 ?
			ld a,(ECH)
			OR a
		JP Z,vpositif_ech_0_16						; ECH = 0
			
		; if (ECH=1) : L_X+=S1		
			ld a,(S1)
			ld d,a
			ld a,(S1+1)
			ld e,a
			ld a,(L_X)
			ld b,a
			ld a,(L_X+1)
			ld c,a
			call F_ADD								; DE = DE + BC
			
			ld a,d
			ld (L_X),a
			ld a,e
			ld (L_X+1),a  							; L_X = result from DE
		JP recalcul_V1_16	
								
		; else (ECH=0) : L_Y+=S2
		vpositif_ech_0_16:
			ld a,(S2)
			ld d,a
			ld a,(S2+1)
			ld e,a
			ld a,(L_Y)
			ld b,a
			ld a,(L_Y+1)
			ld c,a
			call F_ADD								; DE = DE + BC
			
			ld a,d
			ld (L_Y),a
			ld a,e
			ld (L_Y+1),a    						; L_Y = result from DE  
				
		; recalcul de V dans les deux cas
		recalcul_V1_16:
		; V=V-2*L_DX
			ld a,(L_DX)
			ld h,a
			ld a,(L_DX+1)
			ld l,a
			add HL,HL								; 2*L_DX
			ld a,(V)
			ld d,a
			ld a,(V+1)
			ld e,a
			ld b,h
			ld c,l
			call F_SUB								; DE = DE - BC  = V - 2*L_DX
			
			ld a,d
			ld (V),a
			ld a,e
			ld (V+1),a 								; V = result from DE
				
		JP 	Boucle_While_16				
		
	; Test if ECH >0 :
	V_negatif_16:
	
		ld a,(ECH)
		OR A
	JP Z,vnegatif_ech_0_16							; ECH = 0
	
	;if (ECH=1) : L_Y+=S2
		ld a,(S2)
		ld d,a
		ld a,(S2+1)
		ld e,a
		ld a,(L_Y)
		ld b,a
		ld a,(L_Y+1)
		ld c,a
		call F_ADD								; DE = DE + BC
		
		ld a,d
		ld (L_Y),a
		ld a,e
		ld (L_Y+1),a   							; L_Y = result from DE

		JP recalcul_V2_16		
				
	; else (ECH=0) : L_X+=S1
	vnegatif_ech_0_16:
		ld a,(S1)
		ld d,a
		ld a,(S1+1)
		ld e,a
		ld a,(L_X)
		ld b,a
		ld a,(L_X+1)
		ld c,a
		call F_ADD								; DE = DE + BC
		
		ld a,d
		ld (L_X),a
		ld a,e
		ld (L_X+1),a  							; L_X = result from DE

	; recalcul de V dans les deux cas
	recalcul_V2_16:
	; V=V+2*L_DY

		ld a,(L_DY)
		ld h,a
		ld a,(L_DY+1)
		ld l,a
		add HL,HL								; 2*L_DY
		ld a,(V)
		ld d,a
		ld a,(V+1)
		ld e,a
		ld b,h
		ld c,l
		call F_ADD								; DE = DE - BC  = V - 2*L_DY
		
		ld a,d
		ld (V),a
		ld a,e
		ld (V+1),a 								; V = result from DE		
	  
	Draw_point_16:

	; Si oui, afficher un point en (LCD_X16,LCD_Y16)
	
		ld DE,(L_X)
		ld (LCD_X16),DE
		ld DE,(L_Y)
		ld (LCD_Y16),DE	 
		call checkNputpixel
						
		ld a,(BI)
		ld h,a
		ld a,(BI+1)
		ld l,a
		dec HL
		ld a,h
		ld (BI),a
		ld a,l
		ld (BI+1),a								; BI = BI - 1 (16 bits value)
	
	JP Boucle_FOR_16
	
	FinDrawLine_16:
	
	pop HL
	pop BC
	pop DE
ret




GenMatProj:										; Update MatriceProj with Scale Value

	push DE
	push BC
			
	; first value	:		
		ld a,(DISTANCE)
		ld d,a
		ld a,(DISTANCE+1)
		ld e,a 
 	
		ld a,(MatriceProj)
		ld b,a
		ld a,(MatriceProj+1)
		ld c,a
			
		call F_MUL								; DE = DE * BC
			
		ld a,d
		ld (MatriceProj),a
		ld a,e
		ld (MatriceProj+1),a			
 
	; second value	:
		ld a,(DISTANCE)
		ld d,a
		ld a,(DISTANCE+1)
		ld e,a
			
		ld a,(MatriceProj+8)
		ld b,a
		ld a,(MatriceProj+9)
		ld c,a
			
		call F_MUL
			
		ld a,d
		ld (MatriceProj+8),a
		ld a,e
		ld (MatriceProj+9),a	

	pop BC
	pop DE
ret			










Display_LOGO_3D_RY_IN:						; Generate and draw 3d LOGO into the screen : rotate/scale it in XYZ for BOUCLE_PTS time 
											; Need a 3D object point list in "MESH"
											; Need a list of line between point in "Line_list"

	push BC
	push DE
	push HL


; ANGLE RAZ :	
	XOR a 	;ld a,4
	ld (ANGLE),a							; Angle de deplacement = 4 (PI/256 *4 = PI/64 degree RAD) pour MESH initial

; NB ITERATION à afficher ( = nb mouvements)
	ld a,15  
	ld (BOUCLE_PTS),a 

; Distance init resized :
	XOR a
	ld (DISTANCE),a
	ld a,$A0
	ld (DISTANCE+1),a	 

	call GenMatProj	
	
; Distance Zoom each loop:
	ld a,1
	ld (DISTANCE),a
	ld a,28
	ld (DISTANCE+1),a		

	boucle_rotation_LOGO_RY_IN:
	
	;COPIE DE MESH DANS MESH2
		ld BC,500									;  500 MAX
		ld HL,MESH
		ld DE,MESH2
	; LDIR : Copie mémoire d'un octet de (HL) vers (DE), puis incrémente HL,DE et décrémente BC ; tant que BC est supérieure à zéro
		LDIR	
		
	; CALCUL MATRICE ROTATION X :		
	;   call GenMatRotX	
	; ROTATION X sur tous les points de MESH :
	 ;  call Rotation_Mesh
		
	; CALCUL MATRICE ROTATION Y :		
	 	call GenMatRotY		
	; ROTATION Y sur tous les points de MESH :
	 	call Rotation_Mesh				
		
	; CALCUL MATRICE ROTATION Z :		
	;   call GenMatRotZ	
	; ROTATION Z sur tous les points de MESH :
	;	call Rotation_Mesh		

	; SCALING sur MESH :   		 DISTANCE: 2 octets ; pour le calcul du scaling	
		call GenMatProj
		
	; PROJECTION et CONVERSION des points 3D -> 2D	:
		call Projection_Mesh_PointPlan 	
	
	; EFFACER L'ECRAN en RAMVIDEO:
	  	call empty_ramvideo

	; AFFICHAGE OBJETS 3D dans VIDEORAM :	 
		call draw_3D_line_16
 
	; AFFICHAGE/RAFRAICHIR ECRAN LCD :		  
		call draw_DISPLAY	
		
	; INCREMENT ANGLE:
		ld a,(ANGLE)
		add 14
		ld (ANGLE),a
	
	; Iteration suivante?
		ld a,(BOUCLE_PTS)
		dec a
		ld (BOUCLE_PTS),a 
		OR a 
	JP nz,boucle_rotation_LOGO_RY_IN

	pop HL
	pop DE
	pop BC	
ret



Display_LOGO_3D_RY:
	push BC
	push DE
	push IX
	push IY
	push HL

	; NB ITERATION à afficher (= nb mouvements)
		ld a,4  
		ld (BOUCLE_PTS),a	

	boucle_rotation_LOGO_RY:
	;COPIE DE MESH DANS MESH2
		ld BC,500									;  500 MAX
		ld DE,MESH2
		ld HL,MESH
	; LDIR :	 Copie mémoire d'un octet de (HL) vers (DE), puis incrémente HL,DE et décrémente BC ; tant que BC est supérieure à zéro
		LDIR

	; CALCUL MATRICE ROTATION Y :		
	  	call GenMatRotY
		
	; ROTATION Y sur tous les points de MESH :
	 	call Rotation_Mesh	

	; PROJECTION et CONVERSION des points 3D -> 2D	:
		call Projection_Mesh_PointPlan

	; EFFACER L'ECRAN en RAMVIDEO:
	  	call empty_ramvideo

	; AFFICHAGE OBJETS 3D dans VIDEORAM :	 
		call draw_3D_line_16
 
	; AFFICHAGE/RAFRAICHIR ECRAN LCD :		  
		call draw_DISPLAY		 

	; INCREMENT ANGLE:
		ld a,(ANGLE)
		add 14
		ld (ANGLE),a
		
	; Iteration suivante?
		ld a,(BOUCLE_PTS)
		dec a
		ld (BOUCLE_PTS),a 
		OR a 
	JP nz,boucle_rotation_LOGO_RY

	pop HL
	pop IY
	pop IX
	pop DE
	pop BC	
ret




Display_TORE_3D_RXYZ_L_2_C:

	push BC
	push DE
	push IX
	push IY
	push HL

	; ANGLE RAZ :	
		XOR a
		ld (ANGLE),a								; Angle de deplacement = 4 (PI/256 *4 = PI/64 degree RAD) pour MESH initial
	
	; DISTANCE X et Y ; INIT SHIFT VALUE LEFT (out of LCD screen):
	;	ld a,$EE   									; -18?
	;	ld (slideX),a
		
	; NB FRAMES	à afficher (mouvements)
		ld a,18  
		ld (BOUCLE_PTS),a		

	; copy MESH2 in MESH 
		; ld BC,500									;  500 MAX
		; ld DE,MESH		
		; ld HL,MESH2
		; LDIR
		
	boucle_tore:
	
	;COPIE DE MESH DANS MESH2
		ld BC,500									;  500 MAX
		ld HL,MESH
		ld DE,MESH2
		LDIR

	    call GenMatRotX	
		call Rotation_Mesh
		
	; CALCUL MATRICE ROTATION Y :		
	  	call GenMatRotY
	; ROTATION Y sur tous les points de MESH :
		call Rotation_Mesh	
		
	    call GenMatRotZ	
		call Rotation_Mesh

  	; faire entrer le TORE depuis la droite 	
	; pour tout point X de MESH2 : X = X +1 
		ld IX,MESH2
		ld a,(IX)									; nb points 
		ld b,a
		boucle_depl_ball_2:
			ld a,(IX)								; position on X
			ld h,a 
			ld a,(IX+1)
			ld l,a
			ld d,0
			ld a,(slideX)
			ld e,a
			add HL,DE
			ld (IX),h
			ld (IX+1),l
			inc IX
			inc IX									; position on Y	
			inc IX
			inc IX									; position on Z
			inc IX
			inc IX									; position on the next X (n+1)
		djnz boucle_depl_ball_2			 
	 

	; PROJECTION et CONVERSION des points 3D -> 2D	:
		call Projection_Mesh_PointPlan

	; EFFACER L'ECRAN en RAMVIDEO:
	  	call empty_ramvideo
		
	; AFFICHAGE OBJETS 3D dans VIDEORAM :	 
		call draw_3D_line_16
		
	; AFFICHAGE/RAFRAICHIR ECRAN LCD :		  
		call draw_DISPLAY			 

	; INCREMENT ANGLE:
		ld a,(ANGLE)
		add 8
		ld (ANGLE),a
		
	; INCREMENT SLIDEX :
		ld a,(slideX)
		inc a
		inc a
		ld (slideX),a	
		
	; Iteration
		ld a,(BOUCLE_PTS)
		dec a
		ld (BOUCLE_PTS),a 
		OR a 
	JP nz,boucle_tore

	pop HL
	pop IY
	pop IX
	pop DE
	pop BC
ret



Display_TORE_3D_ROTATION:
	push BC
	push DE
	push IX
	push IY
	push HL

	; NB ITERATION à afficher (= nb mouvements)
		ld a,26  
		ld (BOUCLE_PTS),a	
	; ANGLE RAZ :	
		XOR a
		ld (ANGLE),a								; Angle de deplacement = 4 (PI/256 *4 = PI/64 degree RAD) pour MESH initial

	boucle_rotation_TORE:
	;COPIE DE MESH DANS MESH2
		ld BC,500									;  500 MAX
		ld DE,MESH2
		ld HL,MESH
	; LDIR :	 Copie mémoire d'un octet de (HL) vers (DE), puis incrémente HL,DE et décrémente BC ; tant que BC est supérieure à zéro
		LDIR

	    call GenMatRotX	
		call Rotation_Mesh
		
	; CALCUL MATRICE ROTATION Y :		
	 ; 	call GenMatRotY
	; ROTATION Y sur tous les points de MESH :
	;	call Rotation_Mesh	
		
	    call GenMatRotZ	
		call Rotation_Mesh

	; PROJECTION et CONVERSION des points 3D -> 2D	:
		call Projection_Mesh_PointPlan

	; EFFACER L'ECRAN en RAMVIDEO:
	  	call empty_ramvideo

	; AFFICHAGE OBJETS 3D dans VIDEORAM :	 
		call draw_3D_line_16
 
	; AFFICHAGE/RAFRAICHIR ECRAN LCD :		  
		call draw_DISPLAY		 

	; INCREMENT ANGLE:
		ld a,(ANGLE)
		add 5
		ld (ANGLE),a
		
	; Iteration suivante?
		ld a,(BOUCLE_PTS)
		dec a
		ld (BOUCLE_PTS),a 
		OR a 
	JP nz,boucle_rotation_TORE

	pop HL
	pop IY
	pop IX
	pop DE
	pop BC	
ret







GenSINUS:								; Calcul le sinus de 64 valeurs 16 bits et le place dans TABLE_SINUS 
										; pour : Angle(RAD) = [0 -> PI/2] ; apres on perds trop de precision sur 16 bits
										; TEMP , MULTEMP & PI_X : 8.8 bit signed fixed value required

	push BC
	push DE
	push HL	 
	push IX
 
										; table_sin[x] = x - (x*x*x)/6 + (x*x*x*x*x)/120  rem : (x*x*x*x*x)/120 = ( (x*x*x)/6 ) * x*x/20
 ; ex : Sin(PI/2) =  1,57079 - 0,6459640 + 0,079692 = 1,004518 (soit 1)


	; boucle 64 valeurs : for (x=0, x<=PI/2, x+=PI/128) :
	ld b,$40							; 64 value of 16 bits = 128 bytes : TABLE_SINUS[0] ->  TABLE_SINUS[126]
	ld HL,TABLE_SINUS
	XOR a
	ld (PI_X),a   
	ld (PI_X+1),a 
	boucle_1_SIN_256: 
		
		push BC 
				
		;##### (x*x*x)/6 substract from TEMP (<!> a ne pas depasser 128 pendant les calculs)
		; X * X :
		ld a,(PI_X)		
		ld d,a
		ld a,(PI_X+1)
		ld e,a				
		ld b,d
		ld c,e
		call F_MUL						; DE = DE*BC
		
		; divisé par 6 :
		ld b,d
		ld c,e 
		ld DE,$0600
		call F_DIV						; DE = BC/DE
		
		; multiplié par X
		ld a,(PI_X)
		ld b,a
		ld a,(PI_X+1)
		ld c,a		 
		call F_MUL 					 
		

		ld a,d
		ld (MULTEMP),a
		ld a,e
		ld (MULTEMP+1),a				; on le garde pour le prochain calcul
		
		; PI_X - resultat précedent -> TEMP  
		ld b,d
		ld c,e
		ld a,(PI_X)
		ld d,a
		ld a,(PI_X+1)
		ld e,a
		call F_SUB  					; DE = DE - BC
		
		ld a,d
		ld (TEMP),a
		ld a,e
		ld (TEMP+1),a		
		
		;##### (x*x*x*x*x)/120  = MULTEMP *X*X/20 	

		; MULTEMP divisé par 20 :
		ld a,(MULTEMP)			 
		ld b,a
		ld a,(MULTEMP+1)
		ld c,a
		ld DE,$1400						; 20 
		call F_DIV			
		

		; multiplié par X * X :
		ld a,(PI_X)		
		ld b,a
		ld a,(PI_X+1)
		ld c,a			
		call F_MUL
		ld a,(PI_X)
		ld b,a
		ld a,(PI_X+1)
		ld c,a		 
		call F_MUL

 
		; resultat temp + resultat précedent -> HL / HL+1
		ld a,(TEMP)
		ld b,a
		ld a,(TEMP+1)
		ld c,a
		call F_ADD						; DE = DE + BC		

		ld a,d
		ld (HL),a
	 ld (TEMP),a
		inc HL
		ld a,e
		ld (HL),a
	 ld (TEMP+1),a			
		inc HL 

		; increment x   dans PI_X :
		; PI/128 = 0,02454369260 	= $00.$06   
		; PI/32  = 0,098174770424 	= $00.$19
		; PI/16  = 0,196349540	 	= $00.$32
		; PI/4 	 = 0,78515625 	 	= $00.$c9
		
		ld a,(PI_X)
		ld d,a
		ld a,(PI_X+1)
		ld e,a
		ld BC,$0006
		call F_ADD
 	
		ld a,d
		ld (PI_X),a
		ld a,e
		ld (PI_X+1),a 

		
		pop BC

		dec b
	jp nz,boucle_1_SIN_256


		
	; boucle sur les 64 valeurs suivantes : for (x=(PI/2)+$0006, x<=PI, x+=PI/128) 
	; on prends la valeur de sin((PI/2)-PI_X) et on la copie dans sin((PI/2)+PI_X) 
	; donc pour (i = 0, i<64, i++) on prends la valeur (16 bits) de TABLE_SINUS[126-i*2] et on la copie dans TABLE_SINUS[128+i*2]
	ld b,$40							; 64 valeurs  : 128 bytes : TABLE_SINUS[128] ->  TABLE_SINUS[254]
	ld c,0
	boucle_2_SIN_256:
	
		; recuperation de la valeur TABLE_SINUS[128-i*2] :
		ld HL,TABLE_SINUS
		ld a,126
		sub c
		ld e,a
		ld d,0
		add HL,DE
		ld a,(HL)
		ld (TEMP),a
		inc HL
		ld a,(HL)
		ld (TEMP+1),a 
		; copie de la valeur dans TABLE_SINUS[128+i*2] :
		ld HL,TABLE_SINUS
		ld a,128		
		add c
		ld e,a
		ld d,0
		add HL,DE
		ld a,(TEMP)
		ld (HL),a
		inc HL
		ld a,(TEMP+1)
		ld (HL),a

		
		inc c	
		inc c
	
	djnz boucle_2_SIN_256 

		
	; boucle sur les 128 valeurs suivantes : for (x=(PI)+$0006, x<=2PI, x+=PI/128) 
	; on prends la valeur de sin(0+PI_X) et on la copie dans sin((PI)+PI_X) 
	; donc pour (i = 0, i<128, i++ ) on prends la valeur (16 bits) de TABLE_SINUS[0+i*2] on l'inverse et on la copie dans TABLE_SINUS[256+i*2]
	ld b,$80							; 128 valeurs : 128 bytes : TABLE_SINUS[256] ->  TABLE_SINUS[510]
	ld c,0
	boucle_3_SIN_256:	

	;on prends la valeur (16 bits) de TABLE_SINUS[0+i]
		ld H,0
		ld l,c
		add HL,HL						; c*2
		ld d,h
		ld e,l
		ld HL,TABLE_SINUS
		add HL,DE	

	; on inverse la valeur
		push BC
		ld b,(HL)
		inc HL
		ld c,(HL)	
		ld DE,$0000						; 0.0						
		
		call F_SUB						; DE = DE - BC
		pop BC
		
		ld a,d
		ld (TEMP),a
		ld a,e
		ld (TEMP+1),a 	
	
	;on la copie dans TABLE_SINUS[256+i]
		ld H,0
		ld l,c
		add HL,HL					; c*2
		ld DE,256
		add HL,DE
		ld d,h
		ld e,l
		ld HL,TABLE_SINUS
		add HL,DE	

		ld a,(TEMP)
		ld (HL),a
		inc HL
		ld a,(TEMP+1)
		ld (HL),a	
	
		inc c
	
	djnz boucle_3_SIN_256
 

	pop IX
	pop HL
	pop DE
	pop BC
ret



GenCOSINUS:								; Calcul le cosinus de 64 valeurs 16 bits et le place dans TABLE_COSINUS
										; TEMP , MULTEMP & PI_X : 8.8 bit signed fixed value required

	push BC
	push DE
	push HL	 
	push IX
 
										; table_cos[x] = 1 - (x*x)/2 + (x*x*x*x)/24
										; Or : table_cos = table_sin shift by PI/2 ; i.e. shift from 1/4 size of tablesinus[]
ld a,16
ld (CURX),a

	; boucle valeurs = 256 - 64 = 192
	ld b,$c0							; 192
	ld c,0
 
	boucle_1_COS_256: 
 
 		ld h,0
		ld l,c 
		add hl,hl
		ld DE,128						; TABLE_SINUS + 64 *2 bytes
		add HL,DE 
		ld d,h
		ld e,l		
		ld HL,TABLE_SINUS
		add HL,DE
		
		; copier la valeur 16 bits
		ld a,(HL)
		ld (TEMP),a
		inc HL
		ld a,(HL)
		ld (TEMP+1),a 			

		ld h,0
		ld l,c		
		add hl,hl
		ld d,h
		ld e,l
		ld HL,TABLE_COSINUS
		add HL,DE
		
		; coller valeur 16 bits
		ld a,(TEMP)
		ld (HL),a
		inc HL
		ld a,(TEMP+1)
		ld (HL),a			
	 
		inc c 							; c [0-191]
 
	djnz boucle_1_COS_256

	; les 64 dernieres valeurs de table_cosinus = 64 premieres valeurs de table_sinus :


	ld b,$40							; 64
	ld c,0
 
	boucle_2_COS_256: 
 		ld h,0
		ld l,c 
		add hl,hl
		ld d,h
		ld e,l
		ld HL,TABLE_SINUS
		add HL,DE
		
		; copier la valeur 16 bits
		ld a,(HL)
		ld (TEMP),a
		inc HL
		ld a,(HL)
		ld (TEMP+1),a 			

		
		ld h,0
		ld l,c
		add hl,hl
		ld DE,384
		add HL,DE  								; TABLE_COSINUS + 192 *2	
		ld d,h
		ld e,l
		ld HL,TABLE_COSINUS
		add HL,DE
		
		; coller valeur 16 bits
		ld a,(TEMP)
		ld (HL),a
		inc HL
		ld a,(TEMP+1)
		ld (HL),a			
	 
		inc c 									; c [0-63]
 
	djnz boucle_2_COS_256
	
 
	pop IX
	pop HL
	pop DE
	pop BC
ret




;####################################################################################
;############ ELLIPSE FUNCTIONS #####################################################
;####################################################################################


ellipse:							; Genere une Ellipse dans le RAM Buffer
									; Parametres : 
									; RAYA , RAYB : [0-255]
									; CENTERX , CENTERY :	[0,255]
									; INCREMENT_ANGLE, NB_LOOP : [0-255]

	push HL
	push BC
	push DE

	XOR a
	ld (ANGLE),a					; ANGLE = 0
	
	ld a,(INCREMENT_ANGLE)
	ld D,a
	ld C,$ff	
	call F_DIV_8bit 				; INPUT	: C / D     |    OUTPUT	: C = result, A = rest ; B used.
	ld a,C
	ld (NB_LOOP),a	 

	Boucle_Ellipse:
	
	; COS[ANGLE) :
		ld a,(ANGLE)	
		ld h,0
		ld l,a
		add HL,HL					; *2
		ld d,h
		ld e,l	
		ld HL,TABLE_COSINUS 		
		add HL,DE	 				; DE = pointeur dans la table COSINUS 
		
		ld a,(HL)
		ld D,a 
		inc HL
		ld a,(HL)
		ld E,a  					; DE contient le COS(ANGLE) [-1,1]
		ld a,(RAYA)
		ld B,a
		ld C,0
		call F_MUL					; DE = DE * BC (format 8.8) = RAYA * COS(ANGLE)	    
	
		ld a,(CENTERX) 				; 3F (=63)
		add D						; CENTERX + (RAYA * COS(ANGLE))				
		ld (LCD_COOX),a

	;SIN(ANGLE) :
		ld a,(ANGLE)	
		ld h,0
		ld l,a
		add HL,HL
		ld d,h
		ld e,l	
		ld HL,TABLE_SINUS 	 		; DE = pointeur dans la table SINUS
		add HL,DE
		ld a,(HL)	
		ld D,a
		inc HL
		ld a,(HL)
		ld E,a   					; DE contient le SIN(ANGLE) [-1,1]
		ld a,(RAYB)
		ld B,a
		ld C,0
		call F_MUL					; DE = DE * BC (format 8.8) = RAYB * SIN(ANGLE)
		ld a,(CENTERY)
		add D						; CENTERY + (RAYB * SIN(ANGLE))
		ld (LCD_COOY),a
	
	call putpixel					; (LCD_COOX,LCD_COOY)
	
	; INC ANGLE
	ld a,(INCREMENT_ANGLE)
	ld d,a
	ld a,(ANGLE)
	add d
	ld (ANGLE),a

	; Nombre de Boucle pour afficher toute l'Ellipse
	ld a,(NB_LOOP)
	dec a
	ld (NB_LOOP),a	
	OR a
	JP nz,Boucle_Ellipse 

	pop DE
	pop BC
	pop HL
ret



ellipse_dot:								; Affiche les ellipses definies dans la liste TAB_ELLIPSE
											; ALPHA , BETA : 1 byte 
 

	push HL
	push BC
	push DE
	
	ld HL,TAB_ELLIPSE						; LISTE #NB ,[ Cx , Cy , Ra , Rb]+
	ld a,(HL)
	ld (NB_ELLIPSE),a									; nb Ellipse à afficher (i)
; XOR a
; ld (CURX),a
; ld (CURY),a
; push HL
; ld HL,NB_ELLIPSE
; call DISPLAY_FIXED_POINT
; pop HL

	Boucle_ellipse_dot:
		
		inc HL
		ld a,(HL)
		ld (CENTERX),a						; Cix
		inc HL
		ld a,(HL)
		ld (CENTERY),a						; Ciy
		inc HL		
		ld a,(HL)
		ld (RAYA),a							; RAYA = Ria
		inc HL
		ld a,(HL)
		ld (RAYB),a							; RAYB = Rib
 
		push HL
		
		; CENTERX = Cix + ((sin(ALPHA)*(64-Ria))/2)
			ld a,(ALPHA)	
			ld H,0
			ld L,a
			add HL,HL
			ld D,H
			ld E,L	
			ld HL,TABLE_SINUS 	 		; DE = pointeur dans la table SINUS
			add HL,DE
			ld a,(HL)	
			ld D,a
			inc HL
			ld a,(HL)
			ld E,a   					; DE contient le SIN(ALPHA) [-1,1]
			
			ld a,(RAYA)
			ld C,a
			ld a,64
			sub C						; a=64-Raya			
			 
			ld B,a
			ld C,0
			call F_MUL					; DE = DE * BC (format 8.8) =  SIN(ALPHA) * (64-RAYA)
	
			SRA D						; /2
			
			ld a,(CENTERX)
			add D 
			ld (CENTERX),a				;  CENTERX = Cix + (sin(ALPHA)*(64-Ria))

		; CENTERY = C1y + ((cos(beta)*(32-R1b))/2)
			ld a,(BETA)	
			ld H,0
			ld L,a
			add HL,HL
			ld D,H
			ld E,L	
			ld HL,TABLE_COSINUS 	 		; DE = pointeur dans la table COSINUS
			add HL,DE
			ld a,(HL)	
			ld D,a
			inc HL
			ld a,(HL)
			ld E,a   					; DE contient le COS(BETA) [-1,1]
			
			ld a,(RAYB)
			ld C,a
			ld a,32
			sub C						; a=32-Rayb			
			 
			ld B,a
			ld C,0
			call F_MUL					; DE = DE * BC (format 8.8) =  COS(BETA) * (32-RAYB)
	
			SRA D 						; /2

			ld a,(CENTERY)
			add D
			ld (CENTERY),a				;  CENTERY = Ciy + (cos(BETA)*(32-Rib))		

			; generation de l'ellipse (i) :
			call ellipse
		
		pop HL
		
		ld a,(NB_ELLIPSE)
		dec a
		ld (NB_ELLIPSE),a
		OR a
	JP nz,Boucle_ellipse_dot
	
	pop DE
	pop BC
	pop HL	
ret	
	

ellipse_moving:								; Affiche les ellipses definies dans la liste TAB_ELLIPSE_MOV 
											 
	push HL
	push BC
	push DE
	
	
	ld HL,TAB_ELLIPSE_MOV					; LISTE #NB ,[ Cx ,  Cy , direction(0 = monte  1=descend ), vitesse(0-10), Rb , Angle , Ra, ]+
	ld a,(HL)
	ld (NB_ELLIPSE),a						; nb Ellipse à afficher (i)
	inc HL
											;  Angle : Ra + (sin(Angle))*30 

	Boucle_ellipse_move:		
	
		ld a,(HL)
		ld (CENTERX),a						; Cx
		inc HL
		ld a,(HL)
		ld (CENTERY),a						; Cy		
		
		inc HL								; direction
		
		
		; test CenterY
		; lorsque Cy=54 , -> direction = 0
		; lorsque Cy=12 , -> direction = 1

		ld a,(CenterY)
		CP 54								; Si A>=N alors C=0
		jp NC,direction_zero

		ld a,(CenterY)
		CP 12								; Si A<N alors C=1
		jp C,direction_un
		
		jp suite_ellipse_move_1
		
		direction_zero:		
		XOR a
		ld (HL),a		
		jp suite_ellipse_move_1
		
		direction_un:
		ld a,1
		ld (HL),a	
		

		suite_ellipse_move_1: 
		inc HL
		ld a,(HL)							; vitesse
		ld D,a
		dec HL
		ld a,(HL)							; direction
		OR a								; si direction = 0
		JP z, decremente_CenterY
		
		increment_centerY:	
			dec HL 							;Cy
			ld a,(HL)
			add D
			ld (HL),a		
		
		jp suite_ellipse_move_2
		
		decremente_CenterY:
			dec HL 							;Cy
			ld a,(HL)
			sub D
			ld (HL),a	
		
		suite_ellipse_move_2:
		
		inc HL 		
		inc HL		
		inc HL
		ld a,(HL)
		ld (RAYB),a							; RAYB = Rib
		inc HL
		ld a,(HL)
		ld (ANGLE),a						; Angle
		add 16
		ld (HL),a
		inc HL

		
		push HL
		; RAYA = RAYA + (sin(Angle))*30 
			ld a,(ANGLE)	
			ld H,0
			ld L,a
			add HL,HL
			ld D,H
			ld E,L	
			ld HL,TABLE_SINUS 	 			; DE = pointeur dans la table SINUS
			add HL,DE
			ld a,(HL)	
			ld D,a
			inc HL
			ld a,(HL)
			ld E,a   						; DE contient le SIN(ANGLE) [-1,1]
			
			ld B,24
			ld C,0
			
			call F_MUL						; DE = DE * BC (format 8.8)

		pop HL

		ld a,(HL)
		add D
		ld (RAYA),a							; RAYA = Ria
		
		inc HL		
		
		
		call ellipse
	 
		ld a,(NB_ELLIPSE)
		dec a
		ld (NB_ELLIPSE),a
		OR a
	JP nz,Boucle_ellipse_move

	

	pop DE
	pop BC
	pop HL	
ret
	


Affiche_Perspective:						; Display image from ROM into the LCD with prespectiv
	push HL
	push BC
	push DE

; INITIALISATION :

	XOR a
	ld (DamierX),a							; DamierX=0 
	ld (StartX),a							; StartX=0
	ld a,63
	ld (StartY),a 							; StartY=63

	call empty_ramvideo
	
	
; BOUCLE :
	boucle_damierY:
	
		XOR a
		ld (DamierX),a							; DamierX=0

; StartX=(63-StartY)/2		
		ld a,(StartY)
		ld D,a
		ld a,63
		sub D
		srl a
		ld (StartX),a							; StartX=(63-StartY)/2

; SautPixel = ( 126/(63+StartY) ) -1
		ld D,63
		ld a,(StartY)
		add D
		ld D,a
		ld E,0
		ld B,126
		ld C,0
		
		Call F_DIV								; DE = BC / DE =  126 / (63+StartY) 
		
		ld a,D
		dec a									; ( 126/(63+StartY) ) -1

; IndiceSautPixel = sautpixel
 	
		ld (SautPixel),a
		ld (IndiceSautPixel),a
		ld a,E
		ld (SautPixel+1),a
		ld (IndiceSautPixel+1),a				

; Do 
	boucle_damierX:

			ld a,(IndiceSautPixel)
			OR a								; if (IndiceSautPixel == 0)
		JP nz,else_IndiceSautPixel	

			call Read_Pixel						; Pixel = Read_Pixel(DamierX,DamierY)

			ld a,(Pixel)
			OR a								; if (Pixel <> 0)
		JP z,pixel_a_zero	
 
			ld a,(StartX)
			ld (LCD_COOX),a
			ld a,(StartY)
			ld (LCD_COOY),a
			call putpixel						; ld Putpixel (StartX,StartY)		
		; }
		pixel_a_zero:
		
		; inc StartX
			ld a, (StartX) 
			inc a
			ld (StartX),a						; inc StartX
		
		; IndiceSautPixel + = sautpixel 
			ld a,(SautPixel)
			ld D,a
			ld a,(SautPixel+1)		
			ld E,a
			ld a,(IndiceSautPixel)
			ld B,a
			ld a,(IndiceSautPixel+1)
			ld C,a
			
			call F_ADD						; DE = DE + BC 
			
			ld a,D								
			ld (IndiceSautPixel),a
			ld a,E
			ld (IndiceSautPixel+1),a		; IndiceSautPixel[2] + = SautPixel[2]			
			
			jp suite_boucle_damierX			
			

		else_IndiceSautPixel:

			ld a,(IndiceSautPixel)
			dec a
			ld (IndiceSautPixel),a				; dec IndiceSautPixel	

	
	suite_boucle_damierX:
	


		ld a,(DamierX)
		inc a
		ld (DamierX),a							; inc DamierX
		
		ld E,a									; E = DamierX
		ld a,128
		SUB E	 
		OR a
; while (x<128)
	jp nz, boucle_damierX						; while (DamierX < 128) 


	

		ld a,(StartY)
		dec a
		ld (StartY),a							; dec StartY
		ld a,(DamierY)
		dec a
		ld (DamierY),a							; dec DamierY
		OR a
		JP Z, Fin_Affiche_Perspective
	
		ld a,(StartY)
		OR A
	JP nz,boucle_damierY						; while (StartY > EmptyLine)	


	Fin_Affiche_Perspective:
	
	pop DE
	pop BC
	pop HL	
ret


Read_Pixel:										; lit un pixel depuis IMAGE_PERSPECTIVE  et utilise DamierX(0-127) et DamierY(0-n) pour trouver la valeur du pixel

	push HL
	push BC
	push DE
	
	ld H,0	
	ld a,(DamierY)
	ld L,a
	ADD HL,HL
	ADD HL,HL
	ADD HL,HL
	ADD HL,HL									; ld HL, DamierY*16   ; 16 octets
	push HL
	pop DE										; DE = HL	
	ld HL,IMAGE_PERSPECTIVE						; @ en ROM
	add HL,DE									; HL = adresse de la ligne de l'image
 
	;  DamierX / 8 :	
	ld a,(DamierX)
	ld C,a
	srl	 a										; a divisé par 2
	srl  a										; a divisé par 4
	srl  a										; a divisé par 8	
	ld D,0
	ld E,a
	add HL,DE									; HL est positionné sur l'adresse de l'octet à lire dans IMAGE_PERSPECTIVE qui contient notre pixel

	sla  a										; a multiplié par 2
	sla  a										; a multiplié par 4
	sla  a										; a multiplié par 8 
	ld B,a
	ld a,C
	sub B										; ACC get the modulo remain in ACC : that's our pixel's position in the byte [0-7]	in (HL)

	ld E,a
	; LIRE le bit qui est en position E dans l'octet present a l'adresse HL :
	ld D,$80  									; d=$80 = %1000 0000		
	shift_Pe:
		xor a
		or e
	jp z,suite_ReadPixel
		dec e
		srl D									; on decal le bit de d, à droite, de 1 position car les pixels sont lues de gauche à droite.
	jp shift_Pe
	
	suite_ReadPixel:
	; le registre D contient la position du bit à lire (1)	
		ld a,(HL)
		AND D
		OR A
		ld (Pixel),a				; 	Pixel = A  // 0 ou 1	
	
	pop DE
	pop BC
	pop HL	
ret

 
 
 

;####################################################################################
;############ DEBBUG FUNCTIONS ###################################################
;####################################################################################

part1_affiche_point:

	boucle_P1_point:
		call delai_250ms			
		ld a,"."
		ld (CHAR),a
		call print_cchar	
		ld a,(CURX)
		add 5
		ld (CURX),a		
		call draw_display	
	djnz boucle_P1_point
ret




DISPLAY_FIXED_POINT:		; Affiche sur l'ecran la valeur (8.8) dans l'ordre (partie entiere.partie fractionnelle) à partir de l'adresse HL
	
 

	; affichage valeur HEXADECIMAL de (HL) :  decimal signé
	; inc HL
	ld a,(HL)
	AND %11110000
	SRL a
	SRL a
	SRL a
	SRL a
	ld (HEXA_VAL),a
	call print_HEX_char	 
 
	ld a,(CURX)
	add 6
	ld (CURX),a
	
	ld a,(HL)
	AND %00001111
	ld (HEXA_VAL),a
	call print_HEX_char	
 
	ld a,(CURX)
	add 6
	ld (CURX),a
	
	; afficher '.'
	ld a,"."
	ld (CHAR),a
	call print_cchar 

	ld a,(CURX)
	add 6
	ld (CURX),a
	
	; affichage valeur HEXADECIMAL de (HL+1) : fraction

	; dec HL
	 inc HL
	ld a,(HL)
	AND %11110000
	SRL a
	SRL a
	SRL a
	SRL a
	ld (HEXA_VAL),a
	call print_HEX_char	

	ld a,(CURX)
	add 6
	ld (CURX),a

	ld a,(HL)
	AND %00001111
	ld (HEXA_VAL),a
	call print_HEX_char	 

	ld a,(CURX)
	add 6
	ld (CURX),a
	
	; afficher ' '
	ld a," "
	ld (CHAR),a
	call print_cchar 

	ld a,(CURX)
	add 6
	ld (CURX),a
	
	call draw_display
 
ret


print_HEX_char:			; print an hexadecimal value [0-9,A-F] , 	 (HEXA_VAL) contient la valeur initiale
 
						; CHARCODE_V: pour convertion de valeur
						;db 48,49,50,51,52,53,54,55,56,57,65,66,67,68,69,70
	push bc
	push hl
	
	ld a,(HEXA_VAL)
	ld c,a
	ld b,0
	ld HL,CHARCODE_V
	add HL,BC
	ld a,(HL)
	ld (CHAR),a	

	call print_cchar 

	pop hl
	pop bc

ret 

CHARCODE_V: 
	 db 48,49,50,51,52,53,54,55,56,57,65,66,67,68,69,70


;###########################################
;##############  INTERNAL DATA  ############
;###########################################


ASCII_TABLE:							; début memoire de la custom table ASCII : 5*6 pixel per char -> (update is indicated by 'x', other has to be done...)
	db $00,$00,$00,$00,$00,$00			; -> 0 / 32 = <SPACE>
	db $08,$08,$08,$08,$08,$00			; -> 1 / 33 = !
	db $14,$14,$14,$00,$00,$00			; -> 2 / 34 = " 
	db $14,$14,$3e,$14,$3e,$00			; -> 3 / 35 = # 
	db $08,$1e,$28,$1c,$0a,$00			; -> 4 / 36 = $
	db $30,$32,$04,$08,$10,$00			; -> 5 / 37 = %	
	db $18,$24,$28,$10,$2a,$00			; -> 6 / 38 = &	
	db $18,$08,$10,$00,$00,$00			; -> 7 / 39 = '	
	db $04,$08,$10,$10,$10,$00			; -> 8 / 40 = (	
	db $10,$08,$04,$04,$04,$00			; -> 9 / 41 = )
	db $00,$08,$2a,$1c,$2a,$00			; -> 10 / 42 = *
	db $00,$08,$08,$3e,$08,$00			; -> 11 / 43 = +
	db $00,$00,$00,$00,$18,$00			; -> 12 / 44 = ,	
	db $00,$00,$1c,$00,$00,$00			; -> 13 / 45 = - X	
	db $00,$00,$00,$0c,$0c,$00			; -> 14 / 46 = . x	
	db $00,$02,$04,$08,$10,$00			; -> 15 / 47 = / x
	db $1e,$16,$12,$1a,$1e,$00			; -> 16 / 48 = 0 x
	db $04,$0C,$04,$04,$04,$00			; -> 17 / 49 = 1 x
	db $1e,$02,$0c,$10,$1e,$00			; -> 18 / 50 = 2 x
	db $1e,$02,$06,$02,$1e,$00			; -> 19 / 51 = 3 x
	db $10,$10,$14,$1e,$04,$00			; -> 20 / 52 = 4 x
	db $1e,$10,$1e,$02,$1e,$00			; -> 21 / 53 = 5 x
	db $1e,$10,$1e,$12,$1e,$00			; -> 22 / 54 = 6 x
	db $1e,$02,$06,$02,$02,$00			; -> 23 / 55 = 7 x
	db $1e,$12,$1e,$12,$1e,$00			; -> 24 / 56 = 8 x
	db $1e,$12,$1e,$02,$1e,$00			; -> 25 / 57 = 9 x
	db $00,$18,$18,$00,$18,$00			; -> 26 / 58 = : 	
	db $00,$18,$18,$00,$18,$00			; -> 27 / 59 = ; 
	db $02,$04,$08,$10,$08,$00			; -> 28 / 60 = <
	db $00,$00,$3e,$00,$3e,$00			; -> 29 / 61 = =
	db $10,$08,$04,$02,$04,$00			; -> 30 / 62 = >	
	db $1c,$22,$02,$04,$08,$00			; -> 31 / 63 = ?
	db $1c,$22,$02,$1a,$2a,$00			; -> 32 / 64 = @	
	db $1e,$12,$1e,$12,$12,$00			; -> 33 / 65 = A x
	db $1c,$14,$1e,$12,$1e,$00			; -> 34 / 66 = B x
	db $1e,$10,$10,$10,$1e,$00			; -> 35 / 67 = C x
	db $1c,$12,$12,$12,$1c,$00			; -> 36 / 68 = D x
	db $1e,$10,$1c,$10,$1e,$00			; -> 37 / 69 = E x
	db $1e,$10,$1c,$10,$10,$00			; -> 38 / 70 = F x
	db $1e,$10,$16,$12,$1e,$00			; -> 39 / 71 = G x
	db $22,$22,$22,$3e,$22,$00			; -> 40 / 72 = H
	db $1e,$04,$04,$04,$1e,$00			; -> 41 / 73 = I x
	db $3e,$08,$08,$08,$08,$00			; -> 42 / 74 = J
	db $12,$14,$18,$14,$12,$00			; -> 43 / 75 = K x
	db $10,$10,$10,$10,$1e,$00			; -> 44 / 76 = L x
	db $12,$1e,$12,$12,$12,$00			; -> 45 / 77 = M x
	db $12,$1a,$16,$12,$12,$00			; -> 46 / 78 = N x
	db $1e,$12,$12,$12,$1e,$00			; -> 47 / 79 = O x
	db $1e,$12,$1e,$10,$10,$00			; -> 48 / 80 = P x
	db $1e,$12,$12,$16,$1e,$00			; -> 49 / 81 = Q x
	db $1e,$12,$1e,$14,$12,$00			; -> 50 / 82 = R x
	db $1e,$10,$0c,$02,$1e,$00			; -> 51 / 83 = S x
	db $3e,$04,$04,$04,$04,$00			; -> 52 / 84 = T x
	db $12,$12,$12,$12,$1e,$00			; -> 53 / 85 = U x
	db $14,$14,$14,$14,$08,$00			; -> 54 / 86 = V x
	db $22,$22,$22,$2a,$36,$00			; -> 55 / 87 = W
	db $22,$22,$14,$08,$14,$00			; -> 56 / 88 = X
	db $22,$22,$22,$14,$08,$00			; -> 57 / 89 = Y
	db $1e,$02,$0c,$10,$1e,$00			; -> 58 / 90 = Z x
	db $00,$00,$3e,$00,$3e,$00			; -> 59 / 91 = [ 
	db $00,$00,$00,$00,$00,$00			; -> 60 / 92 = \ 
	db $00,$00,$3e,$00,$3e,$00			; -> 61 / 93 = ]
	db $00,$00,$00,$00,$00,$00			; -> 62 / 94 = ^ 
	db $00,$00,$00,$00,$00,$00			; -> 63 / 95 = _ 
	

	
Matrice_project:	
	db $01,$00,	$00,$00,	$00,$00			; 1, 0, 0
	db $00,$00,	$01,$00,	$00,$00			; 0, 1, 0
	db $00,$00,	$00,$00,	$00,$00 		; 0, 0, 0
 

MAT_ROT_X:								; MATRICE ROTATION X 
	db $01,$00,	$00,$00,	$00,$00		; 	1	0		0
	db $00,$00,	$ff,$ff,	$ff,$ff		;	0	cos(A)	-sin(A)
	db $00,$00,	$ff,$ff,	$ff,$ff		;	0	sin(A)	cos(A)


MAT_ROT_Y:								; MATRICE ROTATION Y 
	db $ff,$ff,	$00,$00,	$ff,$ff		; 	cos(A)	0	sin(A)
	db $00,$00,	$01,$00,	$00,$00		;	0		1	0
	db $ff,$ff,	$00,$00,	$ff,$ff		;	-sin(A)	0	cos(A)
	
	
MAT_ROT_Z:								; MATRICE ROTATION Z 
	db $ff,$ff,	$ff,$ff,	$00,$00		; 	cos(A)	-sin(A)	0
	db $ff,$ff,	$ff,$ff,	$00,$00		;	sin(A)	cos(A)	0
	db $00,$00,	$00,$00,	$01,$00		;	0		0		1	
						



	