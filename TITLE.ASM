;---
; title.asm - Title routines
;---

	LINKLIST

	include nindef.asm
	include ninref.asm

BANK1	SECTION

;---
; external subroutines
;---
	extern	buffer_slice
	extern	ckstart			;in ROUTINES.ASM
	extern	do_sprite_DMA		;in ROUTINES.ASM
	extern	hide_sprites		;in ROUTINES.ASM
	extern	line0
	extern	line1
	extern	make_track
	extern	palgame
	extern	setVRAMaddr		;in ROUTINES.ASM
	extern	sliceout
	extern	snd_disable		;in ROUTINES.ASM
	extern	snd_enable		;in ROUTINES.ASM
	extern	sndinit			;in PBSOUND.ASM this bank (1)
	extern	sndplay			;in PBSOUND.ASM this bank (1)
	extern	wait_for_start		;in ROUTINES.ASM
	extern	waitnmi			;in ROUTINES.ASM
	extern	waitxnmis		;in ROUTINES.ASM
	extern	waitxlines		;in ROUTINES.ASM
	extern	waitvb			;in ROUTINES.ASM
	extern	write_x_lines		;in ROUTINES.ASM

tracklength	equ	52		;TEST ONLY - must be variables
trackwrap	equ	255-tracklength	;TEST ONLY - must be variables
TRUE		equ	1
FALSE		equ	TRUE-TRUE

;---
; SHOW_TITLE - display the title
;---
show_title
	public	show_title

	lda	nibnksprSH		;save current sprite bank register
	pha				;
	lda	nibnkchrSH		;save current character bank register
	pha				;
	lda	sv_niscrollm
	pha
	lda	sv_niscrollh
	pha

	jsr	TSKvblank		;turn off track output routine
	dw	0
	
	lda	#0			;turn off string out routine
	sta	PICvramflag		;

	jsr	nividoff		;turn video off

	jsr	write_bc		;put title on the screen
	jsr	blank46			;erase the '46' from the side of the car
	jsr	hide_sprites		;push all the sprites off screen

	lda	#0			;show screen 0 with no vertical scroll
	sta	niscrollv		;
	sta	niscrollv+1		;
	sta	sv_niscrollm		;
	sta	sv_niscrollh		;

	jsr	TSKvblank		;show the blue car
	dw	nmibluecar		;
	lda	#1			;text character set
	sta	nibnkchrSH		;
	jsr	waitnmi			;wait for palette & chrset to take hold

	jsr	TSKvblank		;show 'M I N D S C A P E'
	dw	write_mind		;

	jsr	nividon			;video on

	jsr	carcoming		;sound
	jsr	ck4stop			;of this routine
	jsr	TSKvblank		;erase 'M I N D S C A P E'
	dw	write_blnks		;
	jsr	waitnmi			;wait for erase of Mindscape
	lda	#3			;new background character set=3(has car)
	sta	nibnkchrSH		;
	jsr	waitnmi			;wait for switch
	jsr	ck4stop			;of this routine
	jsr	scroll_car		;move the blue car onto screen and off
	jsr	ck4stop			;of this routine
	jsr	cargoing		;sound
	jsr	ck4stop			;of this routine
	ldx	#60			;1 second
	jsr	waitxnmis
	jsr	ck4stop			;of this routine

	jsr	TSKvblank		;show the red car
	dw	nmiredcar		;
	lda	#1			;text character set
	sta	nibnkchrSH		;
	jsr	waitnmi			;wait for palette & chrset to take hold
	jsr	ck4stop			;of this routine

	jsr	TSKvblank		;show 'PRESENTS'
	dw	write_psents
	jsr	ck4stop			;of this routine

	jsr	carcoming		;sound
	jsr	ck4stop			;of this routine
	jsr	TSKvblank		;erase 'PRESENTS'
	dw	write_blnks		;
	jsr	waitnmi			;wait for presents to be erased
	lda	#3			;new background character set=3(has car)
	sta	nibnkchrSH		;
	jsr	waitnmi			;wait for switch
	jsr	ck4stop			;of this routine
	jsr	scroll_car		;move the blue car onto screen and off
	jsr	ck4stop			;of this routine
	jsr	cargoing		;sound
	jsr	ck4stop			;of this routine
	ldx	#30			;1/2 second
	jsr	waitxnmis
	jsr	ck4stop			;of this routine

	lda	#80
	sta	sndspd
	jsr	TSKvblank		;show the magenta car
	dw	nmimagcar		;
	jsr	ck4stop			;of this routine
	jsr	scroll_car		;move the magenta car onto screen & off
	jsr	ck4stop			;of this routine
	ldx	#5			;1/12 second
	jsr	waitxnmis
	jsr	ck4stop			;of this routine

	lda	#100
	sta	sndspd
	jsr	TSKvblank		;show the yellow car
	dw	nmiyelcar		;
	jsr	ck4stop			;of this routine
	jsr	scroll_car		;move the yellow car onto screen and off
	jsr	ck4stop			;of this routine
	ldx	#5			;1/12 second
	jsr	waitxnmis
	jsr	ck4stop			;of this routine

	lda	#90
	sta	sndspd
	jsr	TSKvblank		;show the blue car
	dw	nmibluecar		;
	jsr	ck4stop			;of this routine
	jsr	scroll_car		;move the blue car onto screen and off
	jsr	ck4stop			;of this routine
	jsr	cargoing
	jsr	ck4stop			;of this routine

	ldx	#45			;
	jsr	waitxnmis
	jsr	ck4stop			;of this routine
	jsr 	screech

