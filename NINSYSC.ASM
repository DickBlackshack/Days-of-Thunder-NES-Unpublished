; NINSYS.ASM:  Nintendo system services

	LINKLIST

	include nindef.asm

	extern	START		;first task scheduled
	extern	show_topview	;topview of track/status/pause screen
	extern	map_hskp	;housekeeping routine for map routines
	extern	sv_niscrollh,sv_niscrollm
	extern	waitxnmis
	extern	pauseflag
	extern	endofraceflag

;===========================================================================
; CONSTANTS

; Select board type:
cnrom		equ	0		;256 Kbit switched ROM
emulator	equ	0		;Nick's stuff
mmc1		equ	1

;===========================================================================
	PAGE0
	public tmp
tmp	ds 4			;temps -- can be used by any routine

	public nicr1SH
	public nibnkchrSH
	public nibnksprSH
nicr1SH	ds 1			;control register shadow
nibnkchrSH ds 1			;character bank shadow
nibnksprSH ds 1			;sprite bank shadow

; Joystick shadow
	public nijoy
nijoy		ds 1		;composite value, debounced buttons

	public niscrollh, niscrollv
niscrollh	ds 1		;horizontal scroll
niscrollv	ds 2		;vertical scroll

	public joy0
joy0	ds 1			;actual value read on port 0
joy1	ds 1			;port 1
	public ninmi
ninmi	ds 1			;nmi enable = $FF

; Vram variables
	public vrambp
vrambp	ds 1			;vrambuf index

	public PICxlo, PICxhi, PICylo, PICyhi
PICxlo		ds TSKmax+1		;x position, low	lower left
PICxhi		ds TSKmax+1		;x position, high
PICylo		ds TSKmax+1		;y position, low
PICyhi		ds TSKmax+1		;y position, high
;PICz		ds TSKmax+1		;depth

	globals on
multiplier	ds 1
multiplicand	ds 1
multiresult	ds 2
	globals off


	public TSKcurrent
TSKcurrent	ds 1			;index of currently active task
	public intflag
intflag	ds 1			;tell background int has occured
	public oldintflag
oldintflag	ds 1



pich	ds 1

	public	pich	;obe

pici	ds 1				;current picture index
picn	ds 1				;# of active pictures - 1
picp	ds 2				;picture pointer
picw	ds 1
picx	ds 2
picy	ds 2
pspri	ds 1				;index of next sprite to be allocated
psprn	ds 1				;sprite buffer index

;===========================================================================
; WRAM LOCATIONS
	DATA
;	org $200

	public	sprbuf
sprbuf	ds	256			;shadow copy of sprite data

vrambufsize equ 256-48
	public	vrambuf
vrambuf	ds	vrambufsize		;VRAM write buffer

	public	PICvramflag,rasterspritey,dashy
PICvramflag	ds	1		;non-zero means okay to output buffer
rasterspritey	ds	1		;y pos of sprite0 used to detect raster
dashy		equ	152-8		;raster sprite y for dashboard

	public	splitbh,splitbm,splitpalflag,splitbchrbnk,splitbsprbnk
splitbh		ds	1	;split screen bottom horizontal position
splitbm		ds	1	;split screen bottom horizontal screen
splitpalflag	ds	1	;split screen bottom palette flag
splitbchrbnk	ds	1	;split screen bottom character bank
splitbsprbnk	ds	1	;split screen bottom sprite bank

;===========================================================================
; Interrupt vectors
ivec	section
;	org $FFFA
	dw nmi
	dw reset
	dw irq

;===========================================================================

; START OF CODE
	CODE			;end of pg. zero

;===========================================================================
; Interrupt handlers

nmi
	inc	ninmi
	bne	nmixit
	pha
	txa
	pha
	tya
	pha


	lda	nistatus		;synchronize the latch

	ldx	nibnksprSH
	lda	nibnkchrSH
	jsr	nibnkchr


	lda	rasterspritey
	sta	sprbuf+niobjy
	lda	rasterspritechr
	sta	sprbuf+niobjc
	lda	#0
	sta	sprbuf+niobja
	lda	#1
	sta	sprbuf+niobjx


	lda	#>sprbuf
	sta	niwrf0			;OBJ DMA from sprite buffer

	lda	TSKvblankAdr+1	;does vblank process exist?
	beq	nmino
	jsr	vblankj			;yes, call it
nmino	equ $

; Do vblank task cleanup
	lda	PICvramflag
	beq	?notnow

	jsr	PICvramOut		;output VRAM buffer
?notnow
; Update scrolling registers
	lda	sv_niscrollh		;horizontal 
	sta	niscroll

	lda	niscrollv		;vertical
	sta	niscroll

	lda	sv_niscrollm		;horizontal 
	ror	a

	lda	niscrollv+1		;get vscroll msb
	rol	a			;shift to position in register
	ora	#nibgseg+niinton	;set other control 0 bits
	sta	nicr0			;set control register

	lda	nicr1SH
	sta	nicr1			;copy video on shadow register

	inc	intflag

	pla
	tay
	pla
	tax
	pla
nmixit	dec	ninmi
	rti

vblankj	jmp	(TSKvblankAdr)

;===========================================================================

irq	rti

;===========================================================================

reset
	public	reset
	sei				;disable interrupts
	cld

; Wait 4 vertical blanks before starting
	ldx #4
sync	lda nistatus
	bpl sync
	dex
	bne sync

	lda #0
	sta nicr0			;disble nmi interrupt
	sta nicr1			;disable video
	sta ninmi

  if mmc1
; Initialize MMC1 control registers
	inc	mmc1r0
	inc	mmc1r1
	inc	mmc1r2
	inc	mmc1r3			;set the MMC1 to a known state

	lda	#mmc1chrbank4k+mmc1_4screens+mmc1pgmbank16k+4
;	lda	#mmc1chrbank4k+mmc1_4screens
	jsr	setr0			;set to MMC1 control register 0

	lda	#0
	sta	currentprgbank
	jsr	setr3			;set to MMC1 control register 3
  endif

	lda #0				;zero ALL ram
	sta tmp				;
	sta tmp+1			;
	ldy #2				;
	ldx #7				;
?zero1	sta (tmp),y			;
	iny				;
	bne ?zero1			;
	inc tmp+1			;
	dex				;
	bne ?zero1			;

	ldx #0
?znam	sta $700,x
	inx
	cpx #$60	;high score names start at $760
	bne ?znam

	ldx #$f1
?real	lda $700,x
	cmp #" "
	bcc ?spacename
	cmp #"Z"+1
	bcs ?spacename
	inx
	cpx #$ff
	bne ?real
	jmp ?dontzero

?spacename
	ldx #13
	lda #" "
?spn	sta name,x
	dex
	bpl ?spn
	lda #0
	sta name+14

;space high score names
	lda #" "
	ldx #0
?14lp
	sta $760,x		;address inced by 17 ($11)
	sta $771,x
	sta $782,x
	sta $793,x
	sta $7a4,x
	sta $7b5,x
	sta $7c6,x
	sta $7d7,x
	inx
	cpx #14
	bne ?14lp
;zero string terminator & high scores
	lda #0
