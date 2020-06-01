;---
; mapstuff.asm - map routines
;---

	LINKLIST

	include nindef.asm
	include ninref.asm

;---
; map equates
;---
sliceht	equ	18		;height of a map slice
cbytes	equ	5		;number of area color codes for the map slice

	CODE

;---
; map_hskp - perform housekeeping functions needed for the map routines
;---
map_hskp:
	public	map_hskp

	lda	#0
	sta	last_sh			;init last value of niscrollh
	sta	track			;

	lda	#nibgseg+niinton	;NMI on, objs @ $0, chrs @ $1000
	sta	nicr0SH		

	lda	#>niscreen1
	sta	nivramaddr
	lda	#<niscreen1
	sta	nivramaddr
	jsr	niscrclr_any		;clear screen 1 & area color code ram

	jsr	line1			;output a 'coincidence' line on screen 1

	rts

;---
; sliceout - write a buffered vertical strip to the PPU screen
;---
sliceout:
	public sliceout

	lda	nicr1SH			;screen off?
	beq	?1			;yes: do not set palette

	lda	#>nipal+1		;set palette address
	sta	nivramaddr		;
	lda	#<nipal+1		;
	sta	nivramaddr		;

	lda	#$2A			;change color set 0
	sta	nivramdata		;light green
	lda	#$1A
	sta	nivramdata		;green
	lda	#$20
	sta	nivramdata		;white

	lda	#$0f			;change color set 1
	sta	nivramdata
	lda	#$12
	sta	nivramdata		;dark blue
	lda	#$16
	sta	nivramdata		;red
	lda	#$20
	sta	nivramdata		;white

	lda	#$0f			;change color set 2
	sta	nivramdata
	lda	#$2C
	sta	nivramdata		;cyan
	lda	#$16
	sta	nivramdata		;red
	lda	#$24
	sta	nivramdata		;light magenta

	lda	#$0f			;change color set 3
	sta	nivramdata
	lda	#$2C
	sta	nivramdata		;cyan
	lda	#$18
	sta	nivramdata		;brown (with greenish tinge)
	lda	#$20
	sta	nivramdata		;white

?1	lda	nicr0SH			;set increment to 32
	ora	#niincm			;
	sta	nicr0			;
					;get address of char in blanked column
	lda	sv_niscrollm		;get most significant bit of x scroll
	and	#%00000001		;
	asl	a			;use it determine if scrn0 or scrn1 up
	asl	a			;
	ora	#>niscreen0	;+32	;1st char in the 2nd row from the top
	sta	nivramaddr
	lda	sv_niscrollh
;	clc			;use these 2 instructions if only 1 screen used
;	adc	#8		;for horizontal scroll left to right, blank left
	lsr	a
	lsr	a
	lsr	a
	clc
	adc	#<niscreen0	;+32
	sta	nivramaddr

	ldx	#0			;number of character in a vertical strip
?10:	lda	Lbuf,x			;get a piece of the buffered strip
	sta	nivramdata		;store in the PPU's screen
	inx
	cpx	#sliceht		;done?
	bne	?10			;no: continue loop

	ldy	#0			;extra amount for a line of color bytes
?20:	sty	maptmp			;index for line color byte line
	asl	maptmp			;each color byte line...
	asl	maptmp			;...is 8 bytes...
	asl	maptmp			;...long
	lda	color_niscrollm		;get most significant bit of x scroll
	and	#%00000001		;
	asl	a			;use it determine if scrn0 or scrn1 up
	asl	a			;
	ora	#>niscreen0+(30*32)	;start of color bytes
	sta	maptmp+1		;save high part: possible carry from low
	lda	color_niscrollh
	lsr	a			;discard pixel scroll amount
	lsr	a			;
	lsr	a			;
	lsr	a			;divide by 4 for 0 to 7
	lsr	a			;
	clc
	adc	#<niscreen0+(30*32)	;start of color bytes
	adc	maptmp			;index to correct row
	sta	maptmp			;save low part
	lda	maptmp+1		;get high part: add the carry from low
	adc	#0
	sta	nivramaddr		;high to hardware
	lda	maptmp
	sta	nivramaddr		;low to hardware
	lda	Lbuf,x			;get a piece of the buffered strip
	sta	nivramdata		;store in the PPU's screen
	inx
	iny
	cpx	#sliceht+cbytes		;done?
	bne	?20			;no: continue loop

	lda	nicr0SH			;reset PPU control reg 0
	sta	nicr0			;

	rts

;---
; LINE1 - put out a coincidence line on screen 1
;---
line1:
	public	line1
	lda	#>niscreen1+(19*32)
	sta	nivramaddr
	lda	#<niscreen1+(19*32)
	sta	nivramaddr
	ldx	#32			;output a 'coincidence' line on screen 1
	lda	#$FE			;
?1	sta	nivramdata		;
	dex				;
	bne	?1			;

	rts

;---
; LINE0 - put out a coincidence line on screen 0
;---
line0:
	public	line0
	lda	#>niscreen0+(19*32)
	sta	nivramaddr
	lda	#<niscreen0+(19*32)
	sta	nivramaddr
	ldx	#32			;output a 'coincidence' line on screen 1
	lda	#$FE			;
?1	sta	nivramdata		;
	dex				;
	bne	?1			;

	rts

;===========================================================================
;---
; external data
;---
	extern	Lbuf
	extern	niscrolll,niscrollm
	extern	track
	extern	track_jmp

;---
; module data for MAPSTUFF.ASM
;---
	extern	last_sh,lane1y,lane2y,lane3y,lane4y
	extern	sv_niscrollh,sv_niscrollm
	extern	color_niscrollm,color_niscrollh
	extern	nicr0SH

;---
; zero page data for MAPSTUFF.ASM
;---
	extern	PAGE0 maptmp		;2 byte pointer
	extern	PAGE0 maptmp2		;2 byte pointer

	END