exitts: jsr	TSKvblank		;no vblank routine
	dw 	0			;

	jsr	nividoff		;turn off the video
	lda	#0			;turn off nmi routine
	sta	ninmi			;

;	jsr	buttup			;wait for buttons to be released

	pla
	sta	sv_niscrollh
	pla
	sta	sv_niscrollm

	pla				;get last character bank
	sta	nibnkchrSH		;
	pla				;get last sprite bank
	sta	nibnksprSH		;

	dec	PICvramflag

	dec	ninmi			;nmi routine back on

	rts

;---
; SCROLL_CAR - scroll the big car on screen
;---
scroll_car:
carspd	equ	32
	lda	#0
	sta	xpos

?1:	jsr	waitnmi
	lda	xpos
	clc
	adc	#carspd
	sta	xpos
	sta	sv_niscrollh
	lda	#0			;show screen 0
	sta	sv_niscrollm		;
	inc	sndspd
	inc	sndspd
	inc	sndvol
	jsr	motorsound
	lda	xpos
	cmp	#256-carspd
	bne	?1

	jsr	waitnmi
	jsr	motorsound
	jsr	waitnmi
	jsr	motorsound
	
?2:	jsr	waitnmi
	lda	xpos
	clc
	adc	#carspd
	sta	xpos
	sta	sv_niscrollh
	lda	#1
	sta	sv_niscrollm
	dec	sndspd
	dec	sndspd
	dec	sndspd
	dec	sndspd
	dec	sndspd
	dec	sndvol
	jsr	motorsound
	lda	xpos
	cmp	#256-carspd
	bne	?2

	jsr	waitnmi
	lda	#0			;show screen 0 (car gone)
	sta	sv_niscrollm		;
	sta	sv_niscrollh

	lda	#$12			;default volume for engine sound
	sta	sndvol

	rts

;---
; BLANK46 - erase car number from the DOT car
;---
blank46:
	ldx	#15			;top/left edge of 46
	stx	xpos			;
	ldy	#20			;
	sty	ypos			;

	jsr	waitvb			;wait for vertical blank

?1:	ldx	xpos			;erase the 46 for the car
	ldy	ypos			;
	jsr	setVRAMaddr		;
	lda	#98			;blank 'green' square
	ldx	#5			;6 blank characters
?2:	sta	nivramdata		;thru the peephole
	dex
	bpl	?2
	inc	ypos
	lda	ypos
	cmp	#24			;rows 20 thru 23
	bne	?1
	rts

;---
; MOTORSOUND - make the motor sound
;---
motorsound:
	lda	sndvol
	sta	nidutyA

	lda	#0
	sta	tmp+1

	lda	sndspd
	asl	a
	rol	tmp+1
	sta	tmp

	lda	#0
	sec
	sbc	tmp
	sta	nifreqlA
	lda	#4
	sbc	tmp+1
	sta	nifreqhA
?motoroff
	rts

;---
; CARCOMING - raise frequency for coming car
;---
carcoming:
	lda	#$12			;motor volume
	sta	sndvol
	lda	#35
	sta	sndspd
	ldx	#60
?1	jsr	waitnmi
	jsr	motorsound
	inc	sndspd
	dex
	bne	?1
	rts

;---
; CARGOING - lower frequency for leaving car
;---
cargoing:
	ldx	#30
?1	jsr	waitnmi
	jsr	motorsound
	dec	sndspd
	dec	sndspd
	dex
	bne	?1
	rts

;---
; NMIBLUECAR - sets blue car palette
;---
nmibluecar:
	ldx	#1			;blue palette index
	jsr	set_titpal		;set palette
	rts

;---
; NMIREDCAR - sets red car palette
;---
nmiredcar:
	ldx	#2			;red palette index
	jsr	set_titpal		;set palette
	rts

;---
; NMIMAGCAR - sets magenta car palette
;---
nmimagcar:
	ldx	#3			;magenta palette index
	jsr	set_titpal		;set palette
	rts

;---
; NMIYELCAR - sets yellow car palette
;---
nmiyelcar:
	ldx	#4			;yellow palette index
	jsr	set_titpal		;set palette
	rts