?17lp	sta $760,x		;address inced by 17 ($11)
	sta $771,x
	sta $782,x
	sta $793,x
	sta $7a4,x
	sta $7b5,x
	sta $7c6,x
	sta $7d7,x
	inx
	cpx #17
	bne ?17lp

?dontzero

	ldx #$FF			;initialize stack
	txs

	lda #" "
	sta space
	lda #$fd
	sta rasterspritechr

	jsr niraninit			;initialize random #s

  if 0		; Temp random check
	ldy #0
rrcheck	lda #$80
	jsr niranrange
	sta sprbuf,y
	iny
	bne rrcheck
foo	jmp foo
  endif


	lda #0
	sta nicr0			;disable video (again)
	sta nicr1
	sta nicr1SH
	sta nioamaddr			;"maintain zero"

; Initialize other registers
;	lda #$1F		;enable sounds
	lda #$0F		;(but not digital sound)

	sta niwrst
	lda #$40
	sta niportb		;disable video irq interrupts

	lda #0
	sta niwre0		;disable sound irq interrupts

; Initialize variables

	lda #0
	sta PICvramflag
	sta vrambp		;vram buffer
	sta vrambuf


	dec ninmi		;enable nmi.
; Enable NMI interrupt
	lda #nibgseg+niinton	;bg seg = $1000
	sta nicr0		;set control register




	jsr palgame


	jsr PICstring
	db 1,8, "       MINDSCAPE PRESENTS",0
	jsr PICvramOut
	jsr PICstring
	db 1,11,"         DAYS OF THUNDER",0
	jsr PICvramOut
	jsr PICstring
	db 1,22,"    COPYRIGHT 1990 PARAMOUNT",0
	jsr PICvramOut
	jsr PICstring
	db 1,23,"      ALL RIGHTS RESERVED.",0
	jsr PICvramOut
	jsr PICstring
	db 1,25,"          LICENSED BY",0
	jsr PICvramOut
	jsr PICstring
	db 1,26,"    NINTENDO OF AMERICA INC.",0
	jsr PICvramOut

	jsr nividon
	ldx #150
	jsr waitxnmis

	jsr show_titlej
	jsr vanityj

	inc ninmi

;=============================================================================
; Initialize tasks
	jsr TSKinit

	jsr TSKschedule
	dw START

	jsr nividoff		;sets scroll variables to zero

	jsr map_hskp

	jsr TSKvblank
	dw 0			;there is no vblank task

; Enable NMI interrupt
;	lda #nibgseg+niinton	;bg seg = $1000
;	sta nicr0		;set control register

	jsr TSKhandler		;execute tasks to setup top of dashboard

;	dec ninmi		;enable nmi. NOW DONE IN START TASK,OBE


	lda	intflag
	sta	oldintflag
	jmp	wait_spcol2


backgroundloop

wait_spcol
	lda	nistatus
	and	#nistrike
	beq	wait_spcol	;wait for top of dashboard

;RESET PALETTE?

	lda	splitpalflag
	bne	?newpal
	jmp	?nonewpal
?newpal
	cmp	#1
	beq	?dashpal
	jmp	?pitpal
?dashpal
;	ldx	0		;this gives me one more cycle delay
	ldx	#$a		;each value of x is equal to 2 cycles
	jsr	xdelay

	lda #0
	sta nicr1			;BLANK IMMEDIATELY!
	lda	#>nipal+1
	sta	nivramaddr
	lda	#<nipal+1
	sta	nivramaddr

	ldx	#$10
	jsr	xdelay

	lda	#$00
	sta	nivramdata
	lda	#$10
	sta	nivramdata
	lda	#$16
	sta	nivramdata

	ldx	#$11
	jsr	xdelay

	lda	#$0f
	sta	nivramdata
	lda	#$00
	sta	nivramdata
	lda	#$2a
	sta	nivramdata

	ldx	#$10
	jsr	xdelay

	lda	#$16
	sta	nivramdata
	lda	#$0f
	sta	nivramdata
	lda	#$00
	sta	nivramdata

	ldx	#$11
	jsr	xdelay

	lda	#$28
	sta	nivramdata
	lda	#$16
	sta	nivramdata
	lda	#$0f
	sta	nivramdata

	ldx	#$11
	jsr	xdelay

	lda	#$00
	sta	nivramdata
	lda	#$2c
	sta	nivramdata
	lda	#$16
	sta	nivramdata

	ldx	#$e
	jsr	xdelay

	lda	#>niscreen0+32*20
	sta	nivramaddr
	lda	#<niscreen0+32*20
	sta	nivramaddr

	lda #nibgblk+niobjblk
	sta nicr1
	jmp	?nonewpal


?pitpal
	ldx	#$a
	jsr	xdelay

	lda #0
	sta nicr1			;BLANK IMMEDIATELY!
	lda	#>nipal+1
	sta	nivramaddr
	lda	#<nipal+1
	sta	nivramaddr

	ldx	#$10
	jsr	xdelay

	lda	#$00
	sta	nivramdata
	lda	#$1a
	sta	nivramdata
	lda	#$28
	sta	nivramdata

	ldx	#$11
	jsr	xdelay

	lda	#$0f
	sta	nivramdata
	lda	#$16
	sta	nivramdata
	lda	#$1a
	sta	nivramdata

	ldx	#$10
	jsr	xdelay

	lda	#$30
	sta	nivramdata
	lda	#$0f
	sta	nivramdata
	lda	#$00
	sta	nivramdata

	ldx	#$11
	jsr	xdelay

	lda	#$1a
	sta	nivramdata
	lda	#$2a
	sta	nivramdata
	lda	#$0f
	sta	nivramdata

	ldx	#$11
	jsr	xdelay

	lda	#$01
	sta	nivramdata
	lda	#$16
	sta	nivramdata
	lda	#$28
	sta	nivramdata

	ldx	#$e
	jsr	xdelay

	lda	#>niscreen0+32*15
	sta	nivramaddr
	lda	#<niscreen0+32*15
	sta	nivramaddr

	lda #nibgblk+niobjblk+niobjlblk+nibglblk	;turn off left column blanking
	sta nicr1


?nonewpal


	ldx	splitbh		;don't scroll dashboard
	stx	niscroll
	ldx	#0
	stx	niscroll

	lda	splitbm
	ora	#nibgseg+niinton	;set other control 0 bits
	sta	nicr0		;set control register

	ldx	#9		;delay for off screen bank switch
?1	dex
	bne	?1

	lda	splitbchrbnk	;dashboard character set
	ldx	splitbsprbnk	;dashboard character set
	jsr	nibnkchr

nodashboard
	lda	intflag
	sta	oldintflag

	ldy	#0
	jsr	nijoyget	;update nijoy with current stick0 (obe)

	jsr	buffer_slice	;buffer new slice & save CURRENT niscrollh/m

;DEBUG
;	lda	#niselect
;	bit	joy0
;	beq	?noslow
;	lda	#255-60
;	sta	intflag
;?slow	lda	intflag
;	bne	?slow
;?noslow
;DEBUG

	lda	nijoy		;if start pressed, pause/unpause game
	and	#nistart	;
	beq	?10		;
	lda	endofraceflag
	bne	?10		;pause only during race
	lda	niwrst
	and	#16
	bne	?10		;if digital sound is on start button errors
	lda	#$ff
	eor	pauseflag
	sta	pauseflag
