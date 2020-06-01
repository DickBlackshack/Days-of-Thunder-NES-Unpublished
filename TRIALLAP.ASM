;---
; person.asm - first person routines
;---

	LINKLIST

	include nindef.asm
	include ninref.asm

BANK2	SECTION

;---
; external subroutines
;---
	extern	buffer_slice
	extern	do_sprite_DMA		;in ROUTINES.ASM
	extern	hide_sprites		;in ROUTINES.ASM
	extern	line0
	extern	line1
	extern	make_track
	extern	nextframej		;bank switched entry point
	extern	palgame
	extern	setVRAMaddr		;in ROUTINES.ASM
	extern	sliceout
	extern	snd_disable		;in ROUTINES.ASM
	extern	snd_enable		;in ROUTINES.ASM
	extern	wait_for_start		;in ROUTINES.ASM
	extern	waitvb			;in ROUTINES.ASM
	extern	waitxlines		;in ROUTINES.ASM
	extern	write_x_lines		;in ROUTINES.ASM

decel		equ	10		;players deceleration rate
friction	equ	2		;off gas slowdown
maxspeed	equ	6		;from PB.ASM, keep in sync
turnslow	equ	5		;steering
turnmed		equ	10		;steering
turnfast	equ	15		;steering
tracklength	equ	52		;TEST ONLY - must be variables
trackwrap	equ	255-tracklength	;TEST ONLY - must be variables

;---
; entry point for vanity
;---
vanity	jmp	vanity2
	public	vanity
;---
; FIRSTPERSON - show first person track
;---
firstperson
	public	firstperson
	jsr	TSKvblank		;turn off track output routine
	dw	0
	
	lda	#0			;turn off string out routine
	sta	PICvramflag		;
	sta	dashboard		;shut off dashboard

	jsr	nividoff		;turn video off
	
	jsr	hide_sprites		;push sprites offscreen

	jsr	set1pal			;set 1st person palette

	jsr	roadhskp		;1st person perspective housekeeping

	lda	#0			;show screen 0 with no vertical scroll
	sta	niscrollv		;
	sta	niscrollv+1		;
	sta	sv_niscrollh		;
	lda	#0			;most significant bit of x scroll
	sta	sv_niscrollm		;

	lda	#16			;new background character set=16
	sta	nibnkchrSH		;
	lda	#6			;set sprite bank to stripe bank
	sta	nibnksprSH		;

	jsr	nividon			;video on

	lda	#(14*8)-1		;sprite 0's Y at window bottom KNOB
	sta	rasterspritey		;
	jsr	waitnmi			;

	lda	nistatus		;reset the latch

wait_spcol
	ldx	#0			;prep for scroll at dashboard
	ldy	#nibgseg+niinton	;

	lda	nistatus
	bmi	wait_spcol3		;in the wrong spot: get down
	and	#nistrike
	beq	wait_spcol		;wait for end of dashboard

	stx	niscroll		;reset for screen split
	stx	niscroll		;reset for screen split
	sty	nicr0			;set control register with no MSB horz

	ldx	#1			;wait 1 scanline
	jsr	waitxlines		;

	lda	#31			;TEST ONLY chg to dashboard bkgd set
	ldx	#7			;no sprites in top part of character set
	jsr	nibnkchr		;

	ldx	#47			;wait for displaying dashboard
	jsr	waitxlines		;

	ldx	#$0A			;delay loop to move the scanline to edge
?1	dex
	bne	?1

	lda	#0			;blank immediately!
	sta	nicr1			;

	lda	#>nipal+16		;change background color to black
	sta	nivramaddr		;
	lda	#<nipal+16		;
	sta	nivramaddr		;
	lda	#niblack		;
	sta	nivramdata

	jsr	nextframej

	lda	#>niscreen0		;display black backgound
	sta	nivramaddr		;
	lda	#<niscreen0		;
	sta	nivramaddr		;

	ldx	#$0F			;delay loop to move the scanline to edge
?2	dex
	bne	?2

	lda	#nibgblk+niobjblk+niobjlblk+nibglblk	;video on
	sta	nicr1			;
	sta	nicr1SH			;

wait_spcol2
	jsr	waitnmi			;wait for an interrupt

wait_spcol3
	lda	nistatus
	bmi	wait_spcol3
	and	#nistrike
	bne	wait_spcol3		;wait for end of vblank

	jsr	frame_control
	jsr	enginesnd		;make the engine sound
	jsr	qtimer			;time qualifying lap
	jsr	movestripes		;

?10:	lda	TSKlap			;qualify done?
	cmp	#04			;
	bne	wait_spcol		;no: continue qualifying
	lda	flindex			;past finish line?
	cmp	#21			;
	bcc	wait_spcol		;no: continue qualifying

	jsr	nividoff		;turn off the video
	lda	#0			;turn off nmi routine
	sta	ninmi			;

	lda	laptimeh		;greater than 99?
	cmp	#100			;
	bcc	?20			;no: continue
	lda	#99			;yes: reset to 99
	sta	laptimeh		;

?20	jsr	TSKvblank		;reset sliceout
	dw	sliceout

	jsr	nividon
	dec	ninmi			;nmi routine back on

	rts

;---
; MOVESTRIPES - move the stripes on the road based on speed and frame
;---
movestripes:
	lda	intflag			;get cycle number
	and	#7			;make 1-8
	tax				;
	inx				;
	stx	TSKflags		;

	ldy	#4			;sprite block number
	ldx	#1			;sprite number

msloop	lda	TSKyh,x			;this sprite below top of dash?
	cmp	#(14*8)-4		;
	bcc	?onscrn			;no: continue

	jsr	testfinish		;see if finish housekeeping needed

	sty	tmp			;yes: start it back at the vanishing pt
	ldy	flindex			;get current frame number
	lda	vpx,y			;get frame's V.P. X
	sta	TSKxh,x			;
	lda	vpy,y			;get frame's V.P. Y
	sta	TSKyh,x			;
	lda	#0			;reset low part too
	sta	TSKxl,x			;
	sta	TSKyl,x			;

	lda	xdeltal,y		;get xdelta for each y movement
	sta	TSKxspeedl,x		;
	lda	xdeltah,y		;
	sta	TSKxspeedh,x		;

	lda	#0			;reset speed toward dashboard
	sta	TSKyspeedl,x		;
	sta	TSKyspeedh,x		;

	lda	#8			;this now moved once every 8 times
	sta	TSKflags,x		;

	ldy	#8			;speed up all of the sprite strips