;---
; WRITE_BC - write the big car into screen 1
;---
write_bc:
	public	write_bc
	ldx	#0			;palette for '46' car
	jsr	set_titpal		;establish the title palette

	lda	#<niscreen0		;clear screen 0
	sta	VRAMbase		;
	lda	#>niscreen0		;
	sta	VRAMbase+1		;
	ldx	#0			;
	ldy	#0			;
	jsr	setVRAMaddr		;
	jsr	niscrclr_any		;

	lda	#<niscreen1		;set working screen
	sta	VRAMbase		;
	lda	#>niscreen1		;
	sta	VRAMbase+1		;

	ldx	#0			;clear screen 1
	ldy	#0			;
	jsr	setVRAMaddr		;
	jsr	niscrclr_any		;

	jsr	color_car		;establish the color memory

	ldx	#0			;set 'cursor' to mid screen
	ldy	#16			;
	jsr	setVRAMaddr		;
	lda	#<big_car		;prime the source pointer
	sta	tvtmp			;
	lda	#>big_car		;
	sta	tvtmp+1			;
	ldx	#9			;number of lines to move
	jsr	write_x_lines		;
	rts

;---
; SET_TITPAL - set the title palette
;---
set_titpal:
	public	set_titpal

	lda	#>nipal			;set VRAM address to palette area
	sta	nivramaddr		;
	lda	#<nipal			;
	sta	nivramaddr		;

	lda	paladdrslo,x		;set palette to xreg palette
	sta	tvtmp			;
	lda	paladdrshi,x		;
	sta	tvtmp+1			;
	ldx	#1			;number of lines to move
	jsr	write_x_lines		;
	rts

;---
; WRITE_MIND
;---
write_mind:
	lda	#<niscreen0		;into screen 0
	sta	VRAMbase		;
	lda	#>niscreen0		;
	sta	VRAMbase+1		;
	ldx	#0			;
	ldy	#8			;
	jsr	setVRAMaddr		;

	lda	#<mind			;word 'M I N D S C A P E'
	sta	tvtmp			;
	lda	#>mind			;
	sta	tvtmp+1			;
	ldx	#1			;
	jsr	write_x_lines		;
	rts

;---
; WRITE_BLNKS
;---
write_blnks:
	lda	#<niscreen0		;into screen 0
	sta	VRAMbase		;
	lda	#>niscreen0		;
	sta	VRAMbase+1		;
	ldx	#0			;
	ldy	#8			;
	jsr	setVRAMaddr		;

	lda	#<blnks			;blank line
	sta	tvtmp			;
	lda	#>blnks			;
	sta	tvtmp+1			;
	ldx	#1			;
	jsr	write_x_lines		;
	rts

;---
; WRITE_PSENTS
;---
write_psents:
	lda	#<niscreen0		;into screen 0
	sta	VRAMbase		;
	lda	#>niscreen0		;
	sta	VRAMbase+1		;
	ldx	#0			;
	ldy	#8			;
	jsr	setVRAMaddr		;

	lda	#<psents		;word 'PRESENTS'
	sta	tvtmp			;
	lda	#>psents		;
	sta	tvtmp+1			;
	ldx	#1			;
	jsr	write_x_lines		;
	rts

;---
; COLOR_CAR - set title car color memory
;---
color_car:
	lda	#>niscreen1+(32*30)+47	;set VRAM address to palette area
	sta	nivramaddr		;
	lda	#<niscreen1+(32*30)+47	;
	sta	nivramaddr		;
	
	lda	#$04			;for circle on left rear quarter panel
	sta	nivramdata

	lda	#>niscreen1+(32*30)+45	;set VRAM address to palette area
	sta	nivramaddr		;
	lda	#<niscreen1+(32*30)+45	;
	sta	nivramaddr		;
	
	lda	#$C0			;for decal on yellow (by left rear tire)
	sta	nivramdata

	lda	#>niscreen1+(32*30)+43	;decals just behind front left tire
	sta	nivramaddr		;
	lda	#<niscreen1+(32*30)+43	;
	sta	nivramaddr		;
	
	lda	#$51			;front wheel
	sta	nivramdata

	lda	#>niscreen1+(32*30)+41	;set VRAM address to palette area
	sta	nivramaddr		;
	lda	#<niscreen1+(32*30)+41	;
	sta	nivramaddr		;
	
	lda	#$10			;front quarter panel
	sta	nivramdata

	lda	#>niscreen1+(32*30)+32	;light green reflections
	sta	nivramaddr		;
	lda	#<niscreen1+(32*30)+32	;
	sta	nivramaddr		;
	lda	#$80			;hood
	sta	nivramdata
	lda	#$A0			;hood
	sta	nivramdata
	lda	#>niscreen1+(32*30)+39
	sta	nivramaddr
	lda	#<niscreen1+(32*30)+39
	sta	nivramaddr
	lda	#$20			;trunk	(39)
	sta	nivramdata
	lda	#$AA			;hood	(40)
	sta	nivramdata
	lda	#$12			;hood	(41)
	sta	nivramdata
	lda	#>niscreen1+(32*30)+48
	sta	nivramaddr
	lda	#<niscreen1+(32*30)+48
	sta	nivramaddr
	lda	#$AA			;hood
	sta	nivramdata

	rts

;---
; WAITLOOP - wait xreg 150 loops
;---
waitloop:
	ldy	#150
?1	dey
	bne	?1
	dex
	bne	waitloop
	rts