?10:				;

	lda	pauseflag
	bne	?paused		;don't do tasks if paused
	jsr	TSKhandler	;execute tasks
?paused


;	lda	#niselect
;	bit	joy0
;	beq	?nodebug
;	lda	nicr1SH		;darken colors to see when tasks end
;	ora	#$e0
;	sta	nicr1
;?nodebug


wait_spcol2
	lda	intflag
	cmp	oldintflag
	beq	wait_spcol2	;wait for int

wait_spcol3
	lda	nistatus
	and	#nistrike
	bne	wait_spcol3	;wait for end of vblank

	lda	dashboard
	beq	nodashboard
	jmp	backgroundloop

xdelay
?xdel	dex
	bne	?xdel
	rts

;===========================================================================
; SYSTEM UTILITIES
;===========================================================================
; Bank in character set A
	public nibnkchr
nibnkchr	equ $
  if cnrom
	tay
	lda nibnkdat,y
	sta nibnkdat,y
	sta nibnkdat,y			;select hardware bank switching
	rts

nibnkdat	equ $
	db $30, $31, $32, $33
  endif


  if emulator				;EMULATOR ONLY
	pha
	lda #0
	sta nicr1			;BLANK IMMEDIATELY!
	pla
	jsr $4800			;call bank switch routine	
	rts				;in emulation ram
  endif

  if mmc1
	jsr	bank_chars
	txa
	jsr	bank_sprites
	rts
  endif
  

;===========================================================================
; Case statement
	public nicase
nicase	equ $
	sta tmp+2		;compare value
	pla			;pop return address
	sta tmp
	pla
	sta tmp+1
	ldy #1
caselp	lda (tmp),y		;high index
	beq casex

	cmp tmp+2
	beq casem

	iny
	iny
	iny
	bne caselp

; Not found, return
casex	tya			;simulate a JSR return address
	clc
	adc tmp
	tay
	lda tmp+1
	adc #0
	pha
	tya
	pha
	lda tmp+2
	rts

; Match found, jump to it
casem	iny
	lda (tmp),y
	pha
	iny 
	lda (tmp),y
	sta tmp+1
	pla
	sta tmp
	lda tmp+2
	jmp (tmp)


;the original code here compares against #$41 which expects D6 to be set to 1.
;while this is sometimes true on hardware, it isn't always true and was found during compatibility testing across multiple systems.
nijoygetfix equ 1
	
;===========================================================================
; JOYGET:  Read joystick port X and return in A
	public nijoyget
nijoyget	equ $
  if 0			;doesn't work
	lda niwrst
	and #16
	beq joyget1		;no digital sound in progress

; Digital sound is active -- return last direction
	lda joy0,y
	and #$0F		;clear buttons
	sta nijoy
	rts
  endif

joyget1	LDa #1
	STa niporta		;L4016
	lda #0
	STa niporta		;L4016

	txa
	pha

	LDx #7
L81CA	lda niporta,y

  if nijoygetfix
	;just shift the low bit (the one we care about for standard controller) into the carry flag, no need for any cmp/branch.
	lsr a
	;just to keep memory layout 1:1 with the original.
	nop
	nop
	nop
	nop
  else ;original code
	cmp #$41
	beq l81cab		;carry is set if =
	clc
  endif
l81cab	equ $
	ROL tmp		;$9C

	dex
	bpl L81CA

	pla
	tax			;restore x

; Debounce selected joystick into joy
	lda joy0,y		;previous value
	and #niselect+nistart	;the debounced switches
	and tmp			;now 1 bits are ones that were both set

	eor tmp			;clear 1s where both are set (debounce)
	sta nijoy

	lda tmp
	sta joy0,y		;undebounced	

;now don't allow diagonals (obe)
;	lda #niup
;	bit nijoy
;	beq ?other
;	lda nijoy
;	and #%11110000		;preserve buttons
;	ora #niup
;	sta nijoy
;	rts
?other
;	lda #nidown
;	bit nijoy
;	beq ?rts
;	lda nijoy
;	and #%11110000		;preserve buttons
;	ora #nidown
;	sta nijoy
?rts
	rts
	
;===========================================================================
; Put full screen picture addr A, Y to screen 0
;	public nipicput
;nipicput	equ $
;	sta nisource		;save source address for run length encode
;	sty nisource+1
;
;	lda #<nivramdata	;write directly to screen
;	sta nidest
;	lda #>nivramdata
;	sta nidest+1
;
;	lda #<$400		;length
;	sta nicount
;	lda #>$400
;	sta nicount+1
;
;	jsr nividoff		;video off
;
;	jsr nirunnew		;run length decode
;
;	ldx TSKcurrent
;	rts

;===========================================================================
; Generate a random # w/ 16 bit seed
	public nirandom
;ranbmax	equ 54
;
;	PAGE0
;ranj	ds 1
;rank	ds 1
;rantmp	ds 1
;
;	DATA
;ranbuf	ds ranbmax+1
;
	CODE

niraninit	equ $
	lda #"E"
	sta RND
	lda #"S"
	sta RND2
	lda #1
	sta CARRY
	rts

;	lda #23
;	sta ranj
;	lda #54
;	sta rank
;	ldx #ranbmax
;ranini1	adc #21
;	sta ranbuf,x
;	dex
;	bpl ranini1
;	rts
;

nirandom equ $

*---
* DORND - generate random numbers (RND = bits 8-1, RND2 = bits 16-9, C = 17)
*---
DORND	ROR CARRY	;get the current carry status
	ROL RND		;rotate the carry into the random number
	ROL RND2	;contine the rotate for another 8 bits
	ROR A		;move the...
	ROR A		;...carry bit...
	ROR A		;...to bit 14 position
	EOR RND2	;xor with bit 14 of our 16 bit shift register
	ASL A		;move the xor'ed bit...
	ASL A		;...back into...
	ASL A		;...the carry
	ROL CARRY	;and save it for next time

	lda RND

	RTS

	DATA

RND	ds	1
RND2	ds	1
CARRY	ds	1

	CODE

;	txa
;	pha
;	tya
;	pha
;
;	ldy ranj
;	dey
;	bpl niran0
;	ldy #ranbmax
;niran0	sty ranj
;
;	ldx rank
;	dex
;	bpl niran1
;	ldx #ranbmax
;niran1	stx rank
;
;	lda ranbuf,x
;	clc
;	adc ranbuf,y
;	sta ranbuf,x
;	sta rantmp
;
;	pla
;	tay
;	pla
;	tax
;	lda rantmp
;	rts
;
;===========================================================================
;NIRANRANGE:  Generate a random # between 0..A-1

	CODE
	public niranrange
niranrange	equ $

	sta multiplicand		;  A 0 / 0 ran

	jsr nirandom
	sta multiplier

	tya
	pha
	jsr umul8x8	
	pla
	tay

	lda multiresult+1		;take hi order; discard fraction
	rts

