
	include	nindef.asm
	include	ninref.asm

	LINKLIST

;---
; extern routines
;---
	extern	umul8x8			;in NINSYSC.ASM

	CODE
;---
; WRITE_X_LINES - write Xreg lines from address within tvtmp to screen
;---
write_x_lines:
	PUBLIC	write_x_lines
?10:	ldy	#0			;move a row to screen
?20:	lda	(tvtmp),y		;
	sta	nivramdata		;
	iny				;
	cpy	#32			;
	bne	?20			;
	lda	#32			;increment source pointer by 32
	clc				;
	adc	tvtmp			;
	sta	tvtmp			;
	bcc	?30			;
	inc	tvtmp+1			;
?30:	dex				;finished with all the rows?
	bne	?10			;no: go do another line
	rts

;---
; SETVRAMADDR - set PPU VRAM address to line y, column x off of VRAMbase
;---
setVRAMaddr:
	PUBLIC	setVRAMaddr
	sty	multiplier		;calculate offset to line start
	ldy	#32			;
	sty	multiplicand		;
	jsr	umul8x8			;

	txa				;add column offset to line offset
	clc				;
	adc	multiresult		;
	sta	multiresult		;
	lda	multiresult+1		;
	adc	#0			;
	sta	multiresult+1		;

	lda	multiresult		;add position offset to screen base
	clc				;
	adc	VRAMbase		;
	sta	multiresult		;
	lda	multiresult+1		;
	adc	VRAMbase+1		;
	sta	multiresult+1		;

	lda	multiresult+1		;set VRAM address (high then low)
	sta	nivramaddr		;
	lda	multiresult		;
	sta	nivramaddr		;

	rts
;---
; WAIT_FOR_START - wait for the start button to be pressed
;---
wait_for_start
	PUBLIC	wait_for_start
	lda	#20			;debounce delay
	sta	debcnt			;
?10:	ldy	#0
	jsr	nijoyget		;update nijoy with current stick 0
	lda	nijoy			;wait for start to be released
	and	#nistart		;
	bne	?10			;
	dec	debcnt			;debounce button
	bne	?10			;

?20:	ldy	#0
	jsr	nijoyget		;update nijoy with current stick 0
	lda	nijoy			;wait for start to be pressed
	and	#nistart		;
	beq	?20			;
	rts

;---
; HIDE_SPRITES - move all sprites to a Y position of 255 (off screen)
;---
hide_sprites
	PUBLIC	hide_sprites
	ldy	#256/niobjsz		;number of sprites in the sprite block
	lda	#248			;new y position
	ldx	#0			;our index for traversing sprite block
?10:	sta	sprbuf+niobjy,x		;move this sprite off screen
	sta	sprbuf+niobjx,x		;move this sprite off screen
	inx				;next sprite in block
	inx				;
	inx				;
	inx				;
	dey				;do all sprites
	bne	?10			;
	rts

;---
; DO_SPRITE_DMA - cause PPU to read the sprite buffer
;---
do_sprite_DMA
	PUBLIC	do_sprite_DMA
	lda	#>sprbuf		;page number of sprite buffer
	sta	niwrf0			;do obj(sprite) DMA from sprite buffer
	rts

;---
; SND_DISABLE - disable all sound channels
;---
snd_disable
	PUBLIC	snd_disable
	lda	niwrst			;get sound channels enable bits
	ora	#$0F			;Obe sez 'niwrst not readable'
	sta	sv_niwrst		;save 
	and	#%11100000		;turn off sound
	sta	niwrst			;
	rts

;---
; SND_ENABLE - enable all sound channels
;---
snd_enable
	PUBLIC	snd_enable
	lda	sv_niwrst		;channels that were on when disabled
	sta	niwrst			;enable (CH 0-3 MUST BE RETRIGGERED)
	rts

;---
; WAITVB - wait for vertical blank
;---
waitvb:
	PUBLIC	waitvb
	lda	nistatus		;wait for not vertical blank
	bmi	waitvb			;
?10	lda	nistatus		;wait for vertical blank
	bpl	?10			;
	rts
	
;---
; WAITXNMIS - wait xreg nmi routines
;---
waitxnmis:
	PUBLIC	waitxnmis
	jsr	waitnmi			;go wait for 1 vertical blank routine
	dex
	bne	waitxnmis
	rts

;---
; WAITNMI - wait for vertical blank routine to happen
;--- 
waitnmi:
	PUBLIC	waitnmi
	lda	intflag
?1	cmp	intflag
	beq	?1
	rts

;---
; WAITXLINES - wait xreg scan lines (approx 124 cycles per scan line)
;---
waitxlines:
	PUBLIC	waitxlines
	ldy	#23			;2 cycles	 2	  2