;---
; SCREECH - 46 in
;---
screech:
	jsr	TSKvblank
	dw 	0			;no vblank routine

	sta	PICvramflag

	sta	xpos
	sta	niscrollv
	sta	sv_niscrollm
	sta	niscrollm
	sta	niscrolll
	sta	ninmi			;turn off interrupt routine

	lda	#$FF			;push DOT logo off screen
	sta	sv_niscrollh
	sta	niscrollh

	jsr	nividoff

	jsr	write_bc		;into screen 1
	jsr	write_logo		;into screen 0

	ldx	#0			;write color memory
	ldy	#30			;
	jsr	setVRAMaddr		;
	ldx	#32			;
	lda	#$FF			;
?1:	sta	nivramdata		;
	dex				;
	bne	?1			;

	jsr	nividon
	dec	ninmi			;turn on int

	ldy	#20
	jsr	holdlogo
	jsr	TSKvblank
	dw 	0			;no vblank routine

	lda	#$07			;4=repeat 6=sampling speed
	sta	niwre0
	lda	#$f2			;skid sound data at $fc80
	sta	nideltaddr
	lda	#$34			;length
	sta	nideltcntr
	lda	#00
	sta	nideltdata
	lda	#$0f			;trigger
	sta	niwrst
	lda	#$1f
	sta	niwrst

	ldy	#4
	jsr	holdlogo

	lda	#12			;pit entry speed
	sta	xspeedh
	lda	#0
	sta	xspeedl
?rollin
	jsr	waitnmi			;wait for vertical blank
	ldx	#120			;wait for '112' scan lines KNOB
	jsr	waitxlines		;
	lda	xspeedl
	sec
	sbc	#$40			;decelerarion rate
	sta	xspeedl
	lda	xspeedh
	sbc	#0
	sta	xspeedh

	ldx	#2			;switch to big car character set
	lda	#3
	jsr	nibnkchr

	sec				;move DOT logo in from left
	lda	sv_niscrollh		;
	sbc	xspeedh			;
	sta	sv_niscrollh		;

	lda	niscrolll		;move car in from right
	clc				;
	adc	xspeedl			;
	lda	xpos			;
	adc	xspeedh			;
	sta	xpos			;
	sta	niscroll		;hardware: split screen
	lda	#0			;
	sta	niscroll		;

	lda	xpos
	cmp	#$fe
	bcc	?rollin

	lda	#0			;play tune 0
	jsr	sndinit			;

?wait	ldy	#1			;show a the logo screen once
	jsr	holdlogo		;

	jsr	sndplay			;can music player

	jsr	ckbuttons		;any key pressed?
	lda	startdown		;
	bne	?wait			;

	lda	#0			;turn off music
	sta	niwrst
	lda	#$0f
	sta	niwrst
	rts

;---
; WRITE_LOGO - write DOT logo graphic into the screen
;---
write_logo:
	public	write_logo
	jsr	nividoff		;screen off

	lda	#<niscreen0		;clear screen 0
	sta	VRAMbase		;
	lda	#>niscreen0		;
	sta	VRAMbase+1		;
	jsr	niscrclr		;

	ldx	#0			;position to logo start
	ldy	#3			;
	jsr	setVRAMaddr		;
	lda	#<logomap		;prime the source pointer
	sta	tvtmp			;
	lda	#>logomap		;
	sta	tvtmp+1			;
	ldx	#11			;number of lines to move
	jsr	write_x_lines		;

	lda	#6
	sta	nibnksprSH
	lda	#7			;set proper character bank for DOT logo
	sta	nibnkchrSH		;
	jsr	nividon			;

	rts

;---
; HOLDLOGO - show title screen yreg counts
;---
holdlogo:
	sty	ycount			;number of frames to stay here

?1	jsr	waitnmi			;wait for vertical blank
	ldx	#120			;wait for '120' scan lines KNOB
	jsr	waitxlines		;

	ldx	#2
	lda	#3			;switch to big car character bank
	jsr	nibnkchr

	lda	xpos
	sta	niscroll		;hardware: split screen
	lda	#0			;
	sta	niscroll		;

	dec	ycount
	bne	?1

	rts

;---
; CKBUTTONS - see if any key is pressed
;---
ckbuttons:
	lda	#1			;assume start is not pressed
	sta	startdown		;
	ldy	#0			;joystick 0
	jsr	nijoyget		;update nijoy with current stick 0
	lda	nijoy			;any button pressed?
	beq	cbexit			;no: leave startdown with nonzero
	dec	startdown
cbexit:	rts

;---
; CK4STOP - see title is to be stopped (CALL ONLY FROM SHOW_TITLE!!!!)
;---
ck4stop:
	ldy	#0			;joystick 0
	jsr	nijoyget		;update nijoy with current stick 0
	lda	nijoy			;any button pressed?
	beq	c4exit			;no: leave
	pla				;yes: flush jsr return address
	pla				;
	jmp	exitts
c4exit:	rts