;******************************************************************
; UMUL8x8:  8 x 8 multiplier
	public umul8x8
umul8x8	equ $
	lda #0
	sta multiresult
	sta multiresult+1

	ldy #8			;bit count
umul1	asl multiresult
	rol multiresult+1

	asl multiplier
	bcc umul2

	lda multiplicand
	clc
	adc multiresult
	sta multiresult
	bcc umul2

	inc multiresult+1

umul2	dey
	bne umul1
	rts

;===========================================================================
; Zero screen
	public niscrclr,niscrclr_any
niscrclr:
	jsr nividoff		;turn off video, resets scroll and vram addr

niscrclr_any:
	lda #0			;clear the current screen
	ldx #4	
	ldy #256-$C0		;full screen size
floop	sta nivramdata
	iny
	bne floop
	dex
	bne floop

; Fill area color RAM
	ldx #64
;opt;	lda #0
	
coloop	sta nivramdata
	dex
	bne coloop
	ldx TSKcurrent
	rts

;===========================================================================
; Routine to set VRAM address to X & Y
	public nivaset
nivaset	equ $
;opt;	lda nistatus		;clear flip flop

	tya
	sta nivramaddr		;hi
	txa
	sta nivramaddr		;lo
	rts

;===========================================================================
; Video on/off
	public nividoff
nividoff	equ $
	lda #0
	sta nicr1SH
	sta nicr1			;BLANK IMMEDIATELY!

	sta niscrollh
	sta niscrollv
	sta niscrollv+1

	lda #>niscreen0			;reset VRAM address
	sta nivramaddr
	lda #<niscreen0
	sta nivramaddr

	lda #0
	sta niscroll
	sta niscroll

	rts

;===========================================================================
; Turn on video -- in shadow reg only
	public nividon
nividon	equ $
;obe	lda #nibglblk+niobjlblk+nibgblk+niobjblk
	lda #nibgblk+niobjblk
	sta nicr1SH
	rts

;===========================================================================
; Palette primitives
	public PALset			;set palette (takes effect next cycle)
;	db offset 0..1F, color, ..., color, $FF

; Picture primitives
	public PICcurSet		;set VRAM write cursor to A,Y
	public PICoverlap		;return Carry if picture X overlaps Y
	public PICpickScan		;scan underneath pick objects (VBLANK only)
	public PICpickSet		;set pick address
	public PICput			;associate picture address with a task
	public PICaput			;associate picture address with a task obe
	public PICput2			;picture address is in TMP
	public PICstring
	public PICstring2		;output string @ address A,Y
	public PICvramOut		;output VRAM buffer -- VBLANK only
	public PICvramPut		;put picture to VRAM buffer
	public PICvramPut2		;from tmp
	public PICxset			;set Xpos from A (low); hi = 0
	public PICxset2			;set Xpos from Y (low) & A (high)
	public PICxadd
	public PICxdec			;decrement Xpos
	public PICxflip			;set xflip attribute
	public PICxinc			;increment Xpos
	public PICxsub
	public PICxyset
	public PICyadd
	public PICyset			;set Ypos from A (low); hi = 0
	public PICyset2			;set Ypos from Y (low) & A (high)
	public PICydec			;decrement Ypos
	public PICyinc			;increment Ypos
	public PICysub
	public picset
	public PICanimlo
	public PICanimhi

; Tasking primitives
	public TSKcancel
	public TSKhandler
	public TSKinit
	public TSKschedule
	public TSKschedule2
	public TSKsuspend
	public TSKvblank		;install vblank task
	public TSKwait			;wait A ticks before resuming

	DATA

; PICture definitions that go along with task ids
	public PICadrLo,PICadrHi
PICadrLo	ds TSKmax+1		;picture address, 0 if none
PICadrHi	ds TSKmax+1
	public PICattr
PICattr		ds TSKmax+1		;picture attribute

	public PICpick, PICpickLo, PICpickHi
PICpick		ds TSKmax+1		;last character "underneath"
PICpickLo	ds TSKmax+1		;precomputed VRAM address for pick read
PICpickHi	ds TSKmax+1




;OBE
	globals on

	PAGE0

TSKxh		ds TSKmax+1
TSKxm		ds TSKmax+1
TSKyh		ds TSKmax+1
TSKlap		ds TSKmax+1
TSKxspeedl	ds TSKmax+1
TSKxspeedh	ds TSKmax+1

	DATA

;TSKcardir	ds TSKmax+1		;cars direction
;TSKhstreet	ds TSKmax+1		;bit to test for open street in band
TSKskidding	ds TSKmax+1		;cars skidding
TSKsecwait	ds TSKmax+1		;wait this many seconds

TSKyspeedl	ds TSKmax+1
TSKyspeedh	ds TSKmax+1
TSKytimer	ds TSKmax+1
TSKxtimer	ds TSKmax+1
TSKxl		ds TSKmax+1
TSKyl		ds TSKmax+1
TSKaccel	ds TSKmax+1
TSKcarnum	ds TSKmax+1

PICatime	ds TSKmax+1		;animation timer
PICanimlo	ds TSKmax+1		;animation table address lo
PICanimhi	ds TSKmax+1		;animation table address hi
taskclock	ds 1			;sixtyiths
taskclockhi	ds 1			;seconds
taskclockmo	ds 1			;minutes
racetimel	ds 1			;total racetime sixtys
racetimeh	ds 1			;total racetime seconds
racetimem	ds 1			;total racetime minutes
practice	ds 1			;practice flag
averagespeed	ds 1
dashboard	ds 1			;1=dashboard on (wait for raster)
space		ds 1
rasterspritechr ds 1			;character for raster sprite

;PICxloo		ds TSKmax+1		;x position old
;PICyloo		ds TSKmax+1		;x position old


TSKflags2	ds TSKmax+1		;obe's flags
;  flags2 definitons
;TSKcolide	equ $80			;set if task should be tested for
;					;collision and scrolled with background
;TSKbhit	equ $40			;set by bulit when hit

	globals off


; Internal tables
PICsort		ds TSKmax+1		;picture Y sort table
	public TSKadrLo, TSKadrHi
TSKadrLo	ds TSKmax+1		;resume point low
TSKadrHi	ds TSKmax+1		;resume point high
	public TSKflags
TSKflags	ds TSKmax+1		;flags
	public TSKwaitLo
TSKwaitLo	ds TSKmax+1		;wait low
TSKyreg		ds TSKmax+1		;preserves Yreg

; Status flag definitons
TSKactive	equ $80			;set if task is alive
TSKwaiting	equ $40

TSKvblankAdr	ds 2			;vblank task address

currentprgbank	ds 1
	CODE

;===========================================================================
; Palette primitives
;	jsr PALset			;set palette (takes effect next cycle)
;	db offset 0..1F, color, ..., color, $FF
PALset	equ $
	pla
	sta tmp+2
	pla
	sta tmp+3

	ldy #1				;starting palette offset
	lda (tmp+2),y
	clc
	adc #<nipal
	sta tmp
	lda #>nipal
	sta tmp+1
	jsr vrambufset			;add new address to vram buffer

	ldy #2