?1	dey				;2 cycles*23	46	 48
	bne	?1			;3 cycles*22+2	68	116
	dex				;2 cycles	 2	118
	nop				;2 cycles	 2	120
	bne	waitxlines		;3 cycles	 3	123
	rts				;6 for rts + 6 for jsr make this routine
					;too long for <18 lines otherwise too
					;short.
					
;---
; CKSTART - see if the start key is pressed
;---
ckstart:
	PUBLIC	ckstart
	lda	#1			;assume start is not pressed
	sta	startdown		;
	ldy	#0			;joystick 0
	jsr	nijoyget		;update nijoy with current stick 0
	lda	nijoy			;start button pressed?
	and	#nistart		;
	beq	csexit			;no: leave startdown with nonzero
	dec	startdown
csexit:	rts

;---
; ZSUPPRESS0 - suppress leading zeroes at screen0 position X,Y for length of A
;---
zsuppress0:
	PUBLIC	zsuppress0
	stx	xpos			;save column position
	sty	ypos			;save row position
	sta	debcnt			;save length of field to examine
	sta	frmptr			;save for return

	lda	#<niscreen0		;setup screen base address
	sta	VRAMbase		;
	lda	#>niscreen0		;
	sta	VRAMbase+1		;

zsup0:	jsr	setVRAMaddr		;calc screen address from x,y
	lda	nivramdata		;get a byte from the screen

	ldx	debcnt			;get length of field to suppress
	ldy	#0			;will be index for suppressing zeroes

?10	lda	nivramdata		;get a byte from the screen
	clc				;adjust displacement to 0 character
	adc	space			;
	cmp	#'0'			;a zero?
	bne	?20			;no: done
	iny				;yes: count leading zeroes
	dex				;all of the field examined?
	bne	?10			;no: loop

?20	cpy	#0			;any leading zeroes found?
	beq	zpexit			;no: leave this routine
	sty	debcnt			;yes: save the count

	ldx	xpos			;point hardware to start of field
	ldy	ypos			;
	jsr	setVRAMaddr		;

	ldx	debcnt			;suppress X zeroes
	lda	#' '			;
	sec				;
	sbc	space			;
?30	sta	nivramdata		;
	dex				;
	bne	?30			;

zpexit	ldx	xpos
	ldy	ypos
	lda	frmptr
	rts

;---
; ZSUPPRESS1 - suppress leading zeroes at screen1 position X,Y for length of A
;---
zsuppress1:
	PUBLIC	zsuppress1
	stx	xpos			;save column position
	sty	ypos			;save row position
	sta	debcnt			;save length of field to examine

	lda	#<niscreen1		;setup screen base address
	sta	VRAMbase		;
	lda	#>niscreen1		;
	sta	VRAMbase+1		;

	jmp	zsup0			;continue at common code

;---
; DECOMP - decompress from pointer MAPTMP to nivramdata port
;---
decomp:
	PUBLIC	decomp
	ldy	#0			;index into frame data
decomp_loop
	lda	(maptmp),y		;get next byte
	iny				;

	cmp	#$55			;compress count prefix?
	bne	?regchr			;no: regular char, go output

	lda	(maptmp),y		;get next byte
	iny				;

	cmp	#$00			;end of this map?
	beq	dcexit			;yes: leave
	tax				;no: save the count

	lda	(maptmp),y		;get next byte
	iny				;

?out	sta	nivramdata		;put to the screen
	dex				;count=count-1
	bne	?out			;do xreg of same characters
	beq	decomp_loop		;branch always

?regchr	sta	nivramdata		;output the single character
	jmp	decomp_loop

dcexit	rts

;---
; CHECKERBOARD - write a blank checkboard background on screen 0
;---
checkerboard:
	public	checkerboard
	lda	#<niscreen0		;position cursor to upper-left
	sta	VRAMbase		;
	lda	#>niscreen0		;
	sta	VRAMbase+1		;
	ldx	#0			;
	ldy	#0			;
	jsr	setVRAMaddr		;

	lda	#128			;set screen to '0101010101' background
	ldy	#30			;
?10	ldx	#32			;
?20	sta	nivramdata		;
	dex				;
	bne	?20			;
	dey				;
	bne	?10			;

	lda	#<checker_col		;move checker board color memory bytes
	sta	tvtmp			;
	lda	#>checker_col		;
	sta	tvtmp+1			;
	ldx	#2			;
	jsr	write_x_lines		;

	lda	#>nipal			;establish checkerboard palette
	sta	nivramaddr		;
	lda	#<nipal			;
	sta	nivramaddr		;
	lda	#<checker_pal		;
	sta	tvtmp			;
	lda	#>checker_pal		;
	sta	tvtmp+1			;
	ldx	#1			;
	jsr	write_x_lines		;

	rts