;---
; BUTTUP - wait for all buttons to be released
;---
buttup:
	ldy	#0			;joystick 0
	jsr	nijoyget		;update nijoy with current stick 0
	lda	nijoy			;any button pressed?
	bne	buttup			;yes: wait here
	rts

;---
; palette address table
;---
paladdrslo	db	<titpal,<bluepal,<redpal,<magpal,<yelpal
paladdrshi	db	>titpal,>bluepal,>redpal,>magpal,>yelpal

;---
; TITPAL - title palette data
;---
titpal
	db niblack,$00,$1A,$28		;black	drkgray	green	yellow
	db niblack,$16,$1A,$30		;black	red	green	white
 	db niblack,$00,$1A,$2A		;black	drkgray	green	light green
 	db niblack,$09,$2A,$28		;black	dkgryel	medgrn	yellow
; 	db niblack,$01,$16,$28		;black	drblubl	medred	yellow
; 	db niblack,$16,$30,$28		;black	red	white	yellow

; Sprites
	db niblack,$15,$38,$13
	db niblack,$2c,$38,$1a
	db niblack,$00,$22,$11
	db niblack,$3d,$30,$15

;---
; colored cars palettes
;---
bluepal
	db niblack,$00,$12,$12		;black	drkgray	blue	blue
	db niblack,$16,$12,$30		;black	red	blue	white
 	db niblack,$00,$12,$22		;black	drkgray	blue	light blue
 	db niblack,$16,$30,$28		;black	red	white	blue
; Sprites
	db niblack,$15,$38,$13
	db niblack,$2c,$38,$1a
	db niblack,$00,$22,$11
	db niblack,$3d,$30,$15

redpal
	db niblack,$00,$16,$16		;black	drkgray	red	red
	db niblack,$17,$16,$30		;black	yelred	red	white
 	db niblack,$00,$16,$26		;black	drkgray	red	light red
 	db niblack,$17,$30,$28		;black	yelred	white	red
; Sprites
	db niblack,$15,$38,$13
	db niblack,$2c,$38,$1a
	db niblack,$00,$22,$11
	db niblack,$3d,$30,$15

magpal
	db niblack,$00,$14,$14		;black	drkgray	magenta	magenta
	db niblack,$16,$14,$30		;black	red	magenta	white
 	db niblack,$00,$14,$24		;black	drkgray	magenta	light magenta
 	db niblack,$16,$30,$34		;black	red	white	very light mag.
; Sprites
	db niblack,$15,$38,$13
	db niblack,$2c,$38,$1a
	db niblack,$00,$22,$11
	db niblack,$3d,$30,$15

yelpal
	db niblack,$00,$28,$28		;black	drkgray	yellow	yellow
	db niblack,$16,$28,$30		;black	red	yellow	white
 	db niblack,$00,$28,$38		;black	drkgray	yellow	light yellow
 	db niblack,$16,$30,$18		;black	red	white	dark yellow
; Sprites
	db niblack,$15,$38,$13
	db niblack,$2c,$38,$1a
	db niblack,$00,$22,$11
	db niblack,$3d,$30,$15

;---
; BIG_CAR - title car map data
;---
;---
;	carnopit.map
;---
big_car:
	db	$00,$00,$00,$00,$00,$00,$00,$00	;line 0
	db	$00,$00,$00,$00,$01,$02,$03,$04
	db	$05,$05,$05,$05,$06,$07,$08,$09
	db	$00,$00,$00,$00,$00,$00,$00,$00

	db	$00,$00,$00,$00,$00,$00,$00,$00	;line 1
	db	$00,$00,$00,$0A,$0B,$0C,$0D,$0E
	db	$0F,$10,$11,$12,$13,$14,$15,$16
	db	$17,$18,$00,$00,$00,$00,$00,$00

	db	$00,$00,$00,$00,$00,$00,$00,$19	;line 2
	db	$1A,$1B,$1C,$1D,$1E,$1F,$0E,$20
	db	$21,$22,$23,$24,$25,$26,$00,$27
	db	$28,$29,$2A,$2B,$2C,$2D,$2E,$2F

	db	$00,$00,$00,$30,$31,$32,$33,$34	;line 3
	db	$35,$36,$37,$38,$39,$3A,$3B,$3C
	db	$3D,$3E,$3F,$40,$41,$42,$43,$43
	db	$44,$41,$45,$46,$47,$48,$49,$4A

	db	$00,$4B,$4C,$4D,$4E,$4F,$50,$51	;line 4
	db	$52,$53,$54,$55,$56,$57,$58,$59
	db	$5A,$5B,$5C,$5D,$41,$41,$41,$41
	db	$41,$5E,$5F,$60,$61,$62,$63,$64

	db	$65,$66,$67,$68,$69,$62,$6A,$6B	;line 5
	db	$6C,$6D,$6E,$6F,$70,$71,$62,$72
	db	$73,$74,$75,$76,$41,$41,$41,$41
	db	$77,$78,$79,$7A,$7B,$7C,$7D,$7E

	db	$7F,$80,$81,$82,$62,$83,$84,$85	;line 6
	db	$86,$87,$88,$89,$8A,$8B,$8C,$8D
	db	$8E,$8F,$90,$91,$41,$92,$93,$94
	db	$95,$96,$97,$98,$99,$9A,$9B,$9C

	db	$9D,$9E,$9F,$A0,$A1,$A2,$A3,$A4	;line 7
	db	$A5,$A6,$A7,$A8,$A9,$AA,$AB,$AC
	db	$AD,$AE,$AF,$B0,$41,$B1,$B2,$B3
	db	$B4,$B5,$B6,$B7,$B8,$B9,$BA,$BB

	db	$BC,$BD,$BE,$BF,$BF,$C0,$C1,$C2	;line 8
	db	$C3,$C4,$C5,$C6,$C7,$C8,$C9,$CA
	db	$CB,$CB,$CB,$CB,$CC,$CD,$CD,$CE
	db	$CF,$D0,$D1,$D2,$00,$00,$00,$00