palset1	lda (tmp+2),y
	bmi palset2
	jsr chrput
	iny
	bne palset1			;always

palset2	tya				;return to caller 
	clc
	adc tmp+2
	tay
	lda tmp+3
	adc #0
	pha
	tya
	pha
	rts

;===========================================================================

palgame	equ $
	public	palgame
; Set game palette
	jsr niscrclr

	lda #0
	sta nibnksprSH		;bank in character set
	lda #1
	sta nibnkchrSH		;bank in character set

	jsr PALset
	db 0				;first palette location loaded


	db niblack,$26,$10,$30
	db niblack,$1C,$1A,$2C
 	db niblack,$1B,$1A,$2A
 	db niblack,$3D,$1A,$05

; Sprites
	db niblack,$00,$27,$27
	db niblack,$00,$1A,$28
	db niblack,$00,$22,$11
	db niblack,$00,$20,$15
	db $FF					;terminator
	rts

; Color definitions.  
; Odd colors are also valid, but do not know what color they are
; DO NOT USE  D, E, 1D, 1E, 1F, 2D, 2E, 2F

;niblack	equ $0F		;was 0

;nigreydk	equ 0		;was $10

;nigrey		equ $20		;is almost white
;nigrey		equ $3D
;niwhite	equ $30

;nibluedk	equ $10+2
;niblue		equ $20+2
;nibluelt	equ $30+2

;nimagenta	equ $20+4

;nireddk	equ $10+6
;nired		equ $20+6

;niorange	equ $30+6	;peach; skin color

;niyellow	equ $30+8

;nigreendk	equ $10+10
;nigreen	equ $20+10

;nicyan		equ $20+12	;highest colors


;===========================================================================

palgamem
	public	palgamem
; Set game palette for melo yellow car

	jsr niscrclr

	lda #0
	sta nibnksprSH		;bank in character set
	lda #1
	sta nibnkchrSH		;bank in character set

	jsr PALset
	db 0				;first palette location loaded


	db niblack,$26,$10,$30
	db niblack,$1C,$1A,$2C
 	db niblack,$1B,$1A,$2A
 	db niblack,$3D,$1A,$05

; Sprites
	db niblack,$00,$27,$27
	db niblack,$00,$1A,$28
	db niblack,$00,$22,$11
	db niblack,$00,$35,$15
	db $FF					;terminator
	rts


;===========================================================================
;===========================================================================
; PICCURSET:  Set VRAM buffer write cursor to A,Y  
; NOTE:  Y >= 30 means write 2nd screen. (if vscroll, 2nd screen = +64)

PICcurSet	equ $
	tax

	tya
;	cmp #30
;	bcc piccur2
;	clc
;	adc #32+2		;relocate to upper screen (offset 64)
;piccur1	equ $
;	cmp #64+30
;	bcc piccur2
;	sec
;	sbc #64+30		;wrap back
;piccur2	equ $
;	tay			;preserve changes

; Calculate screen offset tmp
	lsr a
	lsr a
	lsr a			;hi of Y * 32
	clc
	adc #>niscreen0		;add screen base
	sta tmp+1

	tya
	asl a
	asl a
	asl a
	asl a
	asl a			;lo of Y * 32
	sta tmp

	txa			;horizontal position
	and #%11111
	ora tmp
	sta tmp
	
; Internal entry point to add address tmp to vram buffer 
vrambufset	equ $


	ldx vrambp		;vram buffer pointer
	lda vrambuf,x		;zero count?
	beq curset2		;yes, ok to add here

	clc
	adc vrambp		;add count to buffer pointer
	adc #3			;plus space for count and address
	sta vrambp
	tax

curset2	lda tmp+1
	sta vrambuf+2,x		;set high
	lda tmp
	sta vrambuf+1,x		;low
	lda #0
	sta vrambuf,x		;zero count until something is added

	ldx TSKcurrent


	rts

;=============================================================================
PICoverlap	equ $		;return Carry if picture X overlaps Y

;obe to center collision area
;	stx tmp+2
;	sty tmp+3
;	lda #4
;	jsr PICxadd
;	lda #4
;	jsr PICysub
;	ldx tmp+3
;	lda #4
;	jsr PICxadd
;	lda #4
;	jsr PICysub
;	ldx tmp+2
;	ldy tmp+3
;obe

	lda PICxlo,x
	sec
	sbc PICxlo,y
	sta tmp
	lda PICxhi,x
	sbc PICxhi,y
	sta tmp+1
	bpl pico1		;positive
	jsr negtmp		;negate tmp

pico1	lda tmp+1
	bne picono		;distance > 256, no overlap
	lda tmp
	cmp #20			;was 8 obe
	bcs picono		;distance > 16, no overlap

	lda PICylo,x		;now do Y
	sec
	sbc PICylo,y
	sta tmp
	lda PICyhi,x
	sbc PICyhi,y
	sta tmp+1
	bpl pico2		;positive
	jsr negtmp		;negate tmp

pico2	lda tmp+1
	bne picono		;distance > 256, no overlap
	lda tmp
	cmp #8			;was 8 obe
	bcs picono		;distance > 16, no overlap

;obe to center collision area
;	stx tmp+2
;	sty tmp+3
;	lda #4
;	jsr PICxsub
;	lda #4
;	jsr PICyadd
;	ldx tmp+3
;	lda #4
;	jsr PICxsub
;	lda #4
;	jsr PICyadd
;	ldx tmp+2
;	ldy tmp+3
;obe
	sec			;they overlap
	rts

picono
;obe to center collision area
;	stx tmp+2
;	sty tmp+3
;	lda #4
;	jsr PICxsub
;	lda #4
;	jsr PICyadd
;	ldx tmp+3
;	lda #4
;	jsr PICxsub
;	lda #4
;	jsr PICyadd
;	ldx tmp+2
;	ldy tmp+3
;obe
	clc			;they do not overlap
	rts


negtmp	equ $			;negate tmp
	lda tmp
	eor #$FF
	clc
	adc #1
	sta tmp
	lda tmp+1
	eor #$FF
	adc #0
	sta tmp+1
	rts

;=============================================================================
; Scan underneath pickable objects
PICpickScan	equ $
;  Read vram under objects that request it
	ldx #TSKmax
vramrd	lda TSKflags,x
	bpl vramrd1
	lda PICpickHi,x
	beq vramrd1		;if 0, do not read
	sta nivramaddr
	lda PICpickLo,x
	sta nivramaddr

	lda nivramdata		;discard first read
	lda nivramdata
	sta PICpick,x

vramrd1	dex
	bpl vramrd
	rts

;=============================================================================
; Set pick vram address (and enable picking)
PICpickSet	equ $
	pha			;x offset
	sty tmp+3		;y offset

	lda niscrollv+1
	asl a			;$x000 or $x800
	ora #8			;(>niscreen0)/4
	sta tmp+1		;preshifted high address

	lda PICylo,x
	sec 
	sbc tmp+3		;y offset

  if 0
	lsr a
	lsr a
	lsr a			;div 8 = character boundary
	sta tmp
	lda niscrollv
	lsr a
	lsr a
	lsr a			;div 8 = character boundary
	clc
	adc tmp
  else
	clc
	adc niscrollv
	ror a			;get carry if addition overflowed
	lsr a
	lsr a
  endif
	sta tmp
	cmp #30
	bcc PICpick1

	sec
	sbc #30
	sta tmp

	lda #2
	eor tmp+1
	sta tmp+1		;invert high address (vertical wrap)