;---
; WRITE_GARAGE - write garage palette, map & color memory to screen 0
;---
write_garage:
	public	write_garage

	lda	#>nipal			;establish garage palette
	sta	nivramaddr		;
	lda	#<nipal			;
	sta	nivramaddr		;
	lda	#<garage_pal		;
	sta	tvtmp			;
	lda	#>garage_pal		;
	sta	tvtmp+1			;
	ldx	#1			;
	jsr	write_x_lines		;

	lda	#<niscreen0		;position cursor to upper-left
	sta	VRAMbase		;
	lda	#>niscreen0		;
	sta	VRAMbase+1		;
	ldx	#0			;
	ldy	#0			;
	jsr	setVRAMaddr		;

	lda	#<garage_map		;move garage to screen 0
	sta	tvtmp			;
	lda	#>garage_map		;
	sta	tvtmp+1			;
	ldx	#32			;
	jsr	write_x_lines		;

	lda	#nibgblk+niobjblk+niobjlblk+nibglblk	;left edge off
	sta	nicr1SH			;

	lda	#172			;break screen here
	sta	rasterspritey		;

	lda	#1			;allow split to happen
	sta	dashboard		;

	lda	#0			;switch to these character sets at split
	sta	splitbsprbnk		;
	lda	#1			;
	sta	splitbchrbnk		;

	lda	#1			;set picture character & sprite banks
	sta	nibnksprSH		;
	lda	#8			;
	sta	nibnkchrSH		;


	lda	#0			;horizontal scroll value at split
	sta	splitbh
	sta	splitbm			;msb of horiz. scroll value at split

	rts

;---
; WRITE_WINCRUZ - write win palette, map & color memory to screen 0
;---
write_wincruz:
	public	write_wincruz

	lda	#>nipal			;establish garage palette
	sta	nivramaddr		;
	lda	#<nipal			;
	sta	nivramaddr		;
	lda	#<wincruz_pal		;
	sta	tvtmp			;
	lda	#>wincruz_pal		;
	sta	tvtmp+1			;
	ldx	#1			;
	jsr	write_x_lines		;

	lda	#<niscreen0		;position cursor to upper-left
	sta	VRAMbase		;
	lda	#>niscreen0		;
	sta	VRAMbase+1		;
	ldx	#0			;
	ldy	#0			;
	jsr	setVRAMaddr		;

	lda	#<wincruz_map		;move win to screen 0
	sta	tvtmp			;
	lda	#>wincruz_map		;
	sta	tvtmp+1			;
	ldx	#32			;
	jsr	write_x_lines		;

	lda	#nibgblk+niobjblk+niobjlblk+nibglblk	;left edge off
	sta	nicr1SH			;

	lda	#$FE			;move sprite 0 off screen
	sta	rasterspritey

	lda	#0			;disallow split to happen
	sta	dashboard		;

	lda	#1			;set picture character & sprite banks
	sta	nibnksprSH		;
	lda	#9			;
	sta	nibnkchrSH		;

	rts

;---
; CHECKER_COL - checkerboard color memory bytes
;---
checker_col:
	db	$00,$55,$00,$55,$00,$55,$00,$55,$55,$00,$55,$00,$55,$00,$55,$00
	db	$00,$55,$00,$55,$00,$55,$00,$55,$55,$00,$55,$00,$55,$00,$55,$00
	db	$00,$55,$00,$55,$00,$55,$00,$55,$55,$00,$55,$00,$55,$00,$55,$00
	db	$00,$55,$00,$55,$00,$55,$00,$55,$05,$00,$05,$00,$05,$00,$05,$00

;---
; checkerboard palette data
;---
checker_pal:
	db	$0F,$01,$20,$0F		;black	dkblue	medwhit	black
	db	$0F,$11,$20,$0F		;black	medblue	medwhit	black
 	db	$0F,$06,$28,$30		;black	dkred	yellow	white
 	db	$0F,$02,$14,$0F		;black	medblue	magenta	black
; Sprites
	db	$0F,$02,$02,$0F		;black	dk blue	dk blue	black
	db	$0F,$1A,$28,$0F		;black	green	yellow	black
 	db	$0F,$06,$28,$30		;black	red	yellow	white
 	db	$0F,$02,$14,$0F		;black	medblue	magenta	black