mind	db	0,0,0,0,0,0,0,0		;8 blanks
	db	'M'-$20,0
	db	'I'-$20,0
	db	'N'-$20,0
	db	'D'-$20,0
	db	'S'-$20,0
	db	'C'-$20,0
	db	'A'-$20,0
	db	'P'-$20,0
	db	'E'-$20
	db	0,0,0,0,0,0,0		;7 blanks
blnks	db	0,0,0,0,0,0,0,0		;8 blanks
	db	0,0,0,0,0,0,0,0		;8 blanks
	db	0,0,0,0			;4 blanks
psents	db	0,0,0,0			;4 blanks
	db	0,0,0,0,0,0,0,0		;8 blanks
	db	'P'-$20
	db	'R'-$20
	db	'E'-$20
	db	'S'-$20
	db	'E'-$20
	db	'N'-$20
	db	'T'-$20
	db	'S'-$20
	db	0,0,0,0			;4 blanks
	db	0,0,0,0,0,0,0,0		;8 blanks

;---
; logomap - map of 'Day of Thunder' logo graphic
;---
;---
;	newtitle.map
;---
logomap:
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$01,$02,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00	;1

	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$03,$04,$05,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$06,$07
	db	$08,$09,$00,$00,$00,$00,$00,$00	;2

	db	$00,$0A,$0B,$0C,$0D,$0E,$0F,$10
	db	$11,$12,$13,$14,$15,$16,$17,$18
	db	$19,$1A,$1B,$1C,$1D,$1E,$1F,$20
	db	$21,$22,$00,$00,$00,$00,$00,$00	;3

	db	$00,$23,$24,$25,$26,$27,$28,$29
	db	$2A,$2B,$2C,$2D,$2E,$2F,$30,$31
	db	$32,$33,$34,$35,$36,$37,$38,$39
	db	$3A,$3B,$3C,$3D,$00,$00,$00,$00	;4

	db	$00,$00,$3E,$3F,$40,$41,$42,$43
	db	$44,$45,$46,$47,$48,$49,$4A,$4B
	db	$4C,$4D,$4E,$4F,$50,$51,$52,$53
	db	$54,$55,$56,$57,$58,$00,$00,$00	;5

	db	$00,$00,$59,$5A,$5B,$5C,$5D,$5E
	db	$5F,$60,$61,$62,$63,$64,$65,$66
	db	$67,$68,$69,$6A,$6B,$6C,$6D,$6E
	db	$6F,$70,$71,$72,$73,$00,$00,$00	;6

	db	$00,$74,$75,$76,$77,$78,$79,$7A
	db	$7B,$7C,$7D,$7E,$7F,$80,$81,$82
	db	$83,$84,$85,$86,$87,$88,$89,$8A
	db	$8B,$8C,$8D,$8E,$8F,$90,$91,$00	;7

	db	$00,$92,$93,$94,$95,$96,$97,$98
	db	$99,$9A,$00,$9B,$9C,$9D,$9E,$9F
	db	$A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7
	db	$A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF	;8

	db	$00,$B0,$B1,$B2,$B3,$B4,$B5,$B6
	db	$B6,$B7,$B8,$B9,$BA,$BB,$BC,$BC
	db	$BD,$BE,$BE,$BE,$BF,$C0,$C1,$C2
	db	$C3,$C4,$C5,$C6,$C7,$C8,$C9,$00	;9

	db	$00,$CA,$CB,$CC,$CD,$CE,$CF,$D0
	db	$D1,$D2,$D3,$D4,$C7,$D5,$D6,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00	;10

	db	$00,$D7,$D8,$D9,$DA,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00	;11


;---
; WRITE_BIGCAR - and pit
;---
write_bigcar:
	public	write_bigcar

	lda	#nibgblk+niobjblk+niobjlblk+nibglblk	;left edge off
	sta	nicr1SH			;

	jsr	write_pit		;into screen 0

	lda	#<niscreen1		;position cursor to upper-left
	sta	VRAMbase		;
	lda	#>niscreen1		;
	sta	VRAMbase+1		;
	ldx	#0			;
	ldy	#0			;
	jsr	setVRAMaddr		;

	lda	#<pitcar_map		;move pit car to screen 1
	sta	tvtmp			;
	lda	#>pitcar_map		;
	sta	tvtmp+1			;
	ldx	#32			;
	jsr	write_x_lines		;

	rts