PICpick1	equ $
	lda tmp
	asl a
	asl a
	asl a			;*8

	asl a			;shift in high
	rol tmp+1
	asl a
	rol tmp+1		;row * 32
	sta tmp

; Now add horizontal offset
	lda niscrollh
	lsr a
	lsr a
	lsr a
	sta tmp+2

	pla			;x offset
	clc
	adc PICxlo,x

	lsr a
	lsr a
	lsr a

	clc
	adc tmp+2
	and #%11111
	ora tmp

	sta PICpickLo,x			;set pick address
	lda tmp+1
	sta PICpickHi,x	

	rts

;=============================================================================
; PICpost: Post all active pictures for next cycle
; Local storage -- THESE ARE ALL TEMPS, AND CAN BE OVERLAYED WITH A TEMP AREA

	CODE
PICpost	equ $
	public PICpost

; Sort all active pictures by ascending Y for correct priority positioning
; First collect active pictures
	lda #4		;obe to reserve sprite 0 for raster # detect change from 0 to 4
	sta psprn

	ldy #0				;# of active pictures - 1
	ldx #TSKmax
post1	lda TSKflags,x
	bpl post2			;not active
	lda PICadrLo,x
	ora PICadrHi,x
	beq post2			;not active
	txa
	sta PICsort,y
	iny
post2	dex
	bpl post1

	cpy #0
;;	beq pszero			;no pictures active, zero hi sprites
	bne post2a
	jmp pszero
post2a	equ $
	dey
	sty picn			;highest picture-1


; Sort all active pictures by ascending Y for correct priority positioning
;---
; Insertion sort
	ldx #0

sortS2	stx tmp			;j

	ldy PICsort+1,x
	sty tmp+1		;r
	lda PICylo,y		;was z obe
	sta tmp+2		;k
	
sortS3	lda PICsort,x
	tay
	lda PICylo,y		;was z obe
	cmp tmp+2		;k
	bcs sortS5		;was bcc obe

	tya
	sta PICsort+1,x		;r[i+1] := r [i]
	dex
	bpl sortS3

sortS5	lda tmp+1		;r
	inx
	sta PICsort,x

;loop
	ldx tmp			;j
	inx
	cpx picn
	bcc sortS2

;---


; Allocate visible picture parts to sprite buffer
	ldy #0
psput	equ $
	ldx PICsort,y
	tya
	pha				;preserve sort index

	stx pici			;picture index

	lda PICadrLo,x			;set picture address
	sta picp
	lda PICadrHi,x
	sta picp+1


	ldy #PICheight
	lda (picp),y			;height
	sta pich

	asl a				;* 8 = height in pixels
	asl a
	asl a
	sta tmp

	lda PICylo,x
	sec
	sbc tmp				;bump up, since coords are for bottom
	sta picy
	lda PICyhi,x
	sbc #0
	sta picy+1

	ldy #PICdata			;first data location
psputy	equ $				;y loop
	lda PICxlo,x			;reset x
	sta picx
	lda PICxhi,x
	sta picx+1

	tya
	pha
	ldy #PICwidth
	lda (picp),y			;reset width
	sta picw
	pla
	tay

; If xflip, start at right edge
	lda #niobjhflip
	and PICattr,x
	beq psputx			;not set

	lda picw			;add (width - 1) * 8
	sec
	sbc #1
	asl a
	asl a
	asl a
	clc
	adc picx
	sta picx
	lda picx+1
	adc #0
	sta picx+1

psputx	equ $				;x loop
	lda picx+1
	ora picy+1
	bne psputx1			;if any high bits set, then not vis

	lda PICattr,x			;get attribute

	ldx psprn
	sta sprbuf+niobja,x		;store it

	lda (picp),y

;obe	beq psputx0			;zero character, don't allocate it

	sta sprbuf+niobjc,x		;character #

	lda picx
	sta sprbuf+niobjx,x		;set Xpos
	lda picy
	sta sprbuf+niobjy,x		;set Ypos

	txa				;advance sprite index
	clc
	adc #4
	BCS psputx0		;SPRITE OVERFLOW -- DO NOT ADVANCE

	sta psprn

psputx0	ldx pici			;reload picture index

; Advance to next column
psputx1	iny				;bump the picture pointer

	lda #niobjhflip
	and PICattr,x
	beq psputx2			;not set

	lda picx			;sub 8
	sec
	sbc #8
	sta picx
	lda picx+1
	sbc #0
	sta picx+1
	jmp psputx3

psputx2	equ $
	lda picx			;advance Xpos
	clc
	lda picx
	adc #8
	sta picx
	lda picx+1
	adc #0
	sta picx+1

psputx3	equ $
	dec picw
	bne psputx			;loop while more columns

; Advance to next row
	clc
	lda picy
	adc #8	
	sta picy
	lda picy+1
	adc #0
	sta picy+1

	dec pich
;;	bne psputy
	beq psputyz
	jmp psputy
psputyz	equ $

;obe for animation
	ldx pici
	dec PICatime,x
	bne moreanim
	jsr PICachange
moreanim
;obe
	
	pla				;move on to next picture
	tay
	cpy picn
	beq psputz
	iny
	jmp psput
psputz	equ $
	
; Clear remaining sprite buffers
pszero	ldx psprn
	lda #$F0			;off screen Y location
pszloop	sta sprbuf+niobjy,x
	inx
	inx
	inx 
	inx
	bne pszloop

	rts

;=============================================================================
; Obe
; Associate a picture address table following call with current task; 0 = none

PICaput
	jsr getadr
	pla
nextanim
	sta PICanimlo,x
	sta tmp
	pla 
	sta PICanimhi,x
	sta tmp+1
	jmp picset

PICachange		;entry point when PICatime expires
	lda PICanimlo,x
	clc
	adc #3		;length of animation table entry i.e. atime,address
	sta PICanimlo,x
	sta tmp
	lda PICanimhi,x
	adc #0
	sta PICanimhi,x
	sta tmp+1
picset
	ldy #0
	lda (tmp),y
	bne ?notend
	iny		;end of animation table, get address to jump to
	iny
	lda (tmp),y
	pha
	dey
	lda (tmp),y
	jmp nextanim

?notend	sta PICatime,x	;# of frames this picture is to be displayed
	iny
	lda (tmp),y
	pha
	iny
	lda (tmp),y
	sta tmp+1
	pla
	sta tmp
	jmp PICput2

;=============================================================================
; Associate picture address following call with current task; 0 = none

PICput	equ $
	jsr getadr
	pla
	sta tmp
	pla 
	sta tmp+1

; Picture address is in tmp
PICput2	equ $
	lda tmp
	sta PICadrLo,x
	lda tmp+1
	sta PICadrHi,x

; Get the initial attribute from the picture definition
	ldy #PICcolor
	lda (tmp),y
	sta PICattr,x

	rts