;---
;	garage.map
;---
garage_map:
	db	$00,$00,$00,$01,$02,$03,$04,$05
	db	$00,$06,$07,$08,$09,$08,$08,$0A
	db	$0B,$0C,$0D,$0E,$0F,$10,$08,$00
	db	$00,$00,$11,$00,$00,$00,$00,$00
	db	$12,$13,$00,$14,$15,$16,$17,$18
	db	$00,$19,$1A,$1B,$1C,$1D,$08,$0A
	db	$1E,$1F,$0A,$20,$21,$22,$23,$24
	db	$25,$00,$26,$27,$28,$11,$00,$00
	db	$29,$2A,$2B,$2C,$2D,$2E,$2F,$30
	db	$31,$32,$33,$34,$35,$36,$37,$0A
	db	$38,$39,$0A,$0A,$3A,$0A,$3B,$3C
	db	$3D,$3E,$3F,$40,$08,$26,$27,$28
	db	$41,$42,$43,$44,$45,$46,$47,$48
	db	$49,$4A,$4B,$4C,$0A,$4D,$0A,$0A
	db	$0A,$0A,$0A,$0A,$3A,$0A,$1E,$1F
	db	$0A,$4E,$4F,$50,$51,$52,$53,$00
	db	$54,$55,$56,$57,$58,$59,$5A,$5B
	db	$5C,$5D,$0A,$0A,$0A,$0A,$0A,$0A
	db	$0A,$0A,$0A,$0A,$5E,$0A,$38,$39
	db	$0A,$0A,$3A,$0A,$5F,$60,$61,$62
	db	$63,$64,$65,$66,$67,$68,$69,$6A
	db	$0A,$0A,$6B,$6C,$6D,$0A,$0A,$0A
	db	$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	db	$0A,$0A,$3A,$0A,$1E,$1F,$0A,$6E
	db	$6F,$70,$71,$72,$73,$74,$0A,$0A
	db	$75,$76,$77,$78,$79,$7A,$0A,$0A
	db	$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	db	$0A,$0A,$5E,$0A,$38,$39,$0A,$0A
	db	$7B,$7C,$7D,$7E,$7F,$0A,$0A,$DA
	db	$81,$82,$83,$84,$85,$86,$0A,$0A
	db	$6B,$6C,$6D,$0A,$0A,$0A,$0A,$0A
	db	$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	db	$87,$88,$89,$0A,$0A,$0A,$8A,$8B
	db	$8C,$8D,$8E,$8F,$90,$91,$75,$76
	db	$77,$78,$79,$7A,$0A,$0A,$0A,$0A
	db	$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	db	$92,$93,$0A,$0A,$0A,$0A,$94,$95
	db	$96,$97,$98,$99,$9A,$9B,$81,$82
	db	$83,$84,$85,$86,$0A,$0A,$6B,$6C
	db	$6D,$0A,$0A,$0A,$0A,$0A,$0A,$9C
	db	$9D,$0A,$0A,$0A,$0A,$0A,$9E,$9F
	db	$A0,$A1,$A2,$A3,$A4,$8B,$8C,$8D
	db	$8E,$8F,$90,$91,$75,$76,$77,$78
	db	$79,$7A,$0A,$0A,$0A,$0A,$9C,$A5
	db	$0A,$0A,$0A,$0A,$0A,$0A,$A6,$A7
	db	$A8,$A9,$AA,$AB,$94,$95,$96,$97
	db	$98,$99,$9A,$9B,$81,$82,$83,$84
	db	$85,$86,$0A,$0A,$0A,$9C,$A5,$AC
	db	$AD,$AE,$0A,$0A,$0A,$0A,$AF,$B0
	db	$B1,$B2,$0A,$0A,$9E,$9F,$A0,$A1
	db	$A2,$A3,$A4,$8B,$8C,$8D,$8E,$8F
	db	$90,$91,$0A,$0A,$9C,$A5,$AC,$B3
	db	$B4,$B5,$B6,$AE,$0A,$0A,$0A,$0A
	db	$0A,$0A,$0A,$0A,$A6,$A7,$A8,$A9
	db	$AA,$AB,$94,$95,$96,$97,$98,$99
	db	$9A,$B7,$0A,$9C,$A5,$AC,$B8,$B9
	db	$BA,$BB,$BC,$BD,$AD,$AE,$0A,$0A
	db	$0A,$0A,$0A,$0A,$AF,$B0,$B1,$B2
	db	$0A,$0A,$9E,$9F,$A0,$A1,$A2,$A3
	db	$BE,$0A,$9C,$A5,$AC,$B8,$B9,$00
	db	$BF,$C0,$C1,$C2,$B4,$BD,$AD,$AE
	db	$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A
	db	$0A,$0A,$A6,$A7,$A8,$A9,$AA,$AB
	db	$0A,$9C,$A5,$AC,$C3,$B9,$00,$00
	db	$00,$00,$00,$C4,$0A,$0A,$BB,$C5
	db	$AD,$AE,$0A,$0A,$0A,$0A,$0A,$0A
	db	$0A,$0A,$AF,$B0,$B1,$B2,$0A,$0A
	db	$9C,$A5,$AC,$AC,$AC,$C6,$00,$00
	db	$00,$00,$C7,$C8,$0A,$0A,$BB,$C9
	db	$B4,$BD,$AD,$AE,$0A,$0A,$0A,$0A
	db	$0A,$0A,$0A,$0A,$0A,$0A,$0A,$9C
	db	$A5,$AC,$AC,$CA,$CB,$CC,$00,$00
	db	$00,$00,$CD,$CE,$CF,$D0,$BB,$C9
	db	$0A,$0A,$B4,$BD,$AD,$AE,$0A,$0A
	db	$0A,$0A,$0A,$0A,$0A,$0A,$9C,$A5
	db	$D1,$D2,$CA,$D3,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$BF,$D4,$C9
	db	$0A,$0A,$0A,$0A,$BB,$C5,$AD,$AE
	db	$0A,$0A,$0A,$0A,$0A,$9C,$A5,$D5
	db	$00,$D6,$D7,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$D8
	db	$0A,$0A,$0A,$0A,$BB,$C9,$B4,$BD
	db	$AD,$AE,$0A,$0A,$9C,$A5,$D5,$00
	db	$80,$80,$80,$80,$80,$80,$80,$80
	db	$80,$80,$80,$80,$80,$80,$80,$80
	db	$80,$80,$80,$80,$80,$80,$80,$80
	db	$80,$80,$80,$80,$80,$80,$80,$80
	db	$80,$80,$80,$80,$80,$80,$80,$80