;---
; WRITE_PIT - write pit map and color memory to screen 0
;---
write_pit:
	lda	#<niscreen0		;position cursor to upper-left
	sta	VRAMbase		;
	lda	#>niscreen0		;
	sta	VRAMbase+1		;
	ldx	#0			;
	ldy	#0			;
	jsr	setVRAMaddr		;

	lda	#<pit_map		;move pit to screen 0
	sta	tvtmp			;
	lda	#>pit_map		;
	sta	tvtmp+1			;
	ldx	#32			;
	jsr	write_x_lines		;

	rts

;---
;	pitempty.map
;---
pit_map:
	db	$00,$00,$00,$00,$00,$00,$00,$01
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$01,$00,$00,$00,$00,$00
	db	$00,$00,$00,$02,$03,$04,$05,$06
	db	$07,$08,$03,$07,$08,$00,$00,$00
	db	$02,$03,$08,$00,$00,$00,$00,$03
	db	$07,$04,$09,$00,$03,$08,$01,$00
	db	$00,$00,$00,$0A,$0B,$0B,$0B,$0B
	db	$0B,$0B,$0B,$0B,$09,$00,$00,$00
	db	$0A,$0B,$0B,$0C,$00,$00,$0A,$0B
	db	$0B,$0B,$06,$04,$0B,$0B,$09,$00
	db	$03,$07,$07,$0D,$0B,$0B,$0B,$0B
	db	$0B,$0B,$0B,$0B,$06,$08,$03,$08
	db	$03,$0B,$0B,$0E,$08,$03,$0D,$0B
	db	$0B,$0B,$0B,$0B,$0B,$0B,$06,$08
	db	$0B,$0B,$0B,$0B,$0B,$0B,$0F,$10
	db	$11,$12,$0F,$13,$11,$12,$0F,$13
	db	$11,$12,$0F,$13,$11,$12,$0F,$13
	db	$11,$12,$0B,$0B,$0B,$0B,$0B,$0B
	db	$0B,$0B,$0B,$0B,$0B,$0B,$14,$15
	db	$14,$15,$14,$15,$14,$15,$14,$15
	db	$14,$15,$14,$15,$14,$15,$14,$15
	db	$14,$16,$0B,$0B,$0B,$0B,$0B,$0B
	db	$0B,$0B,$17,$18,$17,$18,$19,$19
	db	$19,$19,$19,$19,$19,$19,$19,$19
	db	$19,$19,$19,$19,$19,$19,$19,$19
	db	$19,$19,$17,$18,$0B,$0B,$17,$18
	db	$1A,$1B,$1A,$1B,$1A,$1B,$1C,$1D
	db	$1E,$1E,$1E,$1F,$1D,$1E,$1E,$1E
	db	$1E,$1E,$1E,$1F,$1D,$1E,$1E,$1E
	db	$1F,$21,$1A,$1B,$22,$23,$1A,$1B
	db	$58,$59,$58,$59,$58,$59,$00,$26
	db	$1B,$1B,$1B,$28,$26,$1B,$1B,$1B
	db	$27,$1B,$1B,$28,$26,$1B,$1B,$1B
	db	$28,$00,$58,$59,$58,$59,$58,$59
	db	$29,$2A,$29,$2A,$29,$2A,$00,$2B
	db	$2C,$2D,$2E,$2F,$30,$31,$32,$33
	db	$34,$35,$36,$37,$5B,$5C,$5D,$5E
	db	$5F,$00,$29,$2A,$29,$2A,$29,$2A
	db	$60,$60,$60,$60,$60,$60,$3C,$3D
	db	$3E,$3F,$40,$41,$42,$43,$3D,$3C
	db	$44,$45,$46,$47,$61,$62,$63,$64
	db	$3C,$3C,$60,$60,$60,$60,$60,$60
	db	$4C,$1B,$4C,$1B,$4C,$1B,$4C,$1B
	db	$4C,$1B,$4C,$1B,$4C,$1B,$4C,$1B
	db	$4C,$1B,$4C,$1B,$4C,$1B,$4C,$1B
	db	$4C,$1B,$4C,$1B,$4C,$1B,$4C,$1B
	db	$1B,$4C,$1B,$4C,$1B,$4C,$1B,$4C
	db	$1B,$4C,$1B,$4C,$1B,$4C,$1B,$4C
	db	$1B,$4C,$1B,$4C,$1B,$4C,$1B,$4C
	db	$1B,$4C,$1B,$4C,$1B,$4C,$1B,$4C
	db	$4C,$1B,$4C,$1B,$4C,$1B,$4C,$1B
	db	$4C,$1B,$4C,$1B,$4C,$1B,$4C,$1B
	db	$4C,$1B,$4C,$1B,$4C,$1B,$4C,$1B
	db	$4C,$1B,$4C,$1B,$4C,$1B,$4C,$1B
	db	$4D,$4D,$4D,$4D,$4D,$4D,$4D,$4D
	db	$4D,$4D,$4D,$4D,$4D,$4D,$4D,$4D
	db	$4D,$4D,$4D,$4D,$4D,$4D,$4D,$4D
	db	$4D,$4D,$4D,$4D,$4D,$4D,$4D,$4D
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$D3,$D3,$D3,$D3,$D3,$D3,$D3,$D3
	db	$D3,$D3,$D3,$D3,$D3,$D3,$D3,$D3
	db	$D3,$D3,$D3,$D3,$D3,$D3,$D3,$D3
	db	$D3,$D3,$D3,$D3,$D3,$D3,$D3,$D3
	db	$D7,$D7,$D7,$D7,$D7,$D7,$D7,$D7
	db	$D7,$D7,$D7,$D7,$D7,$D7,$D7,$D7
	db	$D7,$D7,$D7,$D7,$D7,$D7,$D7,$D7
	db	$D7,$D7,$D7,$D7,$D7,$D7,$D7,$D7
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
;---
;	pitempty.col
;---
	db	$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	db	$00,$40,$50,$50,$50,$50,$D0,$C0
	db	$5A,$56,$55,$55,$55,$55,$59,$5A
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00