;===========================================================================
; String output getting X,Y from xreg,yreg which are both preserved OBE
; Procedure call is followed by asciz string
PICstringXY	equ $
	public PICstringXY

	pla
	sta picp
	pla
	sta picp+1		;get return address

	tya
	pha
	txa
	pha

	jsr PICcurSet		;set the cursor, x in A y in Y

	ldy #1
	jsr pics2lp		;embedded code below

	pla
	tax
	pla
	sta tmp
picsxO
	tya			;set return address beyond end
	clc
	adc picp
	tay
	lda picp+1
	adc #0
	pha
	tya
	pha
	ldy tmp
	rts

;===========================================================================
; String output
; Procedure call is followed by X, Y, asciz string
PICstring	equ $
	pla
	sta picp
	pla
	sta picp+1		;get return address

	ldy #1
	lda (picp),y
	tax
	iny
	lda (picp),y
	tay
	txa
	jsr PICcurSet		;set the cursor

	ldy #3
	jsr pics2lp		;embedded code below

picsx	tya			;set return address beyond end
	clc
	adc picp
	tay
	lda picp+1
	adc #0
	pha
	tya
	pha
	rts

;===========================================================================
PICstring2	equ $		;output string from A,Y at current buffer loc
	sta picp
	sty picp+1
	
	ldy #0

; alt. entry pt.
pics2lp	lda (picp),y
	beq pics2x
	sec
	sbc space		;blank = 0
	jsr chrput
	iny
	bne pics2lp		;always

pics2x	rts

;===========================================================================
; Update VRAM write buffer -- VBLANK ONLY
PICvramOut	equ $
	ldx #0
vramwr	ldy vrambuf,x		;count
	beq vramwrx		;done when zero

	lda vrambuf+2,x		;hi
	sta nivramaddr
	lda vrambuf+1,x
	sta nivramaddr		;lo

	inx			;advance index to data
	inx
	inx
	
vramwr1	lda vrambuf,x		;data
	sta nivramdata
	inx
	dey
	bne vramwr1		;loop while data
	beq vramwr		;always

vramwrx	equ $
	lda #0
	sta vrambuf		;mark buffer as empty
	sta vrambp
	rts


;===========================================================================
PICvramPut2	equ $		;put task picture to VRAM buffer
	sta picx+1		;preserve in top
	sty picy

	lda tmp
	sta picp
	lda tmp+1
	sta picp+1
	jmp PICvramPut3

;===========================================================================
PICvramPut	equ $		;put task picture to VRAM buffer
	sta picx+1		;preserve in top
	sty picy

	jsr getadr		;get address under return address
	pla
	sta picp
	pla
	sta picp+1

PICvramPut3	equ $
	ldy #PICheight
	lda (picp),y			;height
	sta pich

	lda picy
	sec
	sbc pich			;bump up, since coords are for bottom
	bcs picvp4			;no underflow

	clc
	adc #60				;wrap to bottom of virt screen space
picvp4	sta picy
	inc picy			;height = 0 should not change y

; Y holds the picture index
	ldy #PICdata			;first data location
vpputy	equ $				;y loop
	lda picx+1			;initial value
	sta picx

	tya
	pha

; Set the cursor
	lda picx
	ldy picy
	jsr PICcurSet

	ldx TSKcurrent			;restore task index

; Reset the width
	ldy #PICwidth
	lda (picp),y			;reset width
	sta picw

	pla
	tay

vpputx	equ $				;x loop
	lda (picp),y
	jsr chrput			;put character to vram buffer

; Advance to next column
vpputx1	iny				;bump the picture pointer
	inc picx			;advance Xpos

vpputx3	equ $
	dec picw
	bne vpputx			;loop while more columns

; Advance to next row
	inc picy
	dec pich
	bne vpputy
	rts

;===========================================================================
; CHRPUT:  Add character A to VRAM write buffer at current cursor position
; Preserves ALL registers
chrput	equ $


	sta tmp
	txa
	pha
	tya
	pha

	ldx vrambp		;get buffer pointer
	txa
	clc
	adc vrambuf,x		;calculate current end of buffer
	adc #3
	tay			;Y = where to insert next char

;check for h-wrap around screen
	lda vrambuf+1,x		;low buffer address
	and #31
	clc
	adc vrambuf,x		;count
	cmp #32
	bcc chrput1		;no wrap

; Wrap to other side of current screen
	sty vrambp		;set new pointer
	lda #0
	sta vrambuf,y		;count

	lda vrambuf+1,x		;low
	and #%11100000
	sta vrambuf+1,y

	lda vrambuf+2,x		;high stays the same
	sta vrambuf+2,y

	tya
	tax
	iny
	iny
	iny	
chrput1	equ $
; end of h-wrap check

	lda tmp
	sta vrambuf,y

	lda #0
	sta vrambuf+1,y		;always end with a zero count

	inc vrambuf,x		;increment count

	pla			;restore registers & exit
	tay
	pla
	tax	
	lda tmp


	rts
	

;=============================================================================
PICxflip	equ $		;set x flip flag
	lda PICattr,x
	ora #niobjhflip
	sta PICattr,x
	rts

;=============================================================================
PICxdec	equ $			;decrement x
	lda #1

PICxsub	equ $			;subtract A from Xpos
	sta tmp
	lda PICxlo,x
	sec
	sbc tmp
	tay
	lda PICxhi,x
	sbc #0
	jmp PICxset2

;=============================================================================
PICxinc	equ $			;incrment x
	lda #1
PICxadd	equ $
	sta tmp
	lda PICxlo,x
	clc
	adc tmp
	tay
	lda PICxhi,x
	adc #0
	jmp PICxset2

;=============================================================================
PICxset	equ $			;set x from A (low)
	tay
	lda #0
PICxset2	equ $			;set x from Y (low) & A (hi)
	sta PICxhi,x
	tya
	sta PICxlo,x
	rts	

;=============================================================================
PICxyset	equ $		;set Xpos=A & Ypos=Y, hi = 0
	sty tmp
	jsr PICxset
	lda tmp
	jmp PICyset

;=============================================================================
PICydec	equ $			;decrement Ypos
	lda #1
PICysub	equ $
	sta tmp
	lda PICylo,x
	sec
	sbc tmp
	tay
	lda PICyhi,x
	sbc #0
	jmp PICyset2

;=============================================================================
PICyinc	equ $			;increment Ypos
	lda #1
PICyadd	equ $
	sta tmp
	lda PICylo,x
	clc
	adc tmp
	tay
	lda PICyhi,x
	adc #0
	jmp PICyset2
	
;=============================================================================
PICyset	equ $				;set Ypos from A (low)
	tay
	lda #0

PICyset2	equ $			;set Y from Y (low) and A (hi)
	sta PICyhi,x
	tya
	sta PICylo,x
	rts	

;=============================================================================
; T S K    Procedures
;=============================================================================
; Cancel task X
TSKcancel	equ $
	lda #0			;zero the flags
	sta TSKflags,x
	rts

;=============================================================================
; Periodic task handler

TSKhandler	equ $

; Activate each active task
	ldx #TSKmax