?5	lda	TSKflags,y		;
	beq	?6			;(don't go minus)
	sec				;
	sbc	#1			;
	sta	TSKflags,y		;
?6	dey				;
	bne	?5			;

	ldy	tmp			;get back sprite block offset

?onscrn	lda	#0			;assume +slope change (moving left)
	sta	tmp+2			;
	sta	tmp+3			;
	lda	TSKyh			;are we moving left?
	bmi	?mvlft			;yes: leave tmp+3 as is
	beq	?at0			;special case
	dec	tmp+3			;no: moving right, slope becomes less
?mvlft	lda	TSKyh			;current y position
	eor	#$FF			;change its sign
	clc				;
	adc	#1			;
	sta	tmp+2			;tmp+2 is the low part, tmp+3 high part
	rol	tmp+2			;change slope by abs(3 & 252) max
	rol	tmp+3			;
	clc				;
	rol	tmp+2			;
	rol	tmp+3			;
	
?at0	lda	TSKflags,x		;time to move this sprite strip?
	cmp	TSKflags		;
	bcs	?11			;

	lda	onebytexspeed		;calc new sprite speed
	clc				;
	adc	TSKyspeedl,x		;
	sta	TSKyspeedl,x		;
	lda	TSKyspeedh,x		;
	adc	#0			;
	sta	TSKyspeedh,x		;
	
	clc				;calc new Y position for sprite
	lda	TSKyspeedl,x		;
	adc	TSKyl,x			;
	sta	TSKyl,x			;
	lda	TSKyh,x			;
	sta	tmp			;(calc lines moved down this time)
	adc	TSKyspeedh,x		;
	sta	TSKyh,x			;

	sec				;calc lines moved down this time
	sbc	tmp			;
	beq	?11			;no whole lines moved down

	sty	tmp			;calc new X position for sprite
	tay				;
?xadd	clc				;
	lda	TSKxspeedl,x		;
	adc	TSKxl,x			;
	sta	TSKxl,x			;
	lda	TSKxh,x			;
	adc	TSKxspeedh,x		;
	sta	TSKxh,x			;

	clc				;x position changes slope, too.
	lda	TSKxl,x			;
	adc	tmp+2			;
	sta	TSKxl,x			;
	lda	TSKxh,x			;
	adc	tmp+3			;
	sta	TSKxh,x			;

	dey				;
	bne	?xadd			;
	ldy	tmp			;


	
?11	lda	TSKxh,x			;this sprite's current x position
	bit	TSKyh			;car turning left?
	bpl	?20			;yes: go check for overflow
	sec				;no: no overflow check needed
	sbc	TSKyh
	jmp	?30

?20	sec				;keep stripe on the road
	sbc	TSKyh			;
	bcs	?30			;prevent wrap-around
	lda	#$FF			;
?30	sta	sprbuf+niobjx,y		;

	clc
	lda	TSKxspeedl+1		;figure slope of stripes (frame slope)
	clc				;(add turn induced sloped)
	adc	tmp+2			;
	sta	tmp+2			;
	lda	TSKxspeedh+1		;
	adc	tmp+3			;
	sta	tmp+3			;
	rol	tmp+2			;scale
	rol	tmp+3			;
	lda	tmp+3			;negative?
	bpl	?40			;
	lda	tmp+3			;yes: negate
	eor	#$FF			;
	clc				;
	adc	#1			;
?40	cmp	#12			;out of range in char set?
	bcc	?50			;no: continue
	lda	#11			;
?50	asl	a			;multiply by 8
	asl	a			;
	asl	a			;
	sta	tmp			;

	lda	TSKyh,x			;this frames vanishing point Y
	sta	sprbuf+niobjy,y		;

	sec				;generate character number based on Y
	sbc	#miny			;
	stx	tmp+1			;
	tax				;
	lda	ychar,x			;
	clc				;
	adc	tmp			;
	sta	sprbuf+niobjc,y		;
	ldx	tmp+1			;

	lda	#0			;color
	lda	#$3F			;-niobjprior (sprites under background)
	sta	sprbuf+niobja,y		;
	
	inx				;next sprite
	iny				;next sprite control block
	iny				;
	iny				;
	iny				;
	cpx	#9
	beq	msexit
	jmp	msloop

msexit	jsr	finishline		;do finish line work if needed
	rts

;---
; FINISHLINE - see if finish line is needed
;---
finishline
	ldx	fline			;copy from this road strip sprite
	beq	flexit			;not needed yet
	bmi	flexit			;done: not needed

	lda	sprbuf+niobjy,x
	sta	sprbuf+200+niobjy
	sta	sprbuf+204+niobjy
	sta	sprbuf+208+niobjy
	sta	sprbuf+212+niobjy
	sta	sprbuf+216+niobjy

	lda	sprbuf+niobjc,x		;calc x spread
	and	#7			;based on the current stripe character
	asl	a			;
	asl	a			;
	sta	fline+2			;

	lda	sprbuf+niobjx,x
	pha
	sta	sprbuf+200+niobjx
	clc
	adc	fline+2
	sta	sprbuf+204+niobjx
	clc
	adc	fline+2
	sta	sprbuf+208+niobjx
	pla
	sec
	sbc	fline+2
	sta	sprbuf+212+niobjx
	sec
	sbc	fline+2
	sta	sprbuf+216+niobjx

	lda	#$3F 			;sprites below background
	sta	sprbuf+200+niobja	;
	sta	sprbuf+204+niobja	;
	sta	sprbuf+208+niobja	;
	sta	sprbuf+212+niobja	;
	sta	sprbuf+216+niobja	;

	lda	sprbuf+niobjc,x
	and	#7
	ora	#$A0
	sta	sprbuf+200+niobjc
	sta	sprbuf+204+niobjc
	sta	sprbuf+208+niobjc
	sta	sprbuf+212+niobjc
	sta	sprbuf+216+niobjc

flexit	rts

;---
; TESTFINISH - see if finish line housekeeping is needed
;---
testfinish
	lda	fline			;start finish line?
	bne	?10			;no: if in progress or done
	txa				;yes: save road strip to copy from
	asl	a			;change to sprite location
	asl	a			;
	sta	fline			;
	stx	fline+1
	jmp	tfexit			;

?10	bmi	tfhide			;hidden: leave as is

	cpx	fline+1			;was this strip used for finishline x/y?
	bne	tfexit			;no: leave
	lda	#$FF			;mark as hidden
	sta	fline
	
tfexit	rts

tfhide	lda	#$F0			;hide the finishline sprites
	sta	sprbuf+200+niobjy	;
	sta	sprbuf+204+niobjy	;
	sta	sprbuf+208+niobjy	;
	sta	sprbuf+212+niobjy	;
	sta	sprbuf+216+niobjy	;
	rts

;---
; frame_control - drive the car
;---
frame_control:
	ldy	#0			;stick 0
	jsr	nijoyget		;update nijoy with current stick 0
	jsr	accel			;move car forward
	jsr	steer			;get side to side speed
	jsr	simturn			;simulate the turn forces

?10	lda	nijoy			;select pressed?
	and	#niselect		;
	beq	?20			;not pressed

	dec	flindex			;next entry down
	lda	flindex			;before start?
	cmp	#$FF			;TEST ONLY: must be variable
	bne	?20			;no: frame ok as is
	inc	flindex			;yes: reset to min

?20	ldy	flindex			;get frame number
	lda	(frmptr),y		;
	sta	frame			;
	lda	frame_len,y

	clc				;add yspeed to y position
	lda	TSKyl
	adc	TSKyspeedl
	sta	TSKyl
	lda	TSKyh
	adc	TSKyspeedh
	sta	TSKyh

?25	lda	#0			;assume on right side
	sta	sv_niscrollm
	lda	TSKyh
	bpl	?30

	ldx	#1
	stx	sv_niscrollm
	cmp	#136
	bcs	?setscroll
	lda	#136+8
	sta	TSKyh
	jsr	crash
	jmp	?25

?30	cmp	#121
	bcc	?setscroll
	lda	#120-8
	sta	TSKyh
	jsr	crash
	jmp	?25

?setscroll
	lda	TSKyh
	sta	sv_niscrollh
	
fcexit:	rts

;---
; ROADHSKP - prepare 1st person perspective screen
;---
roadhskp:
	lda	#0			;no skidding or move at first
	sta	TSKaccel
	sta	TSKskidding		;
	sta	TSKxspeedl		;forward speed
	lda	#1			;obe
	sta	TSKxspeedh		;forward speed
	lda	#0
	sta	TSKyspeedl		;turn speed
	sta	TSKyspeedh		;turn speed
	sta	TSKyl			;turn position
	sta	TSKyh			;turn position
	sta	Lbuf			;turn position
	sta	turn			;centripetal force
	sta	turn+1			;centripetal force
	sta	TSKxl
	sta	TSKlap			;and lap counter
	sta	TSKxm			;must be zero
	sta	tires			;brand new tires
	sta	body			;brand new car
	sta	laptimel		;qualifying lap time
	sta	laptimeh		;qualifying lap time
	sta	fline+3			;for clock tick routine

	lda	#$FF
	sta	fline			;finish line flag

	ldy	#0			;set road strip values
	ldx	#1			;
?05:	lda	STRxh,y			;
	sta	TSKxh,x			;
	lda	STRyh,y			;
	sta	TSKyh,x			;
	lda	#0			;
	sta	TSKxl,x			;
	sta	TSKyl,x			;
	sta	TSKyspeedl,x		;
	sta	TSKyspeedh,x		;
	lda	#2			;
	sta	TSKxspeedh,x		;
	lda	#25			;
	sta	TSKxspeedl,x		;
	tya				;
	sta	TSKflags,x		;
	inx				;
	iny				;
	cpy	#8			;
	bne	?05			;

	lda	#<niscreen1		;clear screen 1
	sta	VRAMbase		;
	lda	#>niscreen1		;
	sta	VRAMbase+1		;
	ldx	#0			;
	ldy	#0			;
	jsr	setVRAMaddr		;
	jsr	niscrclr_any		;

	ldx	#0			;write inside roof data for screen 1
	ldy	#0			;
	jsr	setVRAMaddr		;
	lda	#1			;
	ldx	#6*32			;
?10	sta	nivramdata		;
	dex				;
	bne	?10			;

	ldx	#0			;cooindence line for screen 1
	ldy	#14			;
	jsr	setVRAMaddr		;
	lda	#1			;
	ldx	#1*32			;
?15	sta	nivramdata		;
	dex				;
	bne	?15			;

	ldx	#0			;set color memory for screen 1
	ldy	#30			;
	jsr	setVRAMaddr		;
	lda	#<road_col		;set palette to xreg palette
	sta	tvtmp			;
	lda	#>road_col		;
	sta	tvtmp+1			;
	ldx	#2			;number of lines to move
	jsr	write_x_lines		;

	lda	#<niscreen0		;clear screen 0
	sta	VRAMbase		;
	lda	#>niscreen0		;
	sta	VRAMbase+1		;
	ldx	#0			;
	ldy	#0			;
	jsr	setVRAMaddr		;set working screen address
	jsr	niscrclr_any		;

	ldx	#0			;write inside roof data for screen 0
	ldy	#0			;
	jsr	setVRAMaddr		;
	lda	#1			;
	ldx	#6*32			;
?20	sta	nivramdata		;
	dex				;
	bne	?20			;

	ldx	#0			;set color memory for screen 0
	ldy	#30			;
	jsr	setVRAMaddr		;
	lda	#<road_col		;set palette to xreg palette
	sta	tvtmp			;
	lda	#>road_col		;
	sta	tvtmp+1			;
	ldx	#2			;number of lines to move
	jsr	write_x_lines		;

	ldx	#0			;write dashboard map
	ldy	#14			;
	jsr	setVRAMaddr		;
	lda	#<dash_map		;
	sta	tvtmp			;
	lda	#>dash_map		;
	sta	tvtmp+1			;
	ldx	#9			;
	jsr	write_x_lines		;

	lda	#<frame_list		;point to list of frame numbers
	sta	frmptr			;
	lda	#>frame_list		;
	sta	frmptr+1		;

	lda	#0			;frame list index
	sta	flindex			;

	lda	#0			;TEST ONLY
	sta	frame

	jsr	nextframej		;paint it
	
	jsr	TSKvblank		;reset background color NMI routine
	dw	NMIbgcolor

	lda	#$14			;set volume of channel 0 (any stuff)
	sta	nidutyA
	lda	#%00000000
	sta	nisweepA

	lda	#84			;T
	sta	sprbuf+(64)+niobjx
	lda	#84+8
	sta	sprbuf+(68)+niobjx	;R
	lda	#84+8+8
	sta	sprbuf+(72)+niobjx	;I
	lda	#84+8+8+8
	sta	sprbuf+(76)+niobjx	;A
	lda	#84+8+8+8+8
	sta	sprbuf+(80)+niobjx	;L
	lda	#84+8+8+8+8+8+8
	sta	sprbuf+(84)+niobjx	;L
	lda	#84+8+8+8+8+8+8+8
	sta	sprbuf+(88)+niobjx	;A
	lda	#84+8+8+8+8+8+8+8+8
	sta	sprbuf+(92)+niobjx	;P

	lda	#23			;y value for lap display
	sta	sprbuf+(64)+niobjy	;T
	sta	sprbuf+(68)+niobjy	;R
	sta	sprbuf+(72)+niobjy	;I
	sta	sprbuf+(76)+niobjy	;A
	sta	sprbuf+(80)+niobjy	;L
	sta	sprbuf+(84)+niobjy	;L
	sta	sprbuf+(88)+niobjy	;A
	sta	sprbuf+(92)+niobjy	;P
	lda	#$3F-niobjprior 	;sprites above background
	sta	sprbuf+(64)+niobja	;T
	sta	sprbuf+(68)+niobja	;R
	sta	sprbuf+(72)+niobja	;I
	sta	sprbuf+(76)+niobja	;A
	sta	sprbuf+(80)+niobja	;L
	sta	sprbuf+(84)+niobja	;L
	sta	sprbuf+(88)+niobja	;A
	sta	sprbuf+(92)+niobja	;P

	lda	#'T'+64
	sta	sprbuf+(64)+niobjc
	lda	#'R'+64
	sta	sprbuf+(68)+niobjc
	lda	#'I'+64
	sta	sprbuf+(72)+niobjc
	lda	#'A'+64
	sta	sprbuf+(76)+niobjc
	lda	#'L'+64
	sta	sprbuf+(80)+niobjc
	lda	#'L'+64
	sta	sprbuf+(84)+niobjc
	lda	#'A'+64
	sta	sprbuf+(88)+niobjc
	lda	#'P'+64
	sta	sprbuf+(92)+niobjc
	rts

;---
; SETQUALIFY - change sprites to the word qualify
;---
setqualify:
	lda	#'Q'+64
	sta	sprbuf+(64)+niobjc
	lda	#'U'+64
	sta	sprbuf+(68)+niobjc
	lda	#'A'+64
	sta	sprbuf+(72)+niobjc
	lda	#'L'+64
	sta	sprbuf+(76)+niobjc
	lda	#'I'+64
	sta	sprbuf+(80)+niobjc
	lda	#'F'+64
	sta	sprbuf+(84)+niobjc
	lda	#'Y'+64
	sta	sprbuf+(88)+niobjc
	lda	#' '+64
	sta	sprbuf+(92)+niobjc

	lda	#92			;Q
	sta	sprbuf+(64)+niobjx
	lda	#92+8
	sta	sprbuf+(68)+niobjx	;U
	lda	#92+8+8
	sta	sprbuf+(72)+niobjx	;A
	lda	#92+8+8+8
	sta	sprbuf+(76)+niobjx	;L
	lda	#92+8+8+8+8
	sta	sprbuf+(80)+niobjx	;I
	lda	#92+8+8+8+8+8
	sta	sprbuf+(84)+niobjx	;F
	lda	#92+8+8+8+8+8+8
	sta	sprbuf+(88)+niobjx	;Y
	lda	#92+8+8+8+8+8+8+8
	sta	sprbuf+(92)+niobjx	;space

	lda	#$3F-niobjprior 	;sprites above background
	sta	sprbuf+(64)+niobja	;Q
	sta	sprbuf+(68)+niobja	;U
	sta	sprbuf+(72)+niobja	;A
	sta	sprbuf+(76)+niobja	;L
	sta	sprbuf+(80)+niobja	;I
	sta	sprbuf+(84)+niobja	;F
	sta	sprbuf+(88)+niobja	;Y
	sta	sprbuf+(92)+niobja	;space

	rts

;---
; WAITXNMIS - wait xreg nmi routines
;---
waitxnmis:
	jsr	waitnmi			;go wait for 1 vertical blank routine
	dex
	bne	waitxnmis
	rts

;---
; WAITNMI - wait for vertical blank routine to happen
;--- 
waitnmi:
	lda	intflag
?1	cmp	intflag
	beq	?1
	rts

;----
; SET1PAL - set 1st person palette
;---
set1pal:
	lda	#>nipal			;set VRAM address to palette area
	sta	nivramaddr		;
	lda	#<nipal			;
	sta	nivramaddr		;

	lda	#<pal1st		;set palette to xreg palette
	sta	tvtmp			;
	lda	#>pal1st		;
	sta	tvtmp+1			;
	ldx	#1			;number of lines to move
	jsr	write_x_lines		;
	rts

;----
; SETVANITYPAL - set vanity screen palette
;---
setvanitypal:
	lda	#>nipal			;set VRAM address to palette area
	sta	nivramaddr		;
	lda	#<nipal			;
	sta	nivramaddr		;

	lda	#<palvanity		;set palette to xreg palette
	sta	tvtmp			;
	lda	#>palvanity		;
	sta	tvtmp+1			;
	ldx	#1			;number of lines to move
	jsr	write_x_lines		;
	rts

;---
; ACCEL - move car forward
;---
accel:
	lda	TSKxspeedh		;minimum speed?
	beq	?noslower		;yes: no slower

	ldy	#friction		;always friction
	lda	#nibutB
	bit	nijoy
	beq	?nobrake
	ldy	#decel+friction
?nobrake
	sty	maptmp2
	sec
	lda	TSKxspeedl
	sbc	maptmp2
	sta	TSKxspeedl
	lda	TSKxspeedh
	sbc	#0
	sta	TSKxspeedh
	bpl	?noslower
	lda	#0			;limit to speed of zero
	sta	TSKxspeedl
	sta	TSKxspeedh

?noslower
	lda	 #nibutA
	bit	 nijoy
	beq	 ?nobutA

	lda	 TSKskidding
	bne	 ?nobutA		;no accel while skidding

	lda	 TSKxspeedh
	cmp	 #maxspeed
	beq	 ?nobutA
	lda	 intflag
	and	 #1			;frequency of speed inc
	bne	 ?nobutA

	lda	 car
	asl	 a
	tay
	lda	 geartab,y
	sta	 maptmp2
	lda	 geartab+1,y
	sta	 maptmp2+1

	lda	 TSKxspeedl
	sta	 Lbuf+2
	lda	 TSKxspeedh
	ror	 a
	ror	 Lbuf+2
	ror	 a
	ror	 Lbuf+2
	ror	 a
	ror	 Lbuf+2
	ldy	 Lbuf+2

	lda	 #0
	sta	 Lbuf+3
	lda	 (maptmp2),y
	bpl	 ?notminus
	dec	 Lbuf+3

?notminus
	clc
	lda	 TSKxspeedl
	adc	 (maptmp2),y
	sta	 TSKxspeedl
	lda	 TSKxspeedh
	adc	 Lbuf+3
	sta	 TSKxspeedh

?nobutA
	jsr	speed2frame
	rts

;---
; SPEED2FRAME
;---
speed2frame
	sec
	lda	TSKxl
	sbc	TSKxspeedl
	sta	TSKxl
	lda	TSKxh
	sbc	TSKxspeedh
	sta	TSKxh
	lda	TSKxm
	sbc	#0
	cmp	#$FF			;next frame?
	bne	s2fexit			;no: same frame
	inc	flindex			;yes: next frame in list

	lda	flindex			;time for finish line?
	cmp	#19			;(finish line frame)
	bne	?5			;no: continue
	lda	TSKlap			;finish line on even half laps
	and	#1			;
	bne	?5			;
	lda	#0			;on even half lap: set indicator
	sta	fline			;

?5	lda	flindex			;beyond end?
	cmp	#flend-frame_list	;TEST ONLY: must be variable
	bne	?10			;no: frame ok as is, go get it
	inc	TSKlap			;half lap is done
	lda	#0			;yes: reset frame list to the start
	sta	flindex			;

?10	lda	#0			;reset low value
	sta	TSKxl
	ldx	flindex			;reset high value
	lda	frame_len,x		;
	sta	TSKxh			;

	ldx	flindex			;adjust stripes with road's movement...
	ldy	#8			;...from this frame from the last frame
?15	lda	TSKyh,y			;
	clc				;
	adc	ymove,x			;
	sta	TSKyh,y			;
	lda	TSKxh,y			;
	clc				;
	adc	xmove,x			;
	sta	TSKxh,y			;

	lda	xdeltal,x		;xdelta for this frame
	sta	TSKxspeedl,y		;
	lda	xdeltah,x		;
	sta	TSKxspeedh,y		;

	dey				;
	bne	?15			;

s2fexit	rts

;---
; ENGINESND - make the engine sound
;---
enginesnd:
	lda	intflag
	and	#1
	bne	esexit
	lda	#0
	sta	maptmp2+1

	lda	onebytexspeed
	asl	a
	rol	maptmp2+1
	sta	maptmp2

	lda	#0
	sec
	sbc	maptmp2
	sta	nifreqlA
	lda	#4
	sbc	maptmp2+1
	sta	nifreqhA

esexit:	rts

;---
; STEER - control the right-left movement of the car
;---
steer:
	ldy	#0			;assume skidding & can't steer
	lda	TSKskidding		;allowed to steer?
	bne	?10			;no: we're skidding
	ldy	nijoy
?10	tya
	and	#$0f			;mask off buttons
	tay
	clc
	lda	TSKyspeedl
	adc	steeringl,y
	sta	TSKyspeedl
	sta	maptmp2
	lda	TSKyspeedh
	adc	steeringh,y
	sta	TSKyspeedh
	sta	maptmp2+1

;test for skid
	bpl ?notneg			;turning right: ok as is

;turning left negate turnspeed
	lda	 maptmp2
	eor	 #$FF
	clc
	adc	 #1
	sta	 maptmp2
	lda	 maptmp2+1
	eor	 #$FF
	adc	 #0
	sta	 maptmp2+1
?notneg
	ror	a
	ror	maptmp2
	ror	a
	ror	maptmp2
	ror	a
	ror	maptmp2			;7 bit yspeed

	lda	TSKxspeedl		;skid based on car's for speed, too.
	sta	maptmp2+1
	lda	TSKxspeedh
	ror	a
	ror	maptmp2+1
	ror	a
	ror	maptmp2+1
	ror	a
	ror	maptmp2+1
	lda	maptmp2+1
	sta	onebytexspeed		;for speedometer and motor sound

	lda	tires			;skid sensitivity knob
	clc
	adc	maptmp2
	adc	maptmp2+1
	bcs	?skid

	cmp	#$f0			;close to skidding threshold?
	bcc	?notclose
	lda	TSKskidding
	bne	?notclose		;already skidding

;close to skidding sound
	lda	#$12
	sta	nidutyD
	lda	intflag
	lsr	a
	and	#%00000011
	sta	nifreqD
	lda	#$20
	sta	nilengthD

?notclose
	lda	TSKskidding
	beq	?rts			;already not skidding
?decskid
	dec	TSKskidding		;reduce the skid count
	bne	?rts
	lda	#$0f			;skid done: shut off deltawave sound
	sta	niwrst
?rts	rts

?skid
	lda	TSKskidding
	bne	?decskid		;already skidding

	jsr	skidsound

	lda	#27*2			;skid duration
	sta	TSKskidding
	inc	tires			;tire wear
	inc	tires
;centrifugal force
	ldx	flindex
	lda 	cftable,x		;2-22
	asl	a
	asl	a
	asl	a
	sta	maptmp2
	clc
	lda	TSKyspeedl
	adc	maptmp2
	sta	TSKyspeedl
	lda	TSKyspeedh
	adc	#0
	sta	TSKyspeedh
	rts

;---
; ENDSKID - used at end of race
;---
endskid
	lda	#0
	sta	TSKskidding
	lda	#$0f			;turn off deltawave sound
	sta	niwrst
	rts

;---
; SKIDSOUND - make the deltawave skid sound
;---
skidsound
	lda	#$4a			;4=repeat a=sampling speed
	sta	niwre0
	lda	#$f2			;data at $fc80
	sta	nideltaddr
	lda	#$34			;length
	sta	nideltcntr
	lda	#00
	sta	nideltdata
	lda	#$0f			;trigger
	sta	niwrst
	lda	#$1f
	sta	niwrst
	rts

;---
; CRASH - bounce, crash, damage
;---
crash:
	lda	#$78
	jsr	niranrange
	ora	#$40			;range of 64-120
	sta	TSKskidding		;crash duration

;crash sound
	lda	#$08			;4=repeat a=sampling speed
	sta	niwre0
	lda	#$c0			;data at $f000
	sta	nideltaddr
	lda	#196
	sta	nideltcntr
	lda	#00
	sta	nideltdata
	lda	#$0f			;trigger
	sta	niwrst
	lda	#$1f
	sta	niwrst

	jsr	damagebody3		;guardrails do more damage

negplyspeed				;negate players yspeed & cut it in half
	lda	TSKyspeedl
	clc
	adc	turn
	sta	TSKyspeedl
	lda	TSKyspeedh
	adc	turn+1
	sta	TSKyspeedh		;get true yspeed

	asl	a			;preserve sign
	ror	TSKyspeedh		;cut in half
	ror	TSKyspeedl

	jsr	negyspeed		;bounce off guardrail

	lda	TSKyspeedl		;nullify centripetal force
	sec
	sbc	turn
	sta	TSKyspeedl
	lda	TSKyspeedh
	sbc	turn+1
	sta	TSKyspeedh		;make true yspeed

;LEH test
	clc				;add yspeed to y position
	lda	TSKyl
	adc	TSKyspeedl
	sta	TSKyl
	lda	TSKyh
	adc	TSKyspeedh
	sta	TSKyh

	clc				;cut xspeed in half
	lsr	TSKxspeedh		;
	ror	TSKxspeedl		;
	lda	TSKxspeedh		;minimum speed
	ora	#1			;
	sta	TSKxspeedh

	rts


;---
; Body damage routine
;---
damagebody1		;nudge
	lda body
	clc
	adc #1
	sta body
	rts

damagebody2		;severe hit  (+nudge)
	lda body
	clc
	adc #3
	sta body
	rts

damagebody3		;crash with guardrail
	lda body
	clc
	adc #7
	sta body
	rts

;---
; NEGYSPEED - bounce the car
;---
negyspeed
	lda TSKyspeedl
	eor #$ff
	sta TSKyspeedl
	lda TSKyspeedh
	eor #$ff
	sta TSKyspeedh

	inc TSKyspeedl
	bne ?rts
	inc TSKyspeedh
?rts	rts

;---
; SIMTURN - simulate turn
;---
simturn:
	lda	#0
	sta	turn+1
	sec
	ldx	flindex
	lda	cftable,x
	asl	a
	rol	turn+1
	asl	a
	rol	turn+1
	asl	a
	rol	turn+1
	asl	a
	rol	turn+1
	asl	a
	rol	turn+1
	sta	turn

	clc
	lda	TSKyl
	adc	turn
	sta	TSKyl
	lda	TSKyh
	adc	turn+1
	sta	TSKyh
	rts

;---
; QTIMER - do timing of trial/qualifying laps
;---
qtimer:
	lda	TSKlap			;half lap 0 logic
	bne	?10			;
	lda	flindex			;	before finish line
	cmp	#19			;	finish line done in frame 19
	bcc	qtexit			;	before finish line: exit
	bne	?10			;	beyond frame 19: run lap clock
	lda	fline			;	still displaying finish line?
	bmi	?10			;	no: run lap clock
	jmp	qtexit			;	yes: leave

?10	cmp	#2			;end of trial lap logic
	bne	?20			;
	lda	flindex			;	reset time if beyond finish line
	cmp	#19			;	on finish line frame?
	bne	?20			;	no: let time run
	lda	fline			;	yes: finish line on screen
	bmi	?20			;	no: let time run
	lda	#0			;	yes: reset timer
	sta	laptimel		;
	sta	laptimeh		;
	jsr	setqualify		;	put out word qualify
	jmp	qtexit

?20	cmp	#4			;end of qualifying lap logic
	bne	?30			;
	lda	flindex			;	stop timer if over finish line
	cmp	#19			;
	bcc	?30			;	not there yet: keep time
	bne	qtexit			;	beyond: don't run timer
	lda	fline			;	if finish line on screen: run
	bmi	qtexit			;	else don't run timer

?30	inc	laptimel		;track the qualify time
	lda	laptimel		;
	cmp	#60			;
	bne	qtexit			;
	inc	laptimeh		;
	lda	#0			;
	sta	laptimel		;
qtexit	lda	laptimeh
	ldx	laptimel
	jsr	numout

	lda	TSKlap			;flash 2 times a second after...
	cmp	#2			;...the trial lap
	bcc	?20
	lda	laptimel
	beq	?10
	cmp	#30
	bne	?20
?10	lda	sprbuf+(64)+niobja	;T
	eor	#niobjprior 		;sprites above background
	sta	sprbuf+(64)+niobja	;T
	lda	sprbuf+(68)+niobja	;R
	eor	#niobjprior		;sprites above background
	sta	sprbuf+(68)+niobja	;R
	lda	sprbuf+(72)+niobja	;I
	eor	#niobjprior 		;sprites above background
	sta	sprbuf+(72)+niobja	;I
	lda	sprbuf+(76)+niobja	;A
	eor	#niobjprior 		;sprites above background
	sta	sprbuf+(76)+niobja	;A
	lda	sprbuf+(80)+niobja	;L
	eor	#niobjprior 		;sprites above background
	sta	sprbuf+(80)+niobja	;L
	lda	sprbuf+(84)+niobja	;L
	eor	#niobjprior 		;sprites above background
	sta	sprbuf+(84)+niobja	;L
	lda	sprbuf+(88)+niobja	;A
	eor	#niobjprior 		;sprites above background
	sta	sprbuf+(88)+niobja	;A
	lda	sprbuf+(92)+niobja	;P
	eor	#niobjprior 		;sprites above background
	sta	sprbuf+(92)+niobja	;P
	jsr	ticktock
?20	rts

;niobjsz	equ 4			;# bytes in record
;niobjy		equ 0			;y position
;niobjc		equ 1			;character
;niobja		equ 2			;attribute
;niobjx		equ 3			;x position
;sprbuf

;---
; TICKTOCK - for the laptimer
;---
ticktock:
	lda	laptimeh		;only tick if different second
	cmp	fline+3			;
	beq	ttexit			;
	sta	fline+3		;save for next compare

	lda	#$15			;and a little noise
	sta	nidutyD
	lda	#$87
	sta	nifreqD
	lda	#$28
	sta	nilengthD
ttexit	rts

wrenchsnd2
	lda	#$15
	sta	nidutyD
	lda	#$85
	sta	nifreqD
	lda	#$28
	sta	nilengthD
	rts
	rts

;---
; NUMOUT - adapted from Nick's routine
;---
numout:	
	ldy	#100			;get 100's digit
	jsr	divy			;divide A by Y
	sty	sprbuf+(40)+niobjc	;quotient in Y, remainder in A

	ldy	#10			;get 10's digit
	jsr	divy
	sty	sprbuf+(44)+niobjc

	clc
	adc	#112			;digit0 (offset in the char set)
	sta	sprbuf+(48)+niobjc	;convert unit's to 'ascii'

	lda	sprbuf+(40)+niobjc
	clc
	adc	#112			;digit0 (offset in the char set)
	sta	sprbuf+(40)+niobjc	;convert 10's to 'ascii'

	lda	sprbuf+(44)+niobjc
	clc
	adc	#112			;digit0 (offset in the char set)
	sta	sprbuf+(44)+niobjc	;convert 100's to 'ascii'

	lda	#155			;period
	sta	sprbuf+(52)+niobjc	;

	txa				;get 10ths & 100ths
	ldy	#10			;get 10th's digit
	jsr	divy
	sty	sprbuf+(56)+niobjc

	clc
	adc	#112			;digit0 (offset in the char set)
	sta	sprbuf+(60)+niobjc	;convert 100th's to 'ascii'

	lda	sprbuf+(56)+niobjc
	clc
	adc	#112			;digit0 (offset in the char set)
	sta	sprbuf+(56)+niobjc	;convert 10th's to 'ascii'

	lda	#35			;y value for time display
	sta	sprbuf+(40)+niobjy	;100's
	sta	sprbuf+(44)+niobjy	; 10's
	sta	sprbuf+(48)+niobjy	;  1's
	sta	sprbuf+(52)+niobjy	;period
	sta	sprbuf+(56)+niobjy	;1/10's
	sta	sprbuf+(60)+niobjy	;1/100's
	lda	#96			;first x value for time display
	sta	sprbuf+(40)+niobjx	;100's
	lda	#96+8
	sta	sprbuf+(44)+niobjx	; 10's
	lda	#96+8+8
	sta	sprbuf+(48)+niobjx	;  1's
	lda	#96+8+8+8
	sta	sprbuf+(52)+niobjx	;period
	lda	#96+8+8+8+8
	sta	sprbuf+(56)+niobjx	;1/10's
	lda	#96+8+8+8+8+8
	sta	sprbuf+(60)+niobjx	;1/100's

	lda	#$3D-niobjprior 	;sprites above background
	sta	sprbuf+(40)+niobja	;100's
	sta	sprbuf+(44)+niobja	; 10's
	sta	sprbuf+(48)+niobja	;  1's
	sta	sprbuf+(52)+niobja	;period
	sta	sprbuf+(56)+niobja	;1/10's
	sta	sprbuf+(60)+niobja	;1/100's

	rts

;---
; DIVY - Divide A by Y
;---
divy:	sty	debcnt
	ldy	#0
divyl	cmp	debcnt
	bcc	divyx
	iny
	sec
	sbc	debcnt
	bcs	divyl			;no underflow
divyx	rts

;---
; joystick directions
;
;  10  8  9 		niright		equ $01		;right
;    \ | / 		nileft		equ $02		;left
;  2 -   - 1 		nidown		equ $04		;down
;    / | \ 		niup		equ $08		;up
;   6  4  5
;---
steeringl
	db	0			; 0 = no arrows pressed
	db	<turnmed		; 1 = right
	db	<-turnmed		; 2 = left
	db	0			; 3 = impossible
	db	0			; 4 = down
	db	<turnfast		; 5 = right/down
	db	<-turnfast		; 6 = left/down
	db	0			; 7 = impossible
	db	0			; 8 = up
	db	<turnslow		; 9 = right/up
	db	<-turnslow		;10 = left/up
	db	0			;11 = impossible
	db	0			;12 = impossible
	db	0			;13 = impossible
	db	0			;14 = impossible
	db	0			;15 = impossible

;---
; joystick directions
;
;  10  8  9 		niright		equ $01		;right
;    \ | / 		nileft		equ $02		;left
;  2 -   - 1 		nidown		equ $04		;down
;    / | \ 		niup		equ $08		;up
;   6  4  5
;---
steeringh
	db	0			; 0 = no arrows pressed
	db	>turnmed		; 1 = right
	db	>-turnmed		; 2 = left
	db	0			; 3 = impossible
	db	0			; 4 = down
	db	>turnfast		; 5 = right/down
	db	>-turnfast		; 6 = left/down
	db	0			; 7 = impossible
	db	0			; 8 = up
	db	>turnslow		; 9 = right/up
	db	>-turnslow		;10 = left/up
	db	0			;11 = impossible
	db	0			;12 = impossible
	db	0			;13 = impossible
	db	0			;14 = impossible
	db	0			;15 = impossible

;---
; list of frames of squeezed data
;---
frame_list:
	db	00,01,02,03,04,05,06,07,08,09		;10
	db	10,11,12,13,14,15,16,17,18,19		;20
	db	20,21,22,23,24,25,26,27,28,29		;30
	db	30,31,32,33,34,35,36,37,38,39		;40
	db	40,41,42,43,44,45,46,47,48,49		;50
	db	50,51,52,53,54,55			;56
	db	54,53,52,51,49,48,47,46,45		;65
	db	56,57,58,59				;69
	db	60,61,62,63,64,65,66,67,68		;78
flend:

;---
; number of times a frame is used
;---
frame_len:
	db	10*maxspeed		;frame 000
	db	10*maxspeed		;frame 002
	db	10*maxspeed		;frame 004
	db	09*maxspeed		;frame 006
	db	09*maxspeed		;frame 008
	db	09*maxspeed		;frame 010
	db	09*maxspeed		;frame 012
	db	09*maxspeed		;frame 014
	db	09*maxspeed		;frame 016
	db	09*maxspeed		;frame 018
	db	09*maxspeed		;frame 020
	db	09*maxspeed		;frame 022
	db	08*maxspeed		;frame 024
	db	08*maxspeed		;frame 026
	db	08*maxspeed		;frame 028
	db	08*maxspeed		;frame 030
	db	40*maxspeed		;frame 032  straightaway knob
	db	40*maxspeed		;frame 034  straightaway knob
	db	40*maxspeed		;frame 036  straightaway knob
	db	40*maxspeed		;frame 039  straightaway knob
	db	40*maxspeed		;frame 042  straightaway knob
	db	40*maxspeed		;frame 045  straightaway knob
	db	40*maxspeed		;frame 048  straightaway knob
	db	40*maxspeed		;frame 051  straightaway knob
	db	07*maxspeed		;frame 054
	db	07*maxspeed		;frame 057
	db	07*maxspeed		;frame 060
	db	06*maxspeed		;frame 063
	db	06*maxspeed		;frame 066
	db	06*maxspeed		;frame 068
	db	06*maxspeed		;frame 070
	db	06*maxspeed		;frame 072
	db	06*maxspeed		;frame 074
	db	05*maxspeed		;frame 076
	db	05*maxspeed		;frame 078
	db	05*maxspeed		;frame 080
	db	05*maxspeed		;frame 082
	db	05*maxspeed		;frame 084
	db	04*maxspeed		;frame 086
	db	04*maxspeed		;frame 088
	db	04*maxspeed		;frame 090
	db	04*maxspeed		;frame 092
	db	03*maxspeed		;frame 094
	db	03*maxspeed		;frame 096
	db	03*maxspeed		;frame 098
	db	02*maxspeed		;frame 100
	db	02*maxspeed		;frame 102
	db	02*maxspeed		;frame 104
	db	02*maxspeed		;frame 106
	db	02*maxspeed		;frame 108
	db	02*maxspeed		;frame 110
	db	02*maxspeed		;frame 112
	db	40*maxspeed		;frame 114 turn knob
	db	40*maxspeed		;frame 116 turn knob
	db	40*maxspeed		;frame 118 turn knob
	db	40*maxspeed		;frame 120 max curve
	db	40*maxspeed		;frame 118 turn knob
	db	40*maxspeed		;frame 116 turn knob
	db	40*maxspeed		;frame 114 turn knob
	db	40*maxspeed		;frame 112 turn knob
	db	20*maxspeed		;frame 110 turn knob
	db	10*maxspeed		;frame 108 turn knob
	db	10*maxspeed		;frame 106 turn knob
	db	03*maxspeed		;frame 104
	db	03*maxspeed		;frame 102
	db	04*maxspeed		;frame 100
	db	04*maxspeed		;frame 122
	db	04*maxspeed		;frame 124
	db	04*maxspeed		;frame 126
	db	05*maxspeed		;frame 128
	db	05*maxspeed		;frame 130
	db	05*maxspeed		;frame 132
	db	05*maxspeed		;frame 134
	db	05*maxspeed		;frame 136
	db	06*maxspeed		;frame 138
	db	08*maxspeed		;frame 140
	db	10*maxspeed		;frame 142
	db	10*maxspeed		;frame 144
	db	10*maxspeed		;frame 146

;---
; CFTABLE - centripetal force table
;---
cftable:
	db	0			;frame 000
	db	0			;frame 002
	db	0			;frame 004
	db	0			;frame 006
	db	0			;frame 008
	db	0			;frame 010
	db	0			;frame 012
	db	0			;frame 014
	db	0			;frame 016
	db	0			;frame 018
	db	0			;frame 020
	db	0			;frame 022
	db	0			;frame 024
	db	0			;frame 026
	db	0			;frame 028
	db	0			;frame 030
	db	0			;frame 032
	db	0			;frame 034
	db	0			;frame 036
	db	0			;frame 039
	db	0			;frame 042
	db	0			;frame 045
	db	0			;frame 048
	db	0			;frame 051
	db	0			;frame 054
	db	0			;frame 057
	db	0			;frame 060
	db	0			;frame 063
	db	0			;frame 066
	db	2			;frame 068
	db	2			;frame 070
	db	2			;frame 072
	db	2			;frame 074
	db	2			;frame 076
	db	2			;frame 078
	db	2			;frame 080
	db	3			;frame 082
	db	4			;frame 084
	db	5			;frame 086
	db	6			;frame 088
	db	7			;frame 090
	db	8			;frame 092
	db	9			;frame 094
	db	10			;frame 096
	db	11			;frame 098
	db	12			;frame 100
	db	13			;frame 102
	db	14			;frame 104
	db	15			;frame 106
	db	16			;frame 108
	db	17			;frame 110
	db	18			;frame 112
	db	19+1			;frame 114
	db	20+2			;frame 116
	db	21+3			;frame 118
	db	22+4			;frame 120 max curve
	db	21+5			;frame 118
	db	20+6			;frame 116
	db	19+5			;frame 114
	db	18+4			;frame 112
	db	17+3			;frame 110
	db	16+2			;frame 108
	db	15+1			;frame 106
	db	14			;frame 104
	db	13			;frame 102
	db	12			;frame 100
	db	11			;frame 122
	db	10			;frame 124
	db	9			;frame 126
	db	8			;frame 128
	db	7			;frame 130
	db	6			;frame 132
	db	5			;frame 134
	db	4			;frame 136
	db	3			;frame 138
	db	2			;frame 140
	db	2			;frame 142
	db	2			;frame 144
	db	2			;frame 146

;---
; VPX - vanishing point x (by frame)
;---
vpx:
	db	209-128			;frame 000
	db	218-128			;frame 002
	db	220-128			;frame 004
	db	222-128			;frame 006
	db	217-128			;frame 008
	db	210-128			;frame 010
	db	210-128			;frame 012
	db	210-128			;frame 014
	db	210-128			;frame 016
	db	210-128			;frame 018
	db	211-128			;frame 020
	db	211-128			;frame 022
	db	212-128			;frame 024
	db	213-128			;frame 026
	db	214-128			;frame 028
	db	215-128			;frame 030
	db	217-128			;frame 032
	db	219-128			;frame 034
	db	220-128			;frame 036
	db	222-128			;frame 039
	db	224-128			;frame 042
	db	225-128			;frame 045
	db	225-128			;frame 048
	db	226-128			;frame 051
	db	225-128			;frame 054
	db	225-128			;frame 057
	db	224-128			;frame 060
	db	223-128			;frame 063
	db	218-128			;frame 066
	db	215-128			;frame 068
	db	215-128			;frame 070
	db	216-128			;frame 072
	db	216-128			;frame 074
	db	213-128			;frame 076
	db	213-128			;frame 078
	db	201-128			;frame 080
	db	197-128			;frame 082
	db	190-128			;frame 084
	db	182-128			;frame 086
	db	173-128			;frame 088
	db	167-128			;frame 090
	db	162-128			;frame 092
	db	155-128			;frame 094
	db	147-128			;frame 096
	db	140-128			;frame 098
	db	134-128			;frame 100
	db	136-128			;frame 102
	db	136-128			;frame 104
	db	137-128			;frame 106
	db	138-128			;frame 108
	db	139-128			;frame 110
	db	140-128			;frame 112
	db	140-128			;frame 114
	db	139-128			;frame 116
	db	139-128			;frame 118
	db	139-128			;frame 120 max curve
	db	139-128			;frame 118
	db	139-128			;frame 116
	db	140-128			;frame 114
	db	140-128			;frame 112
	db	139-128			;frame 110
	db	138-128			;frame 108
	db	137-128			;frame 106
	db	136-128			;frame 104
	db	136-128			;frame 102
	db	134-128			;frame 100
	db	141-128			;frame 122
	db	145-128			;frame 124
	db	150-128			;frame 126
	db	154-128			;frame 128
	db	165-128			;frame 130
	db	173-128			;frame 132
	db	181-128			;frame 134
	db	185-128			;frame 136
	db	189-128			;frame 138
	db	197-128			;frame 140
	db	201-128			;frame 142
	db	201-128			;frame 144
	db	204-128			;frame 146

;---
; VPY - vanishing point y (by frame)
;---
vpy:
miny	equ	73-8
	db	78-8			;frame 000
	db	81-8			;frame 002
	db	83-8			;frame 004
	db	85-8			;frame 006
	db	84-8			;frame 008
	db	82-8			;frame 010
	db	83-8			;frame 012
	db	84-8			;frame 014
	db	85-8			;frame 016
	db	86-8			;frame 018
	db	87-8			;frame 020
	db	88-8			;frame 022
	db	88-8			;frame 024
	db	89-8			;frame 026
	db	89-8			;frame 028
	db	89-8			;frame 030
	db	89-8			;frame 032
	db	89-8			;frame 034
	db	89-8			;frame 036
	db	89-8			;frame 039
	db	89-8			;frame 042
	db	89-8			;frame 045
	db	89-8			;frame 048
	db	88-8			;frame 051
	db	87-8			;frame 054
	db	86-8			;frame 057
	db	85-8			;frame 060
	db	84-8			;frame 063
	db	84-8			;frame 066
	db	84-8			;frame 068
	db	84-8			;frame 070
	db	84-8			;frame 072
	db	84-8			;frame 074
	db	84-8			;frame 076
	db	84-8			;frame 078
	db	83-8			;frame 080
	db	82-8			;frame 082
	db	81-8			;frame 084
	db	80-8			;frame 086
	db	79-8			;frame 088
	db	78-8			;frame 090
	db	77-8			;frame 092
	db	76-8			;frame 094
	db	75-8			;frame 096
	db	74-8			;frame 098
	db	73-8			;frame 100
	db	73-8			;frame 102
	db	73-8			;frame 104
	db	73-8			;frame 106
	db	73-8			;frame 108
	db	73-8			;frame 110
	db	73-8			;frame 112
	db	73-8			;frame 114
	db	73-8			;frame 116
	db	73-8			;frame 118
	db	73-8			;frame 120 max curve
	db	73-8			;frame 118
	db	73-8			;frame 116
	db	73-8			;frame 114
	db	73-8			;frame 112
	db	73-8			;frame 110
	db	73-8			;frame 108
	db	73-8			;frame 106
	db	73-8			;frame 104
	db	73-8			;frame 102
	db	73-8			;frame 100
	db	73-8			;frame 122
	db	73-8			;frame 124
	db	73-8			;frame 126
	db	73-8			;frame 128
	db	74-8			;frame 130
	db	74-8			;frame 132
	db	75-8			;frame 134
	db	75-8			;frame 136
	db	75-8			;frame 138
	db	76-8			;frame 140
	db	76-8			;frame 142
	db	76-8			;frame 144
	db	77-8			;frame 146

;---
; XDELTA - strip x deltas
;---
xdeltal:
	db	#<(512+025-128)		;frame 000
	db	#<(512+007-128)		;frame 002
	db	#<(512+021-128)		;frame 004
	db	#<(512+038-128)		;frame 006
	db	#<(512+044-128)		;frame 008
	db	#<(512+042-128)		;frame 010
	db	#<(512+028-128)		;frame 012
	db	#<(512+015-128)		;frame 014
	db	#<(512+015-128)		;frame 016
	db	#<(256+248-128)		;frame 018
	db	#<(256+248-128)		;frame 020
	db	#<(256+240-128)		;frame 022
	db	#<(256+207-128)		;frame 024
	db	#<(256+205-128)		;frame 026
	db	#<(256+187-128)		;frame 028
	db	#<(256+171-128)		;frame 030
	db	#<(256+154-128)		;frame 032
	db	#<(256+128-128)		;frame 034
	db	#<(256+110-128)		;frame 036
	db	#<(256+094-128)		;frame 039
	db	#<(256+077-128)		;frame 042
	db	#<(256+068-128)		;frame 045
	db	#<(256+068-128)		;frame 048
	db	#<(256+058-128)		;frame 051
	db	#<(256+072-128)		;frame 054
	db	#<(256+078-128)		;frame 057
	db	#<(256+090-128)		;frame 060
	db	#<(256+102-128)		;frame 063
	db	#<(256+161-128)		;frame 066
	db	#<(256+197-128)		;frame 068
	db	#<(256+212-128)		;frame 070
	db	#<(256+219-128)		;frame 072
	db	#<(256+219-128)		;frame 074
	db	#<(256+240-128)		;frame 076
	db	#<(256+250-128)		;frame 078
	db	#<(512+042-128)		;frame 080
	db	#<(512+055-128)		;frame 082
	db	#<(512+074-128)		;frame 084
	db	#<(512+098-128)		;frame 086
	db	#<(512+122-128)		;frame 088
	db	#<(512+131-128)		;frame 090
	db	#<(512+146-128)		;frame 092
	db	#<(512+150-128)		;frame 094
	db	#<(512+157-128)		;frame 096
	db	#<(512+171-128)		;frame 098
	db	#<(512+178-128)		;frame 100
	db	#<(512+156-128)		;frame 102
	db	#<(512+145-128)		;frame 104
	db	#<(512+122-128)		;frame 106
	db	#<(512+122-128)		;frame 108
	db	#<(512+089-128)		;frame 110
	db	#<(512+067-128)		;frame 112
	db	#<(512+056-128)		;frame 114
	db	#<(512+045-128)		;frame 116
	db	#<(512+028-128)		;frame 118
	db	#<(512+017-128)		;frame 120 max curve
	db	#<(512+028-128)		;frame 118
	db	#<(512+045-128)		;frame 116
	db	#<(512+056-128)		;frame 114
	db	#<(512+067-128)		;frame 112
	db	#<(512+089-128)		;frame 110
	db	#<(512+122-128)		;frame 108
	db	#<(512+122-128)		;frame 106
	db	#<(512+145-128)		;frame 104
	db	#<(512+156-128)		;frame 102
	db	#<(512+178-128)		;frame 100
	db	#<(512+134-128)		;frame 122
	db	#<(512+117-128)		;frame 124
	db	#<(512+095-128)		;frame 126
	db	#<(512+083-128)		;frame 128
	db	#<(512+051-128)		;frame 130
	db	#<(512+034-128)		;frame 132
	db	#<(512+018-128)		;frame 134
	db	#<(512+012-128)		;frame 136
	db	#<(512+018-128)		;frame 138
	db	#<(512+000-128)		;frame 140
	db	#<(512+000-128)		;frame 142
	db	#<(512+018-128)		;frame 144
	db	#<(512+037-128)		;frame 146
xdeltah:
	db	#>(512+025-128)		;frame 000
	db	#>(512+007-128)		;frame 002
	db	#>(512+021-128)		;frame 004
	db	#>(512+038-128)		;frame 006
	db	#>(512+044-128)		;frame 008
	db	#>(512+042-128)		;frame 010
	db	#>(512+028-128)		;frame 012
	db	#>(512+015-128)		;frame 014
	db	#>(512+015-128)		;frame 016
	db	#>(256+248-128)		;frame 018
	db	#>(256+248-128)		;frame 020
	db	#>(256+240-128)		;frame 022
	db	#>(256+207-128)		;frame 024
	db	#>(256+205-128)		;frame 026
	db	#>(256+187-128)		;frame 028
	db	#>(256+171-128)		;frame 030
	db	#>(256+154-128)		;frame 032
	db	#>(256+128-128)		;frame 034
	db	#>(256+110-128)		;frame 036
	db	#>(256+094-128)		;frame 039
	db	#>(256+077-128)		;frame 042
	db	#>(256+068-128)		;frame 045
	db	#>(256+068-128)		;frame 048
	db	#>(256+058-128)		;frame 051
	db	#>(256+072-128)		;frame 054
	db	#>(256+078-128)		;frame 057
	db	#>(256+090-128)		;frame 060
	db	#>(256+102-128)		;frame 063
	db	#>(256+161-128)		;frame 066
	db	#>(256+197-128)		;frame 068
	db	#>(256+212-128)		;frame 070
	db	#>(256+219-128)		;frame 072
	db	#>(256+219-128)		;frame 074
	db	#>(256+240-128)		;frame 076
	db	#>(256+250-128)		;frame 078
	db	#>(512+042-128)		;frame 080
	db	#>(512+055-128)		;frame 082
	db	#>(512+074-128)		;frame 084
	db	#>(512+098-128)		;frame 086
	db	#>(512+122-128)		;frame 088
	db	#>(512+131-128)		;frame 090
	db	#>(512+146-128)		;frame 092
	db	#>(512+150-128)		;frame 094
	db	#>(512+157-128)		;frame 096
	db	#>(512+171-128)		;frame 098
	db	#>(512+178-128)		;frame 100
	db	#>(512+156-128)		;frame 102
	db	#>(512+145-128)		;frame 104
	db	#>(512+122-128)		;frame 106
	db	#>(512+122-128)		;frame 108
	db	#>(512+089-128)		;frame 110
	db	#>(512+067-128)		;frame 112
	db	#>(512+056-128)		;frame 114
	db	#>(512+045-128)		;frame 116
	db	#>(512+028-128)		;frame 118
	db	#>(512+017-128)		;frame 120 max curve
	db	#>(512+028-128)		;frame 118
	db	#>(512+045-128)		;frame 116
	db	#>(512+056-128)		;frame 114
	db	#>(512+067-128)		;frame 112
	db	#>(512+089-128)		;frame 110
	db	#>(512+122-128)		;frame 108
	db	#>(512+122-128)		;frame 106
	db	#>(512+145-128)		;frame 104
	db	#>(512+156-128)		;frame 102
	db	#>(512+178-128)		;frame 100
	db	#>(512+134-128)		;frame 122
	db	#>(512+117-128)		;frame 124
	db	#>(512+095-128)		;frame 126
	db	#>(512+083-128)		;frame 128
	db	#>(512+051-128)		;frame 130
	db	#>(512+034-128)		;frame 132
	db	#>(512+018-128)		;frame 134
	db	#>(512+012-128)		;frame 136
	db	#>(512+018-128)		;frame 138
	db	#>(512+000-128)		;frame 140
	db	#>(512+000-128)		;frame 142
	db	#>(512+018-128)		;frame 144
	db	#>(512+037-128)		;frame 146

;---
; XMOVE - x movement of the VP between this frame and the last
;---
xmove:
	db	(209-128)-(204-128)	;frame 000
	db	(218-128)-(209-128)	;frame 002
	db	(220-128)-(218-128)	;frame 004
	db	(222-128)-(220-128)	;frame 006
	db	(217-128)-(222-128)	;frame 008
	db	(210-128)-(217-128)	;frame 010
	db	(210-128)-(210-128)	;frame 012
	db	(210-128)-(210-128)	;frame 014
	db	(210-128)-(210-128)	;frame 016
	db	(210-128)-(210-128)	;frame 018
	db	(211-128)-(210-128)	;frame 020
	db	(211-128)-(211-128)	;frame 022
	db	(212-128)-(211-128)	;frame 024
	db	(213-128)-(212-128)	;frame 026
	db	(214-128)-(213-128)	;frame 028
	db	(215-128)-(214-128)	;frame 030
	db	(217-128)-(215-128)	;frame 032
	db	(219-128)-(217-128)	;frame 034
	db	(220-128)-(219-128)	;frame 036
	db	(222-128)-(220-128)	;frame 039
	db	(224-128)-(222-128)	;frame 042
	db	(225-128)-(224-128)	;frame 045
	db	(225-128)-(225-128)	;frame 048
	db	(226-128)-(225-128)	;frame 051
	db	(225-128)-(226-128)	;frame 054
	db	(225-128)-(225-128)	;frame 057
	db	(224-128)-(225-128)	;frame 060
	db	(223-128)-(224-128)	;frame 063
	db	(218-128)-(223-128)	;frame 066
	db	(215-128)-(218-128)	;frame 068
	db	(215-128)-(215-128)	;frame 070
	db	(216-128)-(215-128)	;frame 072
	db	(216-128)-(216-128)	;frame 074
	db	(213-128)-(216-128)	;frame 076
	db	(213-128)-(213-128)	;frame 078
	db	(201-128)-(213-128)	;frame 080
	db	(197-128)-(201-128)	;frame 082
	db	(190-128)-(197-128)	;frame 084
	db	(182-128)-(190-128)	;frame 086
	db	(173-128)-(182-128)	;frame 088
	db	(167-128)-(173-128)	;frame 090
	db	(162-128)-(167-128)	;frame 092
	db	(155-128)-(162-128)	;frame 094
	db	(147-128)-(155-128)	;frame 096
	db	(140-128)-(147-128)	;frame 098
	db	(134-128)-(140-128)	;frame 100
	db	(136-128)-(134-128)	;frame 102
	db	(136-128)-(136-128)	;frame 104
	db	(137-128)-(136-128)	;frame 106
	db	(138-128)-(137-128)	;frame 108
	db	(139-128)-(138-128)	;frame 110
	db	(140-128)-(139-128)	;frame 112
	db	(140-128)-(140-128)	;frame 114
	db	(139-128)-(140-128)	;frame 116
	db	(139-128)-(139-128)	;frame 118
	db	(139-128)-(139-128)	;frame 120 max curve
	db	(139-128)-(139-128)	;frame 118
	db	(139-128)-(139-128)	;frame 116
	db	(140-128)-(139-128)	;frame 114
	db	(140-128)-(140-128)	;frame 112
	db	(139-128)-(140-128)	;frame 110
	db	(138-128)-(139-128)	;frame 108
	db	(137-128)-(138-128)	;frame 106
	db	(136-128)-(137-128)	;frame 104
	db	(136-128)-(136-128)	;frame 102
	db	(134-128)-(136-128)	;frame 100
	db	(141-128)-(134-128)	;frame 122
	db	(145-128)-(141-128)	;frame 124
	db	(150-128)-(145-128)	;frame 126
	db	(154-128)-(150-128)	;frame 128
	db	(165-128)-(154-128)	;frame 130
	db	(173-128)-(165-128)	;frame 132
	db	(181-128)-(173-128)	;frame 134
	db	(185-128)-(181-128)	;frame 136
	db	(189-128)-(185-128)	;frame 138
	db	(197-128)-(189-128)	;frame 140
	db	(201-128)-(197-128)	;frame 142
	db	(201-128)-(201-128)	;frame 144
	db	(204-128)-(201-128)	;frame 146

;---
; YMOVE - y movement of the VP between this and the last frame
;---
ymove:
	db	(78-8)-(77-8)	;frame 000
	db	(81-8)-(78-8)	;frame 002
	db	(83-8)-(81-8)	;frame 004
	db	(85-8)-(83-8)	;frame 006
	db	(84-8)-(85-8)	;frame 008
	db	(82-8)-(84-8)	;frame 010
	db	(83-8)-(82-8)	;frame 012
	db	(84-8)-(83-8)	;frame 014
	db	(85-8)-(84-8)	;frame 016
	db	(86-8)-(85-8)	;frame 018
	db	(87-8)-(86-8)	;frame 020
	db	(88-8)-(87-8)	;frame 022
	db	(88-8)-(88-8)	;frame 024
	db	(89-8)-(88-8)	;frame 026
	db	(89-8)-(89-8)	;frame 028
	db	(89-8)-(89-8)	;frame 030
	db	(89-8)-(89-8)	;frame 032
	db	(89-8)-(89-8)	;frame 034
	db	(89-8)-(89-8)	;frame 036
	db	(89-8)-(89-8)	;frame 039
	db	(89-8)-(89-8)	;frame 042
	db	(89-8)-(89-8)	;frame 045
	db	(89-8)-(89-8)	;frame 048
	db	(88-8)-(89-8)	;frame 051
	db	(87-8)-(88-8)	;frame 054
	db	(86-8)-(87-8)	;frame 057
	db	(85-8)-(86-8)	;frame 060
	db	(84-8)-(85-8)	;frame 063
	db	(84-8)-(84-8)	;frame 066
	db	(84-8)-(84-8)	;frame 068
	db	(84-8)-(84-8)	;frame 070
	db	(84-8)-(84-8)	;frame 072
	db	(84-8)-(84-8)	;frame 074
	db	(84-8)-(84-8)	;frame 076
	db	(84-8)-(84-8)	;frame 078
	db	(83-8)-(84-8)	;frame 080
	db	(82-8)-(83-8)	;frame 082
	db	(81-8)-(82-8)	;frame 084
	db	(80-8)-(81-8)	;frame 086
	db	(79-8)-(80-8)	;frame 088
	db	(78-8)-(79-8)	;frame 090
	db	(77-8)-(78-8)	;frame 092
	db	(76-8)-(77-8)	;frame 094
	db	(75-8)-(76-8)	;frame 096
	db	(74-8)-(75-8)	;frame 098
	db	(73-8)-(74-8)	;frame 100
	db	(73-8)-(73-8)	;frame 102
	db	(73-8)-(73-8)	;frame 104
	db	(73-8)-(73-8)	;frame 106
	db	(73-8)-(73-8)	;frame 108
	db	(73-8)-(73-8)	;frame 110
	db	(73-8)-(73-8)	;frame 112
	db	(73-8)-(73-8)	;frame 114
	db	(73-8)-(73-8)	;frame 116
	db	(73-8)-(73-8)	;frame 118
	db	(73-8)-(73-8)	;frame 120 max curve
	db	(73-8)-(73-8)	;frame 118
	db	(73-8)-(73-8)	;frame 116
	db	(73-8)-(73-8)	;frame 114
	db	(73-8)-(73-8)	;frame 112
	db	(73-8)-(73-8)	;frame 110
	db	(73-8)-(73-8)	;frame 108
	db	(73-8)-(73-8)	;frame 106
	db	(73-8)-(73-8)	;frame 104
	db	(73-8)-(73-8)	;frame 102
	db	(73-8)-(73-8)	;frame 100
	db	(73-8)-(73-8)	;frame 122
	db	(73-8)-(73-8)	;frame 124
	db	(73-8)-(73-8)	;frame 126
	db	(73-8)-(73-8)	;frame 128
	db	(74-8)-(73-8)	;frame 130
	db	(74-8)-(74-8)	;frame 132
	db	(75-8)-(74-8)	;frame 134
	db	(75-8)-(75-8)	;frame 136
	db	(75-8)-(75-8)	;frame 138
	db	(76-8)-(75-8)	;frame 140
	db	(76-8)-(76-8)	;frame 142
	db	(76-8)-(76-8)	;frame 144
	db	(77-8)-(76-8)	;frame 146

;---
; palette data
;---
pal1st
	db	$00,$2C,$2A,$20		;dkgray	cyan	medgrn	medwhite
	db	$00,$0F,$0F,$20		;dkgray	black	black	medwhite
 	db	$00,$08,$0F,$38		;dkgray	dkbrown	black	yellow
 	db	$00,$0C,$10,$06		;dkgray	dkcyan	medgray	dark red
; Sprites
	db	$00,$0F,$26,$26
	db	$00,$26,$26,$26
	db	$00,$2A,$2A,$2A
	db	$00,$20,$20,$20
palvanity
	db	$1C,$3C,$0C,$30		;medcyn	ltcyan	dkcyan	white
	db	$1C,$0F,$0F,$20		;medcyn	black	black	medwhite
 	db	$1C,$08,$0F,$38		;medcyn	dkbrown	black	yellow
 	db	$1C,$12,$18,$38		;medcyn	medblue	brown	yellow
; Sprites
	db	$1C,$15,$38,$00
	db	$1C,$2c,$38,$22
	db	$1C,$00,$22,$06
	db	$1C,$3d,$30,$0A

road_col:
	db	$55,$55,$55,$55,$55,$55,$55,$55
	db	$05,$05,$05,$05,$05,$05,$05,$05
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0
	db	$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	db	$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	db	$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	db	$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F

;---
;	qdash.map
;---
dash_map:
	db	$01,$01,$01,$01,$01,$01,$01,$01
	db	$01,$01,$01,$01,$01,$01,$01,$01
	db	$01,$01,$01,$01,$01,$01,$01,$01
	db	$01,$01,$01,$01,$01,$01,$01,$01	;1
	db	$02,$03,$03,$03,$03,$03,$04,$05
	db	$06,$07,$08,$09,$0A,$0B,$03,$03
	db	$03,$03,$03,$03,$03,$03,$03,$03
	db	$03,$03,$03,$03,$03,$03,$03,$0C	;2
	db	$0D,$0E,$0F,$10,$11,$12,$13,$14
	db	$15,$16,$17,$18,$19,$1A,$1B,$1C
	db	$1D,$1E,$1F,$20,$21,$22,$23,$24
	db	$25,$26,$27,$28,$29,$2A,$2B,$2C	;3
	db	$2D,$2E,$2F,$30,$31,$32,$33,$34
	db	$35,$36,$37,$38,$39,$3A,$3B,$3C
	db	$3D,$3E,$3F,$40,$41,$42,$43,$44
	db	$45,$46,$47,$48,$49,$4A,$4B,$4C	;4
	db	$4D,$4E,$4E,$4F,$50,$51,$52,$53
	db	$54,$55,$56,$57,$58,$59,$5A,$5B
	db	$5C,$5D,$5E,$5F,$60,$61,$62,$63
	db	$64,$65,$66,$67,$66,$67,$68,$69	;5
	db	$6A,$6B,$6C,$6D,$6E,$6F,$70,$71
	db	$72,$73,$74,$75,$76,$77,$78,$79
	db	$7A,$7B,$7C,$7D,$70,$70,$7E,$7F
	db	$80,$81,$82,$83,$84,$83,$85,$86	;6
	db	$87,$88,$89,$89,$8A,$8B,$89,$8C
	db	$8D,$00,$00,$8E,$8F,$89,$90,$91
	db	$92,$89,$89,$89,$89,$89,$89,$89
	db	$89,$89,$89,$89,$93,$94,$95,$96	;7
	db	$97,$97,$97,$97,$98,$99,$97,$9A
	db	$9B,$97,$97,$9B,$9C,$97,$9D,$9E
	db	$9F,$97,$97,$97,$97,$97,$97,$97
	db	$97,$97,$97,$97,$97,$97,$97,$A0	;8
	db	$01,$01,$01,$01,$01,$01,$01,$01
	db	$01,$01,$01,$01,$01,$01,$01,$01
	db	$01,$01,$01,$01,$01,$01,$01,$01
	db	$01,$01,$01,$01,$01,$01,$01,$01	;9

;---
; VANITY_MAP - name entry screen
;---
vanity_map:
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
	db	$00,$00,$00,$00,$3C,$3D,$3D,$3D
	db	$3D,$3D,$3D,$3D,$3D,$3D,$3D,$3D
	db	$3D,$3D,$3D,$3D,$3D,$3D,$3D,$3D
	db	$3D,$3D,$3D,$3D,$3E,$00,$00,$00
	db	$00,$00,$00,$00,$43,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$00,$43,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$00,$43,$00,$00,$21
	db	$00,$00,$22,$00,$00,$23,$00,$00
	db	$24,$00,$00,$25,$00,$00,$26,$00
	db	$00,$27,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$00,$43,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$00,$43,$00,$00,$28
	db	$00,$00,$29,$00,$00,$2A,$00,$00
	db	$2B,$00,$00,$2C,$00,$00,$2D,$00
	db	$00,$2E,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$00,$43,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$00,$43,$00,$00,$2F
	db	$00,$00,$30,$00,$00,$31,$00,$00
	db	$32,$00,$00,$33,$00,$00,$34,$00
	db	$00,$35,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$00,$43,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$00,$43,$00,$00,$36
	db	$00,$00,$37,$00,$00,$38,$00,$00
	db	$39,$00,$00,$3A,$00,$00,$45,$00
	db	$00,$46,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$00,$43,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$00,$43,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$00,$43,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$00,$43,$00,$00,$00
	db	$00,$00,$47,$47,$47,$47,$47,$47
	db	$47,$47,$47,$47,$47,$47,$47,$47
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$00,$43,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$00,$43,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$00,$44,$42,$42,$42
	db	$42,$42,$42,$42,$42,$42,$42,$42
	db	$42,$42,$42,$42,$42,$42,$42,$42
	db	$42,$42,$42,$42,$41,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$3C,$3D,$3D,$3D
	db	$3D,$3D,$3D,$3D,$3D,$3D,$3D,$3D
	db	$3D,$3D,$3D,$3D,$3D,$3D,$3D,$3D
	db	$3D,$3D,$3D,$3D,$3E,$00,$00,$00
	db	$00,$00,$00,$00,$43,$30,$2C,$25
	db	$21,$33,$25,$00,$25,$2E,$34,$25
	db	$32,$00,$39,$2F,$35,$32,$00,$2E
	db	$21,$2D,$25,$0E,$3F,$00,$00,$00
	db	$00,$00,$00,$00,$44,$42,$42,$42
	db	$42,$42,$42,$42,$42,$42,$42,$42
	db	$42,$42,$42,$42,$42,$42,$42,$42
	db	$42,$42,$42,$42,$41,$00,$00,$00
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

;---
; NAMEOUT - output name on vanity screen during NMI
;---
nameout
	ldx	#10			;position cursor
	ldy	#16			;
	jsr	setVRAMaddr		;
	ldx	#0			;output 14 characters to peephole
?10:	lda	name,x
	sec
	sbc	space
	sta	nivramdata
	inx
	cpx	#14
	bne	?10
	rts

;---
; vanity2 - name entry screen
;---
vanity2:	lda	#0			;turn off string out routine
	sta	PICvramflag		;
	sta	dashboard		;shut off dashboard

	jsr	nividoff		;turn video off
	
	jsr	hide_sprites		;push sprites offscreen

	lda	#0			;show screen 0 with no vertical scroll
	sta	niscrollv		;
	sta	niscrollv+1		;
	sta	sv_niscrollh		;
	lda	#0			;most significant bit of x scroll
	sta	sv_niscrollm		;

	lda	#1			;new background character set
	sta	nibnkchrSH		;
	lda	#1			;set sprite bank to stripe bank
	sta	nibnksprSH		;

	lda	#<niscreen0		;write vanity frame to screen 0
	sta	VRAMbase		;
	lda	#>niscreen0		;
	sta	VRAMbase+1		;
	ldx	#0			;
	ldy	#0			;
	jsr	setVRAMaddr		;
	jsr	niscrclr_any		;
	ldx	#0			;
	ldy	#0			;
	jsr	setVRAMaddr		;
	lda	#<vanity_map		;
	sta	tvtmp			;
	lda	#>vanity_map		;
	sta	tvtmp+1			;
	ldx	#30			;
	jsr	write_x_lines		;

	jsr	setvanitypal

	lda	#$F0			;sprite 0's Y at window bottom KNOB
	sta	rasterspritey		;

	jsr	nividon			;video on

	jsr	TSKvblank		;turn on name out routine
	dw	nameout	

butup	ldy	#0			;wait for buttons to be up
	jsr	nijoyget		;
	lda	nijoy			;
	bne	butup			;

	lda	#0			;do some housekeeping
	sta	flindex			;
	sta	frame			;
	lda	#128			;
	sta	sprbuf+4+niobjc		;
	lda	xalpha			;
	sta	sprbuf+4+niobjx		;
	lda	yalpha			;
	sta	sprbuf+4+niobjy		;
	lda	#0			;
	sta	sprbuf+4+niobja		;

	lda	#128			;cursor above dashed lines
	sta	sprbuf+8+niobjc		;
	lda	#8*10			;
	sta	sprbuf+8+niobjx		;
	lda	#8*16			;
	sta	sprbuf+8+niobjy		;
	lda	#$fc			;
	sta	sprbuf+8+niobja		;

vmove	ldy	#0			;stick 0
	jsr	nijoyget		;update nijoy with current stick 0

	lda	#10			;position cursor
	clc				;
	adc	flindex			;
	asl	a			;
	asl	a			;
	asl	a			;
	sta	sprbuf+8+niobjx		;

	lda	intflag			;smoo sprite
	and	#$1F			;
	bne	noblink
	lda	sprbuf+4+niobja		;
	xor	#niobjprior		;
	sta	sprbuf+4+niobja		;
	

noblink	lda	nijoy			;branch to routines based on bits
	ror	a			;right arrow pressed?
	bcs	rton			;yes:
	ror	a			;left button pressed?
	bcs	lton			;yes:
	ror	a			;down button pressed?
	bcs	dnon			;yes:
	ror	a			;up button pressed?
	bcs	upon			;yes:
	ror	a			;start button pressed?
	bcc	?10			;no: continue test
	jmp	vexit			;yes: leave this routine
?10	ror	a			;select button pressed?
	ror	a			;B button pressed?
	ror	a			;A button pressed?
	bcc	?40			;no: go back and read again
	jmp	abon			;yes: deposit letter into name buffer
?40	jmp	vmove

rton	inc	frame			;move cursor sprite right
	ldx	frame			;
	cpx	#28			;
	bne	doxy			;
	ldx	#0			;
	stx	frame			;
doxy	lda	xalpha,x		;
	sta	sprbuf+4+niobjx		;
	lda	yalpha,x		;
	sta	sprbuf+4+niobjy		;
rdlay	ldx	#15			;repeat at 4 characters a second
	jsr	waitxnmis		;
	jmp	vmove			;

lton	dec	frame			;move cursor sprite left
	ldx	frame			;
	cpx	#$FF			;
	bne	?10			;
	ldx	#27			;
	stx	frame			;
?10	jmp	doxy

upon	lda	frame			;move cursor sprite up
	sec				;
	sbc	#7			;
	bpl	?10			;
	clc				;
	adc	#28			;
?10	sta	frame			;
	tax				;
	jmp	doxy

dnon	lda	frame			;move cursor sprite down
	clc				;
	adc	#7			;
	cmp	#28			;
	bcc	?10			;
	sec				;
	sbc	#28			;
?10	sta	frame			;
	tax				;
	jmp	doxy

abon	lda	frame			;at control positions?
	cmp	#26			;at delete?
	beq	delete			;
	cmp	#27			;at space?
	beq	spac			;

	lda	frame			;put letter into buffer
	clc				;
	adc	#'A'			;
stash	ldx	flindex			;
	sta	name,x			;

	inc	flindex			;bump to next position in the name
	lda	flindex			;was advance too far?
	cmp	#14			;
	bne	dodlay			;yes: flindex ok as is
	lda	#13			;no: stay at last position in name
	sta	flindex			;
dodlay	jmp	rdlay

delete	lda	flindex			;at beginning?
	beq	dodlay			;yes: cannot backup
	dec	flindex			;backup and erase
	ldx	flindex			;
	lda	#' '			;
	sta	name,x			;
	jmp	rdlay			;
	
spac	lda	#' '			;space
	jmp	stash			;
vexit	jsr	TSKvblank		;turn off name out routine
	dw	0	
	rts

;---
; NMIbgcolor - reset background color
;---
NMIbgcolor
	lda	#>nipal+16		;set VRAM address to background color
	sta	nivramaddr		;
	lda	#<nipal+16			;
	sta	nivramaddr		;
	lda	pal1st			;
	sta	nivramdata
	rts

;---
; GEARTAB - gear table KEEP IN SYNC WITH TABLES FROM PB.ASM
;---

geartab
	dw unigear
	dw unigear
	dw unigear
	dw unigear

unigear		;universal gear
	db	3+4,3+4,3+4,3+4,3+4,3+4,3+4,3+4
	db	3+4,4+4,4+4,4+4,4+4,4+4,4+4,4+4
	db	4+4,4+4,5+4,5+4,5+4,5+4,5+4,5+4
	db	6+4,6+4,6+4,6+4,6+4,6+4,7+4,7+4
	db	7+4,7+4,7+4,8+4,8+4,8+4,8+4,9+4
	db	9+4,9+4,9+4,10+4,10+4,10+4,11+4,11+4
	db	11+4,12+4,12+4,12+4,13+4,13+4,15+4,14+4
	db	14+4,14+4,14+4,14+4,13+4,13+4,13+4,13+4
	db	12+4,12+4,12+4,12+4,12+4,12+4,11+4,11+4
	db	11+4,11+4,11+4,11+4,11+4,10+4,10+4,10+4
	db	10+4,10+4,10+4,10+4,10+4,9+4,9+4,9+4
	db	9+4,9+4,9+4,9+4,9+4,9+4,9+4,8+4
	db	8+4,8+4,8+4,8+4,8+4,8+4,8+4,8+4
	db	8+4,8+4,8+4,8+4,7+4,7+4,7+4,7+4
	db	7+4,7+4,7+4,7+4,7+4,7+4,7+4,7+4
	db	8,8,8,8,7,7,7,7
	db	7,7,7,7,7,7,7,7
	db	7,7,7,7,7,7,7,6
	db	6,6,6,6,6,6,6,6
	db	6,6,6,6,6,6,6,6
	db	6,6,6,6,6,6,6,6
	db	6,5,5,5,5,5,5,5
	db	5,5,5,5,5,5,5,5
	db	5,5,5,5,5,5,5,5
	db	5,5,-5,-5,-5,-5,-5,-5
	db	-5,-5,-5,-6,-6,-6,-6,-6
	db	-6,-6,-6,-6,-6,-6,-7,-7
	db	-7,-7,-7,-7,-7,-7,-7,-7
	db	-7,-8,-8,-8,-8,-8,-8,-8
	db	-8,-8,-8,-9,-9,-9,-9,-9
	db	-9,-9,-9,-9,-10,-10,-10,-10
	db	-10,-10,-10,-10,-11,-11

;---
; stripe initialization data
;---
STRxh		db	149,116,099,091,087,085,083,081
STRyh		db	103,087,079,075,073,072,071,070

;---
; strip character numbers based on y position
;---
ychar	db	0,0,0,0,0,0,0,0,0,0
	db	1,1,1,1,1,1,1,1,1,1
	db	2,2,2,2,2,3,3,3,3,3
	db	4,4,4,4,4,5,5,5,5,6
	db	6,6,7,7,7

;---
; y positions of the alphabet on the vanity screen
;---
yalpha	db	8*07,8*07,8*07,8*07,8*07,8*07,8*07
	db	8*09,8*09,8*09,8*09,8*09,8*09,8*09
	db	8*11,8*11,8*11,8*11,8*11,8*11,8*11
	db	8*13,8*13,8*13,8*13,8*13,8*13,8*13
	
;---
; x positions of the alphabet on the vanity screen
;---
xalpha	db	8*07,8*10,8*13,8*16,8*19,8*22,8*25
	db	8*07,8*10,8*13,8*16,8*19,8*22,8*25
	db	8*07,8*10,8*13,8*16,8*19,8*22,8*25
	db	8*07,8*10,8*13,8*16,8*19,8*22,8*25
	
;----
; data local and external
;---

;---
; local data
;---
	extern	frame		;ds 1			;current frame number
	extern	flindex		;ds 1			;frame list index
	extern	startdown

;---
; external data
;---
	extern	afartlow,afarthigh
	extern	bfartlow,bfarthigh
	extern	dashboard
	extern	debcnt
	extern	Lbuf			;used here for horizontal scroll
	extern	nicr0SH
	extern	niscrolll
	extern	niscrollm
	extern	PICvramflag
	extern	roadchrset
	extern	sv_niscrollh
	extern	sv_niscrollm
	extern	tsknums
	extern	VRAMbase

;---
; zero page data
;---
	extern PAGE0	frmptr		;ds 2	frame list pointer
	extern PAGE0	maptmp		;ds 2	screen 0 pointer
	extern PAGE0	maptmp2		;ds 2	screen 1 pointer
	extern PAGE0	tvtmp		;ds 2	for write_x_lines/palette

;---
; from PB.ASM - OBE's player/car control routines
;---
	extern	body
	extern	car
	extern	fline
	extern	laptimel
	extern	laptimeh
	extern	onebytexspeed
	extern	space
	extern	tires
	extern	TSKxspeedm
	extern	turn

	END