;---
;	specs.map
;---
	db	080h,080h,0BBh,0BCh,0BCh,0BCh,0BCh,0BCh	;double line
	db	0BCh,0BCh,0BCh,0BCh,0BCh,0BCh,0BCh,0BCh
	db	0BCh,0BCh,0BCh,0BCh,0BCh,0BCh,0BCh,0BCh
	db	0BCh,0BCh,0BCh,0BCh,0BCh,0BDh,080h,080h

	db	080h,080h,0BEh,080h,080h,080h,080h,080h	;CAR # line
	db	080h,080h,080h,080h,080h,080h,0A3h,0A1h
	db	0B2h,080h,083h,080h,080h,080h,080h,080h
	db	080h,080h,080h,080h,080h,0BFh,080h,080h

	db	080h,080h,0BEh,0B2h,0A5h,0B0h,0A1h,0A9h	;REPAIRS  PER.... line
	db	0B2h,0B3h,080h,080h,0B0h,0A5h,0B2h,0A6h
	db	0AFh,0B2h,0ADh,0A1h,0AEh,0A3h,0A5h,080h
	db	0B3h,0B0h,0A5h,0A3h,0B3h,0BFh,080h,080h

	db	080h,080h,0BEh,080h,080h,080h,080h,080h	;$ for repair
	db	080h,080h,080h,080h,080h,0A5h,0AEh,0A7h
	db	0A9h,0AEh,0A5h,080h,0B3h,0A9h,0BAh,0A5h
	db	09Ah,080h,080h,080h,080h,0BFh,080h,080h

	db	080h,080h,0BEh,0ADh,0AFh,0AEh,0A5h,0B9h	;TOP GEAR
	db	080h,080h,080h,080h,080h,0B4h,0AFh,0B0h
	db	080h,0A7h,0A5h,0A1h,0B2h,09Ah,080h,080h
	db	080h,080h,080h,080h,080h,0BFh,080h,080h

	db	080h,080h,0BEh,080h,080h,080h,080h,080h	;$ & CHASSI
	db	080h,080h,080h,080h,080h,0A3h,0A8h,0A1h
	db	0B3h,0B3h,0A9h,0B3h,09Ah,080h,080h,080h
	db	080h,080h,080h,080h,080h,0BFh,080h,080h

	db	080h,080h,0C0h,0C1h,0C1h,0C1h,0C1h,0C1h
	db	0C1h,0C1h,0C1h,0C1h,0C1h,0C1h,0C1h,0C1h
	db	0C1h,0C1h,0C1h,0C1h,0C1h,0C1h,0C1h,0C1h
	db	0C1h,0C1h,0C1h,0C1h,0C1h,0C2h,080h,080h
	db	080h,080h,080h,080h,080h,080h,080h,080h
	db	080h,080h,080h,080h,080h,080h,080h,080h
	db	080h,080h,080h,080h,080h,080h,080h,080h
	db	080h,080h,080h,080h,080h,080h,080h,080h