TSKhan1	lda TSKflags,x
	bpl TSKhan2			;inactive
	tay				;preserve flags

; Handle wait field
	lda TSKwaitLo,x
	beq TSKhanc			;nothing to do if zero
	sec
	sbc #1
	sta TSKwaitLo,x		
	beq TSKhannw			;1 -> 0; clear wait flag

; Wait is not zero.  See if task is waiting.
	tya
	and #TSKwaiting
	bne TSKhan2			;is waiting, don't call

TSKhannw	equ $
	lda #TSKactive			;clear all flags but active
	sta TSKflags,x

TSKhanc	equ $
	stx TSKcurrent			

	lda TSKadrLo,x
	sta tmp
	lda TSKadrHi,x
	sta tmp+1

	ldy TSKyreg,x		;restore Y reg
	jsr TSKcall		;call the task
	ldx TSKcurrent
	tya
	sta TSKyreg,x		;preserve Y reg

TSKhan2	equ $
	dex
	bpl TSKhan1		;loop while more tasks

; Now post all active pictures for next cycle
	jsr PICpost

	inc taskclock
	lda taskclock
	cmp #60
	bne ?nosecond
	lda #0
	sta taskclock
	inc taskclockhi
	lda taskclockhi
	cmp #60
	bne ?nominute
	lda #0
	sta taskclockhi
	inc taskclockmo
?nosecond
?nominute
	rts

TSKcall	jmp (tmp)			;call the task

;=============================================================================
; Cancels all tasks (required for once only intialization)
TSKinit	equ $
	ldx #TSKmax
	lda #0
	sta taskclock
	sta taskclockhi
TSKini1	sta TSKflags,x
	sta TSKflags2,x
	dex
	bpl TSKini1
	rts

;=============================================================================
; Schedule task whose address follows the call
; Returns X = -1 if failure, otherwise returns task id
TSKschedule	equ $
	jsr getadr		;get address under call onto stack
	pla
	sta tmp
	pla
	sta tmp+1

TSKschedule2	equ $

; Search for inactive task
	ldx #TSKmax
TSKsch1	lda TSKflags,x
	bpl TSKsch2			;inactive
	dex
	bpl TSKsch1

	txa
	rts				;failed

TSKsch2	lda #TSKactive			;activate
	sta TSKflags,x
	lda tmp
	sta TSKadrLo,x
	lda tmp+1
	sta TSKadrHi,x

	lda #0
	sta PICadrLo,x
	sta PICadrHi,x			;no picture (yet)
	sta PICpickHi,x			;no vram pick address
	sta PICpick,x			;or value

;	lda #128
;	sta PICz,x			;set medium Z value

	txa
	ldx TSKcurrent			;reload current task id
	rts				;success

;=============================================================================
; Suspend task at current position
; Stack holds call to Suspend, plus initial call to task
TSKsuspend	equ $
	ldx TSKcurrent
	pla
	clc
	adc #1			;correct screwy JSR address
	sta TSKadrLo,x
	pla
	adc #0
	sta TSKadrHi,x
	rts			;return to task handler

;=============================================================================
TSKvblank	equ $		;install vblank task
	jsr getadr
	pla
	sta TSKvblankAdr
	pla
	sta TSKvblankAdr+1
	rts

;=============================================================================
; Wait A ticks before resuming
TSKwait	equ $
	ldx TSKcurrent
	sta TSKwaitLo,x
	lda #TSKactive+TSKwaiting
	sta TSKflags,x
	jmp TSKsuspend	


;=============================================================================
; UTILITY ROUTINES

getadr	equ $			;get address off stack
	pla
	sta tmp
	pla
	sta tmp+1		;return address to caller

	pla			;points to address location - 1
	sta tmp+2
	clc
	adc #2
	tay
	pla
	sta tmp+3
	adc #0
	pha
	tya
	pha			;push back corrected return address

; Push address onto stack
	ldy #2
	lda (tmp+2),y		;hi
	pha
	dey
	lda (tmp+2),y		;lo
	pha

	lda tmp+1		;return to caller
	pha
	lda tmp
	pha
	rts

;=============================================================================

  if mmc1
;=============================================================================
; MMC1 utility routines
setr0	sta	mmc1r0		;D0 setting - this routine takes 40 cycles
	lsr	a
	sta	mmc1r0		;D1 setting
	lsr	a
	sta	mmc1r0		;D2 setting
	lsr	a
	sta	mmc1r0		;D3 setting
	lsr	a
	sta	mmc1r0		;D4 setting
	rts

;---
; banks character set from Areg (0-31) into low 4K area of the PPU/VRAM
;---
bank_sprites:
	and	#%00011111
setr1:
	sta	mmc1r1
	lsr	a
	sta	mmc1r1
	lsr	a
	sta	mmc1r1
	lsr	a
	sta	mmc1r1
	lsr	a
	sta	mmc1r1
	rts

;---
;banks character set from Areg (0-31) into high 4K area of the PPU/VRAM
;---
bank_chars:
	and	#%00011111
setr2:
	sta	mmc1r2	
	lsr	a
	sta	mmc1r2
	lsr	a
	sta	mmc1r2
	lsr	a
	sta	mmc1r2
	lsr	a
	sta	mmc1r2
	rts

setr3	sta	mmc1r3
	lsr	a
	sta	mmc1r3
	lsr	a
	sta	mmc1r3
	lsr	a
	sta	mmc1r3
	lsr	a
	sta	mmc1r3
	rts
  endif



	public	nextframej
	extern	nextframe
nextframej
	lda	#3
	jsr	setr3			;set to MMC1 control register 3
	jsr	nextframe
	lda	#2
	jmp	setr3			;set to MMC1 control register 3


	public	sndplayj
	extern	sndplay
sndplayj
	lda	#1
	jsr	setr3			;set to MMC1 control register 3
	jsr	sndplay
	jmp	restoreprgbank


	public	sndinitj
	extern	sndinit
sndinitj
	pha
	lda	#1
	jsr	setr3			;set to MMC1 control register 3
	pla
	jsr	sndinit
	jmp	restoreprgbank


	public	write_bigcarj
	extern	write_bigcar
write_bigcarj
	lda	#1
	jsr	setr3			;set to MMC1 control register 3
	jsr	write_bigcar
	jmp	restoreprgbank


	public	show_titlej
	extern	show_title
show_titlej
	lda	#1
	jsr	setr3			;set to MMC1 control register 3
	jsr	show_title
	jmp	restoreprgbank


	public	vanityj
	extern	vanity
vanityj
	lda	#2
	jsr	setr3			;set to MMC1 control register 3
	jsr	vanity
	jmp	restoreprgbank



	public	firstpersonj
	extern	firstperson
firstpersonj
	lda	#2
	jsr	setr3			;set to MMC1 control register 3
	jsr	firstperson
	jmp	restoreprgbank

	public	buffer_slice
	extern	track0
buffer_slice
	lda	#4
	jsr	setr3			;set to MMC1 control register 3
	jsr	track0
	jmp	restoreprgbank

restoreprgbank
	lda	currentprgbank
	jsr	setr3			;set to MMC1 control register 3
	rts

	end