;---
;	carsprit.map
;---
pitcar_map:
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$01,$02,$03,$04
	db	$05,$05,$05,$05,$06,$07,$08,$09
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$0A,$0B,$0C,$0D,$0E
	db	$0F,$10,$11,$12,$13,$14,$15,$16
	db	$17,$18,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$19
	db	$1A,$1B,$1C,$1D,$1E,$1F,$0E,$20
	db	$21,$22,$23,$24,$25,$26,$00,$27
	db	$28,$29,$2A,$2B,$2C,$2D,$2E,$2F
	db	$00,$00,$00,$30,$31,$32,$33,$34
	db	$35,$36,$37,$38,$39,$3A,$3B,$3C
	db	$3D,$3E,$3F,$40,$41,$42,$43,$43
	db	$44,$41,$45,$46,$47,$48,$49,$4A
	db	$D3,$D4,$D5,$4D,$4E,$4F,$50,$51
	db	$52,$53,$54,$55,$56,$57,$58,$59
	db	$5A,$5B,$5C,$5D,$41,$41,$41,$41
	db	$41,$5E,$5F,$60,$61,$62,$63,$D6
	db	$D7,$D8,$67,$68,$69,$62,$6A,$6B
	db	$6C,$6D,$6E,$6F,$70,$71,$62,$72
	db	$73,$74,$75,$76,$41,$41,$41,$41
	db	$77,$78,$79,$7A,$7B,$7C,$7D,$D9
	db	$DA,$80,$81,$82,$62,$83,$84,$85
	db	$86,$87,$88,$89,$8A,$8B,$8C,$8D
	db	$8E,$8F,$90,$91,$41,$92,$93,$94
	db	$95,$96,$97,$98,$99,$9A,$9B,$DB
	db	$DC,$9E,$9F,$A0,$A1,$A2,$A3,$A4
	db	$A5,$A6,$A7,$A8,$A9,$AA,$AB,$AC
	db	$AD,$AE,$AF,$B0,$41,$B1,$B2,$B3
	db	$B4,$B5,$B6,$B7,$DD,$DE,$DF,$E0
	db	$E1,$BD,$BE,$BF,$BF,$C0,$C1,$C2
	db	$C3,$C4,$C5,$C6,$C7,$C8,$C9,$CA
	db	$CB,$CB,$CB,$CB,$CC,$CD,$CD,$CE
	db	$CF,$D0,$D1,$D2,$E2,$E3,$E4,$E4
	db	$E5,$E6,$E6,$E6,$E6,$E6,$E6,$E6
	db	$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6
	db	$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6
	db	$E6,$E6,$E6,$E6,$E7,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
	db	$E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
;---
;	car.col
;---
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$80,$A0,$A0,$00,$00,$00,$00,$20
	db	$AA,$1A,$04,$51,$00,$F0,$00,$08
	db	$0A,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00

;----
; data local and external
;---

;---
; local data for TITLE.ASM
;---
	extern	xpos		;ds 1		;cursor postion/scroll position
	extern	ypos		;ds 1		;cursor position
	extern	xspeedl		;ds 1		;screech in
	extern	xspeedh		;ds 1		;screech in
	extern	startdown	;ds 1		;start button was pressed
	extern	ycount		;ds 1		;used by holdlogo routine

;---
; external data
;---
	extern	mytask
	extern	nicr0SH
	extern	niscrolll
	extern	niscrollm
	extern	PICvramflag
	extern	sv_niscrollh
	extern	sv_niscrollm
	extern	tsknums
	extern	tvtmp
	extern	VRAMbase

;---
; zero page data for TITLE.ASM
;---
	extern	PAGE0 sndspd		;ds	1	;frequency
	extern	PAGE0 sndvol		;ds	1	;amplitude

	END