;---
;	garage.col
;---
	db	$FC,$FC,$00,$00,$1F,$CF,$F3,$30
	db	$FF,$73,$54,$55,$55,$55,$40,$1F
	db	$33,$44,$55,$55,$55,$55,$55,$01
	db	$FF,$F4,$05,$55,$55,$55,$01,$00
	db	$CC,$FC,$CF,$F0,$04,$01,$00,$00
	db	$A0,$AC,$A0,$AF,$A3,$A0,$A0,$A0
	db	$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
	db	$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A

;---
; garage palette data
;---
garage_pal:
	db	$12,$02,$02,$0F		;blue	dk blue	dk blue	black
	db	$12,$1A,$28,$0F		;blue	green	yellow	black
 	db	$12,$03,$20,$03		;blue	dkblmag	medwhit	dkblmag
 	db	$12,$02,$14,$0F		;blue	medblue	magenta	black
; Sprites
	db	$12,$02,$02,$0F		;blue	dk blue	dk blue	black
	db	$12,$1A,$28,$0F		;blue	green	yellow	black
 	db	$12,$20,$28,$30		;blue	red	yellow	white
 	db	$12,$02,$14,$0F		;blue	medblue	magenta	black


;---
;	wincruz2.map
;---
wincruz_map:
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
	db	$00,$00,$00,$00,$00,$01,$02,$03
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$04,$05,$06,$07,$08
	db	$09,$0A,$01,$02,$03,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$01,$02,$09,$0B,$0C,$0D,$0E,$0F
	db	$07,$10,$11,$07,$08,$09,$0A,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$01,$02,$03,$00,$00,$04
	db	$07,$07,$07,$07,$12,$13,$14,$15
	db	$16,$07,$07,$07,$07,$07,$17,$00
	db	$00,$00,$00,$01,$02,$03,$00,$00
	db	$04,$05,$06,$07,$08,$09,$18,$19
	db	$1A,$1B,$1B,$1B,$1C,$1D,$1E,$1F
	db	$20,$21,$07,$07,$07,$07,$08,$22
	db	$0A,$04,$05,$06,$07,$08,$03,$00
	db	$0B,$07,$07,$07,$07,$07,$07,$23
	db	$24,$25,$26,$27,$28,$29,$2A,$2B
	db	$2C,$2D,$2E,$2F,$07,$07,$07,$07
	db	$10,$0B,$07,$07,$07,$07,$08,$09
	db	$07,$07,$07,$07,$07,$07,$07,$30
	db	$31,$32,$33,$34,$35,$FC,$36,$37
	db	$36,$38,$39,$3A,$07,$07,$07,$07
	db	$07,$07,$07,$07,$07,$07,$07,$07
	db	$07,$07,$07,$07,$07,$07,$3B,$3C
	db	$3D,$3E,$3F,$40,$41,$42,$36,$43
	db	$00,$36,$44,$45,$07,$07,$07,$46
	db	$47,$48,$49,$07,$07,$07,$07,$07
	db	$07,$07,$07,$07,$07,$07,$4A,$4B
	db	$4C,$4D,$4E,$4F,$50,$51,$42,$52
	db	$53,$54,$55,$56,$07,$07,$07,$57
	db	$58,$59,$5A,$07,$07,$07,$07,$07
	db	$07,$07,$07,$07,$07,$07,$5B,$5C
	db	$5D,$5E,$5F,$07,$07,$07,$60,$61
	db	$62,$63,$36,$64,$65,$07,$66,$67
	db	$68,$69,$07,$07,$07,$07,$07,$07
	db	$6A,$6B,$07,$6C,$6B,$07,$6D,$6E
	db	$6F,$70,$71,$72,$73,$07,$74,$75
	db	$36,$76,$77,$78,$79,$7A,$7B,$7C
	db	$7D,$7E,$7F,$07,$07,$6A,$6C,$6C
	db	$80,$81,$82,$83,$84,$85,$86,$87
	db	$88,$7B,$89,$07,$8A,$8B,$8B,$8B
	db	$8B,$8B,$8B,$8C,$8D,$8E,$8F,$90
	db	$91,$92,$93,$94,$95,$96,$83,$83
	db	$97,$97,$97,$97,$97,$98,$92,$99
	db	$9A,$9B,$9C,$73,$9D,$9E,$9F,$A0
	db	$A0,$A1,$A2,$A3,$A4,$FD,$A5,$9A
	db	$A6,$A7,$A8,$A9,$AA,$AB,$97,$97
	db	$AC,$AC,$AC,$AC,$AD,$AE,$AF,$61
	db	$B0,$B1,$B2,$B3,$B4,$B5,$B6,$07
	db	$07,$B7,$B8,$B9,$AC,$BA,$BB,$B0
	db	$BC,$BD,$BE,$BF,$C0,$AC,$AC,$AC
	db	$C1,$41,$C1,$41,$C2,$C3,$74,$75
	db	$C4,$C5,$C6,$FF,$B4,$B5,$B6,$07
	db	$07,$B7,$B8,$B9,$C7,$FE,$75,$C4
	db	$C9,$41,$CA,$CB,$CC,$41,$C1,$41
	db	$41,$C1,$8A,$8B,$8B,$8B,$8B,$8B
	db	$8B,$8B,$8C,$9D,$B4,$B5,$B6,$07
	db	$07,$B7,$B8,$B9,$A3,$8A,$8B,$8B
	db	$8B,$8B,$8B,$8B,$8B,$8C,$41,$C1
	db	$C1,$41,$9D,$9E,$9F,$A0,$A0,$A0
	db	$A1,$A2,$A3,$B4,$B4,$B5,$B6,$07
	db	$07,$B7,$B8,$B9,$B9,$9D,$9E,$9F
	db	$A0,$A0,$A0,$A1,$A2,$A3,$C1,$41
	db	$41,$C1,$B4,$B5,$B6,$07,$07,$07
	db	$B7,$B8,$B9,$B4,$B4,$B5,$B6,$07
	db	$07,$B7,$B8,$B9,$B9,$B4,$B5,$B6
	db	$07,$07,$07,$B7,$B8,$B9,$41,$C1
	db	$C1,$41,$B4,$B5,$B6,$07,$07,$07
	db	$B7,$B8,$B9,$B4,$B4,$B5,$B6,$07
	db	$07,$B7,$B8,$B9,$B9,$B4,$B5,$B6
	db	$07,$07,$07,$B7,$B8,$B9,$C1,$41
	db	$41,$C1,$B4,$B5,$B6,$07,$07,$07
	db	$B7,$B8,$CD,$CE,$CE,$CE,$CE,$CE
	db	$CE,$CE,$CE,$CE,$CE,$CF,$B5,$B6
	db	$07,$07,$07,$B7,$B8,$B9,$41,$C1
	db	$C1,$41,$B4,$B5,$B6,$07,$07,$07
	db	$B7,$B8,$D0,$41,$41,$41,$41,$41
	db	$41,$41,$41,$41,$41,$D1,$B5,$B6
	db	$07,$07,$07,$B7,$B8,$B9,$C1,$41
	db	$41,$C1,$B4,$B5,$B6,$07,$07,$07
	db	$B7,$D2,$D0,$41,$41,$41,$41,$41
	db	$41,$41,$41,$41,$41,$D1,$B5,$B6
	db	$07,$07,$07,$B7,$D2,$B9,$41,$C1
	db	$D3,$D4,$D5,$D6,$D7,$D8,$07,$46
	db	$DB,$47,$DD,$DE,$DE,$DE,$DE,$DE
	db	$D2,$DF,$DE,$DE,$DE,$E0,$B5,$B6
	db	$07,$E1,$E2,$E3,$DC,$E4,$C1,$41
	db	$E5,$E6,$E7,$58,$59,$EA,$65,$57
	db	$58,$59,$46,$0D,$0D,$F0,$F1,$F2
	db	$DC,$20,$F4,$D6,$D7,$F5,$F6,$F7
	db	$E2,$13,$14,$FA,$FB,$FB,$0D,$0F
	db	$D6,$D6,$D6,$68,$69,$3C,$BF,$67
	db	$68,$69,$57,$58,$59,$FB,$FB,$FB
	db	$C3,$C5,$57,$58,$59,$4A,$4B,$4C
	db	$4D,$1D,$1E,$5E,$EC,$4B,$4C,$47
	db	$D6,$D6,$D6,$7D,$7E,$EA,$EB,$7C
	db	$7D,$7E,$67,$68,$69,$FB,$FB,$FB
	db	$DC,$F3,$67,$68,$69,$5B,$5C,$5D
	db	$5E,$29,$2A,$2B,$67,$5C,$1E,$5E
	db	$41,$41,$41,$41,$41,$41,$41,$41
	db	$41,$41,$41,$41,$41,$41,$41,$41
	db	$41,$41,$41,$41,$41,$41,$41,$41
	db	$41,$41,$41,$41,$41,$41,$41,$41
;---
;	wincruz2.col
;---
	db	$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
	db	$AA,$AA,$FA,$BA,$AA,$AA,$AA,$AA
	db	$6A,$9A,$FF,$AB,$AA,$AA,$AA,$AA
	db	$55,$55,$55,$0A,$0A,$56,$59,$5A
	db	$15,$05,$05,$00,$00,$05,$05,$45
	db	$11,$00,$00,$00,$00,$00,$00,$44
	db	$01,$00,$00,$00,$00,$00,$00,$44
	db	$00,$00,$00,$00,$00,$00,$00,$04

;---
; win palette data
;---
wincruz_pal:
	db	$0F,$27,$16,$36		;black	brown	red	flesh
	db	$0F,$30,$16,$36		;black	white	red	flesh
 	db	$0F,$30,$12,$36		;black	white	blue	flesh
 	db	$0F,$30,$28,$36		;black	white	yellow	flesh
; Sprites
	db	$0F,$02,$2C,$30		;black	dk blue	lt cyan	bright white
	db	$0F,$1A,$28,$0F		;black	green	yellow	black
 	db	$0F,$20,$28,$30		;black	red	yellow	white
 	db	$0F,$02,$14,$0F		;black	medblue	magenta	black

;---
; test routines for scrolling
;---
mynmi
	inc	startdown
	lda	startdown
	and	#$0F
	bne	myexit

	lda	#<niscreen0		;position cursor to color byte area
	sta	VRAMbase		;
	lda	#>niscreen0		;
	sta	VRAMbase+1		;
	ldx	#0			;
	ldy	#30			;
	jsr	setVRAMaddr		;

	ldx	debcnt
	PUBLIC	mynmi
	inx
	cpx	#4
	bne	?10
	ldx	#0
?10	stx	debcnt
	lda	cbstlo,x		;next checkerboard color byte pattern
	sta	tvtmp			;
	lda	cbsthi,x		;
	sta	tvtmp+1			;
	ldx	#2			;
	jsr	write_x_lines		;
myexit	rts

;
;	cb2.col
;
cb2_col
	db	$44,$11,$44,$11,$44,$11,$44,$11
	db	$11,$44,$11,$44,$11,$44,$11,$44
	db	$44,$11,$44,$11,$44,$11,$44,$11
	db	$11,$44,$11,$44,$11,$44,$11,$44
	db	$44,$11,$44,$11,$44,$11,$44,$11
	db	$11,$44,$11,$44,$11,$44,$11,$44
	db	$44,$11,$44,$11,$44,$11,$44,$11
	db	$01,$04,$01,$04,$01,$04,$01,$04
;
;	cb3.col
;
cb3_col
	db	$55,$00,$55,$00,$55,$00,$55,$00
	db	$00,$55,$00,$55,$00,$55,$00,$55
	db	$55,$00,$55,$00,$55,$00,$55,$00
	db	$00,$55,$00,$55,$00,$55,$00,$55
	db	$55,$00,$55,$00,$55,$00,$55,$00
	db	$00,$55,$00,$55,$00,$55,$00,$55
	db	$55,$00,$55,$00,$55,$00,$55,$00
	db	$00,$05,$00,$05,$00,$05,$00,$05
;
;	cb4.col
;
cb4_col
	db	$11,$44,$11,$44,$11,$44,$11,$44
	db	$44,$11,$44,$11,$44,$11,$44,$11
	db	$11,$44,$11,$44,$11,$44,$11,$44
	db	$44,$11,$44,$11,$44,$11,$44,$11
	db	$11,$44,$11,$44,$11,$44,$11,$44
	db	$44,$11,$44,$11,$44,$11,$44,$11
	db	$11,$44,$11,$44,$11,$44,$11,$44
	db	$04,$01,$04,$01,$04,$01,$04,$01

cbstlo	db	<checker_col,<cb4_col,<cb3_col,<cb2_col
cbsthi	db	>checker_col,>cb4_col,>cb3_col,>cb2_col

;---
; external data
;---
	extern	dashboard		;ds 1	;want split screen
	extern	debcnt			;ds 1	;debounce counter
	extern	space
	extern	splitbchrbnk
	extern	splitbh
	extern	splitbm
	extern	splitbsprbnk
	extern	startdown		;ds 1	;0 if start button pressed
	extern	sv_niwrst		;ds 1	;sound channel enable bits
	extern	VRAMbase		;ds 2	;video screen base address
	extern	xpos			;ds 1	;screen x (column) position
	extern	ypos			;ds 1	;screen y (row) position

;---
; zeropage data
;---
	extern	PAGE0 frmptr		;2 byte pointer
	extern	PAGE0 maptmp		;2 byte pointer
	extern	PAGE0 tvtmp		;2 byte pointer
